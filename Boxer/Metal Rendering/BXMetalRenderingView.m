//
//  BXMetalRenderingView.m
//  Boxer
//
//  Created by Stuart Carnie on 7/10/20.
//  
//

@import QuartzCore;
@import OpenEmuShaders;

#import "ADBGeometry.h"
#import "BXMetalRenderingView.h"
#import "BXVideoFrame.h"
#import "BXMetalLayer.h"

/// Only send 1 frame at once to the GPU.
/// Since we aren't synced to the display, even one more
/// is enough to block in nextDrawable for more than a frame
/// and cause audio skipping.
/// TODO(sgc): implement triple buffering
#define MAX_INFLIGHT 1


@implementation BXMetalRenderingView {
    BXMetalLayer  *_videoLayer;
    OEFilterChain *_filterChain;
    OEPixelBuffer *_buffer;
    
    dispatch_semaphore_t    _inflightSemaphore;
    NSInteger               _skippedFrames;
    id<MTLDevice>           _device;
    id<MTLCommandQueue>     _commandQueue;
    MTLClearColor           _clearColor;
    
    
    BOOL _inViewportAnimation;
    BOOL _managesViewport;
    NSSize _maxViewportSize;
    NSRect _viewportRect;
    NSRect _targetViewportRect;
}

@synthesize currentFrame=_currentFrame;
@synthesize maxFrameSize=_maxFrameSize;
@synthesize renderingStyle=_renderingStyle;

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder: coder]) {
        [self initDefaults];
    }
    return self;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame: frameRect]) {
        [self initDefaults];
    }
    return self;
}

- (CALayer *)makeBackingLayer {
    return _videoLayer;
}

- (OEFilterChain *)filterChain {
    return _filterChain;
}

- (void)initDefaults {
    _inflightSemaphore = dispatch_semaphore_create(MAX_INFLIGHT);
    _device = MTLCreateSystemDefaultDevice();
    _commandQueue      = [_device newCommandQueue];
    _clearColor        = MTLClearColorMake(0, 0, 0, 1);
    _filterChain = [[OEFilterChain alloc] initWithDevice:_device];
    [_filterChain setDefaultFilteringLinear:NO];
    _videoLayer = [[BXMetalLayer alloc] init];
    _videoLayer.device = _device;
    _videoLayer.opaque = YES;
    _videoLayer.framebufferOnly = YES;
    _videoLayer.displaySyncEnabled = YES;

    self.wantsLayer = YES;
    
    [self updateRenderState];

    _maxFrameSize = NSMakeSize(16384, 16384);
}

- (BOOL)supportsRenderingStyle:(BXRenderingStyle)style {
    return NO;
}

- (void)updateWithFrame:(BXVideoFrame *)frame {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    CGRect sourceRect = CGRectMake(0, 0, frame.size.width, frame.size.height);
    [_filterChain setSourceRect:sourceRect aspect:frame.scaledSize];

    if (frame != _currentFrame) {
        if (NSIsEmptyRect(self.viewportRect)) {
            NSRect viewportRect = [self viewportForFrame:frame];
            [self setViewportRect:viewportRect animated:NO];
        }
        
        // new buffer
        _currentFrame = frame;
        _buffer = [_filterChain newBufferWithFormat:OEMTLPixelFormatBGRA8Unorm
                                             height:frame.size.height
                                        bytesPerRow:frame.pitch
                                              bytes:frame.mutableBytes];
    }
    
    @autoreleasepool {
        if (dispatch_semaphore_wait(_inflightSemaphore, DISPATCH_TIME_NOW) != 0) {
            _skippedFrames++;
        } else {
            id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
            commandBuffer.label = @"offscreen";
            [commandBuffer enqueue];
            [_filterChain renderOffscreenPassesWithCommandBuffer:commandBuffer];
            [commandBuffer commit];
            
            id<CAMetalDrawable> drawable = _videoLayer.nextDrawable;
            if (drawable != nil) {
                MTLRenderPassDescriptor *rpd = [MTLRenderPassDescriptor new];
                rpd.colorAttachments[0].clearColor = _clearColor;
                // TODO: Investigate whether we can avoid the MTLLoadActionClear
                // Frame buffer should be overwritten completely by final pass.
                rpd.colorAttachments[0].loadAction = MTLLoadActionClear;
                rpd.colorAttachments[0].texture    = drawable.texture;
                commandBuffer = [_commandQueue commandBuffer];
                commandBuffer.label = @"final";
                id<MTLRenderCommandEncoder> rce = [commandBuffer renderCommandEncoderWithDescriptor:rpd];
                [_filterChain renderFinalPassWithCommandEncoder:rce];
                [rce endEncoding];

                __block dispatch_semaphore_t inflight = _inflightSemaphore;
                [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> _) {
                    dispatch_semaphore_signal(inflight);
                }];

                [commandBuffer presentDrawable:drawable];
                [commandBuffer commit];
            } else {
                dispatch_semaphore_signal(self->_inflightSemaphore);
            }
        }
    }
    
    [self.layer display];
    [CATransaction commit];
    
    // If the frame changes size or aspect ratio, and we're responsible for the viewport ourselves,
    // then smoothly animate the transition to the new size.
    if (self.managesViewport)
    {
        [self setViewportRect:[self viewportForFrame:frame] animated:YES];
    }
}

#pragma mark - Viewport / Bounds

- (void)updateRenderState {
    [_videoLayer setBounds:self.bounds];
    [_filterChain setDrawableSize:_videoLayer.drawableSize];
    if (self.currentFrame) {
        [self setViewportRect:[self viewportForFrame:self.currentFrame] animated:NO];
    }
}

- (void)setFrameSize:(NSSize)newSize {
    [super setFrameSize:newSize];
    if (!self.inLiveResize) {
        [self updateRenderState];
    }
}

- (void) viewDidEndLiveResize
{
    [self updateRenderState];
}

- (void) windowDidChangeBackingProperties: (NSNotification *)notification
{
    //[self _applyViewportToRenderer];
}

#pragma mark - Animation

+ (id) defaultAnimationForKey: (NSString *)key
{
    if ([key isEqualToString: @"viewportRect"])
    {
        CABasicAnimation *animation = [CABasicAnimation animation];
        animation.duration = 0.2;
        animation.timingFunction = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseIn];
        return animation;
    }
    else
    {
        return [super defaultAnimationForKey:key];
    }
}

- (void)animationDidStart:(CAAnimation *)anim
{
    _inViewportAnimation = YES;
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    _inViewportAnimation = NO;
    anim.delegate = nil;
}

//Returns the rectangular region of the view into which the specified frame should be drawn.
- (NSRect)viewportForFrame:(BXVideoFrame *)frame
{
    if (frame != nil && self.managesViewport)
    {
        NSSize frameSize = frame.scaledSize;
        NSRect frameRect = NSMakeRect(0.0f, 0.0f, frameSize.width, frameSize.height);
        
        NSRect canvasRect = self.bounds;
        NSRect maxViewportRect = canvasRect;
        
        //If we have a maximum viewport size, fit the frame within that; otherwise, just fill the canvas as best we can.
        if (!NSEqualSizes(self.maxViewportSize, NSZeroSize) && sizeFitsWithinSize(self.maxViewportSize, canvasRect.size))
        {
            maxViewportRect = resizeRectFromPoint(canvasRect, self.maxViewportSize, NSMakePoint(0.5f, 0.5f));
        }
        
        NSRect fittedViewportRect = fitInRect(frameRect, maxViewportRect, NSMakePoint(0.5f, 0.5f));
        
        return fittedViewportRect;
    }
    else
    {
        return self.bounds;
    }
}

- (void) setManagesViewport:(BOOL)enabled
{
    if (_managesViewport != enabled)
    {
        _managesViewport = enabled;
        
        // Update our viewport immediately to compensate for the change
        [self setViewportRect:[self viewportForFrame:self.currentFrame]
                     animated:NO];
    }
}

- (void)setViewportRect:(NSRect)newRect
{
    if (!NSEqualRects(newRect, _viewportRect))
    {
        _viewportRect = newRect;
        [self needsDisplay];
    }
}

- (void)setViewportRect:(NSRect)newRect animated:(BOOL)animated
{
    if (!NSEqualRects(_targetViewportRect, newRect))
    {
        //If our viewport is zero (i.e. we haven't received a frame until now)
        //then just replace the viewport with the new one instead of animating to it.
        if (!animated || NSIsEmptyRect(_viewportRect))
        {
            _targetViewportRect = newRect;
            self.viewportRect = newRect;
        }
        else
        {
            _targetViewportRect = newRect;
            
            [NSAnimationContext beginGrouping]; {
                NSAnimationContext.currentContext.duration = 0.2;
                [self.animator setViewportRect:_targetViewportRect];
                [NSAnimationContext endGrouping];
            }
        }
    }
}


@end
