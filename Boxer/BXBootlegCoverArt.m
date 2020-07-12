/* 
 Copyright (c) 2013 Alun Bestor and contributors. All rights reserved.
 This source file is released under the GNU General Public License 2.0. A full copy of this license
 can be found in this XCode project at Resources/English.lproj/BoxerHelp/pages/legalese.html, or read
 online at [http://www.gnu.org/licenses/gpl-2.0.txt].
 */


#import "BXBootlegCoverArt.h"
#import "ADBAppKitVersionHelpers.h"

@implementation BXJewelCase

+ (NSString *) fontName	{ return @"Marker Felt Thin"; }

+ (NSColor *) textColor
{
	return [NSColor colorWithCalibratedRed: 0.0
									 green: 0.1
									  blue: 0.2
									 alpha: 0.9];
}

+ (NSImage *) baseLayerForSize:	(NSSize)size
{
	return [NSImage imageNamed: @"CDCase"];
}

+ (NSImage *) topLayerForSize:	(NSSize)size
{
	//At sizes below 128x128 we don't use the cover-glass image
	if (size.width >= 128)
		return [NSImage imageNamed: @"CDCover"];
	else
		return nil;
}

+ (CGFloat) lineHeightForSize:	(NSSize)size	{ return 20.0 * (size.width / 128.0); }
+ (CGFloat) fontSizeForSize:	(NSSize)size
{
	//Use smaller font at sizes > 128 so that we can fit more on the label
	CGFloat baseSize = (size.width > 128.0) ? 12.0 : 14.0;
	return baseSize * (size.width / 128.0);
}

+ (NSRect) textRegionForRect: (NSRect)frame
{	
	if (frame.size.width >= 128)
	{
		CGFloat scale = frame.size.width / 128.0;
		return NSMakeRect(22.0 * scale,
						  32.0 * scale,
						  92.0 * scale,
						  60.0 * scale);
	}
	//Do not show text on icon sizes below 128x128.
	else return NSZeroRect;
}

+ (NSDictionary *) textAttributesForSize: (NSSize)size
{
	CGFloat lineHeight	= [self lineHeightForSize: size];
	CGFloat fontSize	= [self fontSizeForSize: size];
	NSColor *color		= [self textColor];
	NSFont *font		= [NSFont fontWithName: [self fontName] size: fontSize];
	
	NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[style setAlignment: NSTextAlignmentCenter];
	[style setMaximumLineHeight: lineHeight];
	[style setMinimumLineHeight: lineHeight];
	
    return @{NSParagraphStyleAttributeName: style,
             NSFontAttributeName: font,
             NSForegroundColorAttributeName: color,
             NSLigatureAttributeName: @2 };
}


- (id) initWithTitle: (NSString *)coverTitle
{
	if ((self = [super init]))
	{
		[self setTitle: coverTitle];
	}
	return self;
}

- (void) drawInRect: (NSRect)frame
{
	NSSize iconSize		= frame.size;
	
	NSImage *baseLayer	= [[self class] baseLayerForSize: iconSize];
	NSImage *topLayer	= [[self class] topLayerForSize: iconSize];
	NSRect textRegion	= [[self class] textRegionForRect: frame];
	
	if (baseLayer)
	{
		[baseLayer drawInRect: frame
					 fromRect: NSZeroRect
					operation: NSCompositingOperationSourceOver
					 fraction: 1.0];
	}

	if (!NSEqualRects(textRegion, NSZeroRect))
	{
		NSDictionary *textAttributes = [[self class] textAttributesForSize: iconSize];
		[[self title] drawInRect: textRegion withAttributes: textAttributes];
	}

	if (topLayer)
	{
		[topLayer drawInRect: frame
					fromRect: NSZeroRect
				   operation: NSCompositingOperationSourceOver
					fraction: 1.0];
	}

}

- (NSImageRep *) representationForSize: (NSSize)iconSize
{
	return [self representationForSize: iconSize scale: 1];
}

- (NSImageRep *) representationForSize: (NSSize)iconSize scale: (CGFloat)scale
{
	NSRect frame = NSMakeRect(0.0, 0.0, iconSize.width, iconSize.height);
	
	//Create a new empty canvas to draw into
	NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:iconSize.width*scale pixelsHigh:iconSize.height*scale bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:32];
	rep.size = iconSize;
	
	[NSGraphicsContext saveGraphicsState];
	NSGraphicsContext.currentContext = [NSGraphicsContext graphicsContextWithBitmapImageRep:rep];
		[self drawInRect: frame];
	[NSGraphicsContext restoreGraphicsState];
	
	return rep;
}

- (NSImage *) coverArt
{
	NSImage *coverArt = [[NSImage alloc] init];
	[coverArt addRepresentation: [self representationForSize: NSMakeSize(512, 512) scale: 2]];
	[coverArt addRepresentation: [self representationForSize: NSMakeSize(512, 512)]];
	[coverArt addRepresentation: [self representationForSize: NSMakeSize(128, 128) scale: 2]];
	[coverArt addRepresentation: [self representationForSize: NSMakeSize(128, 128)]];
	[coverArt addRepresentation: [self representationForSize: NSMakeSize(32, 32) scale: 2]];
	[coverArt addRepresentation: [self representationForSize: NSMakeSize(32, 32)]];
	[coverArt addRepresentation: [self representationForSize: NSMakeSize(16, 16) scale: 2]];
	[coverArt addRepresentation: [self representationForSize: NSMakeSize(16, 16)]];
	return coverArt;
}

+ (NSImage *) coverArtWithTitle: (NSString *)coverTitle
{
	id generator = [[self alloc] initWithTitle: coverTitle];
	return [generator coverArt];
}

@end


@implementation BX35Diskette

+ (NSImage *) baseLayerForSize: (NSSize)size
{
	return [NSImage imageNamed: @"35Diskette"];
}

+ (NSImage *) topLayerForSize: (NSSize)size
{
	if (size.width >= 128)
		return [NSImage imageNamed: @"35DisketteShine"];
	else
		return nil;
}

+ (CGFloat) lineHeightForSize:	(NSSize)size
{
    return 18.0 * (size.width / 128.0);
}

+ (NSRect) textRegionForRect: (NSRect)frame
{
	if (frame.size.width >= 128)
	{
		CGFloat scale = frame.size.width / 128.0;
		return NSMakeRect(24.0 * scale,
						  56.0 * scale,
						  80.0 * scale,
						  56.0 * scale);
	}
	else return NSZeroRect;
}
@end

@implementation BX525Diskette

+ (NSImage *) baseLayerForSize:	(NSSize)size	{ return [NSImage imageNamed: @"525Diskette"]; }
+ (NSImage *) topLayerForSize:	(NSSize)size	{ return nil; }
+ (CGFloat) lineHeightForSize:	(NSSize)size	{ return 16.0 * (size.width / 128.0); }
+ (CGFloat) fontSizeForSize:	(NSSize)size	{ return 12.0 * (size.width / 128.0); }

+ (NSRect) textRegionForRect: (NSRect)frame
{
	if (frame.size.width >= 128)
	{
		CGFloat scale = frame.size.width / 128.0;
		return NSMakeRect(16.0 * scale,
						  90.0 * scale,
						  96.0 * scale,
						  32.0 * scale);
	}
	else return NSZeroRect;
}
@end
