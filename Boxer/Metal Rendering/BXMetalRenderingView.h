//
//  BXMetalRenderingView.h
//  Boxer
//
//  Created by Stuart Carnie on 7/10/20.
//  
//

@import Foundation;

#import "BXFrameRenderingView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BXMetalRenderingView : NSView<BXFrameRenderingView>

@property (assign, nonatomic) BOOL managesViewport;
@property (assign, nonatomic) NSSize maxViewportSize;
@property (readonly, nonatomic) NSRect viewportRect;

@end

NS_ASSUME_NONNULL_END
