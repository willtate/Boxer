/* 
 Copyright (c) 2013 Alun Bestor and contributors. All rights reserved.
 This source file is released under the GNU General Public License 2.0. A full copy of this license
 can be found in this XCode project at Resources/English.lproj/BoxerHelp/pages/legalese.html, or read
 online at [http://www.gnu.org/licenses/gpl-2.0.txt].
 */


#import "BXThemes.h"
#import "NSShadow+ADBShadowExtensions.h"


#pragma mark - Control and cell extensions

@implementation NSObject (BXThemableExtensions)

+ (NSString *) defaultThemeKey
{
    return nil;
}

- (BGTheme *) themeForKey
{
    if ([self respondsToSelector: @selector(themeKey)])
        return [[BGThemeManager keyedManager] themeForKey: [(id)self themeKey]];
    else
        return nil;
}

@end

@implementation NSControl (BXThemedControls)

+ (NSString *) defaultThemeKey
{
    if ([[self cellClass] respondsToSelector: _cmd])
        return [[self cellClass] defaultThemeKey];
    else
        return nil;
}

- (void) setThemeKey: (NSString *)key
{
    if ([self.cell respondsToSelector: _cmd])
        [(id)self.cell setThemeKey: key];
}

- (NSString *) themeKey
{
    if ([self.cell respondsToSelector: _cmd])
        return [(id)self.cell themeKey];
    else
        return nil;
}
@end


#pragma mark - Theme extensions

@implementation BGTheme (BXThemeExtensions)

+ (void) registerWithName: (NSString *)name
{
    @autoreleasepool {
    if (!name) name = NSStringFromClass(self);
    BGTheme *theme = [[self alloc] init];
    [[BGThemeManager keyedManager] setTheme: theme
                                     forKey: name];
    }
}


- (NSGradient *) imageFill
{
    return [[NSGradient alloc] initWithStartingColor: self.textColor endingColor: self.textColor];
}
- (NSShadow *) imageDropShadow  { return self.dropShadow; }
- (NSShadow *) imageInnerShadow { return nil; }

- (NSGradient *) selectedImageFill      { return self.imageFill; }
- (NSShadow *) selectedImageDropShadow  { return self.imageDropShadow; }
- (NSShadow *) selectedImageInnerShadow { return self.imageInnerShadow; }

- (NSGradient *) highlightedImageFill      { return self.imageFill; }
- (NSShadow *) highlightedImageDropShadow  { return self.imageDropShadow; }
- (NSShadow *) highlightedImageInnerShadow { return self.imageInnerShadow; }

- (NSGradient *) pushedImageFill      { return self.highlightedImageFill; }
- (NSShadow *) pushedImageDropShadow  { return self.highlightedImageDropShadow; }
- (NSShadow *) pushedImageInnerShadow { return self.highlightedImageInnerShadow; }

- (NSGradient *) disabledImageFill
{
    return [[NSGradient alloc] initWithStartingColor: self.disabledTextColor endingColor: self.disabledTextColor];
}
- (NSShadow *) disabledImageDropShadow  { return self.imageDropShadow; }
- (NSShadow *) disabledImageInnerShadow { return self.imageInnerShadow; }

@end


#pragma mark - Concrete themes

@implementation BXBaseTheme
@end

@implementation BXBlueprintTheme

+ (void) load
{
    [self registerWithName: nil];
}

- (NSShadow *) textShadow
{
    return [NSShadow shadowWithBlurRadius: 3.0f
                                   offset: NSZeroSize
                                    color: [NSColor colorWithCalibratedWhite: 0 alpha: 0.75f]];
}

- (NSColor *) textColor
{
	return [NSColor whiteColor];
}

@end

@implementation BXBlueprintHelpTextTheme

+ (void) load
{
    [self registerWithName: nil];
}

- (NSColor *) textColor
{
	return [NSColor colorWithCalibratedRed: 0.67f green: 0.86f blue: 0.93f alpha: 1.0f];
}
@end



@implementation BXHUDTheme

+ (void) load
{
    [self registerWithName: nil];
}

- (NSShadow *) dropShadow
{
    return [NSShadow shadowWithBlurRadius: 2
                                   offset: NSMakeSize(0, -1)
                                    color: [NSColor colorWithCalibratedWhite: 0 alpha: 0.75f]];
}
- (NSShadow *) textShadow
{
    return [NSShadow shadowWithBlurRadius: 2
                                   offset: NSMakeSize(0, -1)
                                    color: [NSColor colorWithCalibratedWhite: 0 alpha: 0.66f]];
}

- (NSColor *) textColor
{
    return [NSColor whiteColor];
}

- (NSColor *) disabledTextColor
{
    return [NSColor colorWithCalibratedWhite: 1.0f alpha: 0.5f];
}

@end


@implementation BXIndentedTheme

+ (void) load
{
    [self registerWithName: nil];
}

- (NSShadow *) textShadow	{ return self.dropShadow; }

- (NSShadow *) dropShadow
{
    return [NSShadow shadowWithBlurRadius: 1.0f
                                   offset: NSMakeSize(0, -1.0f)
                                    color: [NSColor colorWithCalibratedWhite: 1 alpha: 1.0f]];
}

- (NSColor *) textColor
{
    return [NSColor colorWithCalibratedWhite: 0.25f alpha: 1];
}

- (NSColor *) disabledTextColor
{
    return [NSColor grayColor];
}





- (NSGradient *) imageFill
{
    return [[NSGradient alloc] initWithStartingColor: [NSColor colorWithCalibratedWhite: 0 alpha: 0.33]
                                          endingColor: [NSColor colorWithCalibratedWhite: 0 alpha: 0.10]];
}

- (NSShadow *) imageDropShadow
{
    return [NSShadow shadowWithBlurRadius: 1.0
                                   offset: NSMakeSize(0, -1)
                                    color: [NSColor colorWithCalibratedWhite: 1 alpha: 1]];
}
- (NSShadow *) imageInnerShadow
{
    return [NSShadow shadowWithBlurRadius: 1.25
                                   offset: NSMakeSize(0, -0.25)
                                    color: [NSColor colorWithCalibratedWhite: 0 alpha: 0.5]];
}

- (NSGradient *) disabledImageFill
{
    return [[NSGradient alloc] initWithStartingColor: [NSColor colorWithCalibratedWhite: 0 alpha: 0.10]
                                          endingColor: [NSColor colorWithCalibratedWhite: 0 alpha: 0.05]];
}
- (NSShadow *) disabledImageInnerShadow
{
    return [NSShadow shadowWithBlurRadius: 1.25
                                   offset: NSMakeSize(0, -0.25)
                                    color: [NSColor colorWithCalibratedWhite: 0 alpha: 0.25]];
}

- (NSGradient *) highlightedImageFill
{
    return [[NSGradient alloc] initWithStartingColor: [NSColor colorWithCalibratedWhite: 0 alpha: 0.5]
                                          endingColor: [NSColor colorWithCalibratedWhite: 0 alpha: 0.15]];
}
- (NSShadow *) highlightedImageInnerShadow
{
    return [NSShadow shadowWithBlurRadius: 1.25
                                   offset: NSMakeSize(0, -0.25)
                                    color: [NSColor colorWithCalibratedWhite: 0 alpha: 0.6]];
}

@end

@implementation BXIndentedHelpTextTheme

+ (void) load
{
    [self registerWithName: nil];
}

- (NSColor *) textColor
{
    return [NSColor darkGrayColor];
}

@end


@implementation BXInspectorListControlTheme

+ (void) load
{
    [self registerWithName: nil];
}

@end

@implementation BXInspectorListControlSelectionTheme

+ (void) load
{
    [self registerWithName: nil];
}

- (NSGradient *) imageFill
{
    return [[NSGradient alloc] initWithStartingColor: [NSColor colorWithCalibratedWhite: 1.0 alpha: 0.75]
                                          endingColor: [NSColor colorWithCalibratedWhite: 1.0 alpha: 0.50]];
}

- (NSShadow *) imageDropShadow
{
    return nil;
}

- (NSGradient *) highlightedImageFill
{
    return [[NSGradient alloc] initWithStartingColor: [NSColor colorWithCalibratedWhite: 1.0 alpha: 0.90]
                                          endingColor: [NSColor colorWithCalibratedWhite: 1.0 alpha: 0.80]];
}

- (NSShadow *) highlightedImageDropShadow
{
    return [NSShadow shadowWithBlurRadius: 1.0
                                   offset: NSMakeSize(0, -1)
                                    color: [NSColor colorWithCalibratedWhite: 0 alpha: 0.5]];
}

- (NSGradient *) pushedImageFill
{
    return [[NSGradient alloc] initWithStartingColor: [NSColor colorWithCalibratedWhite: 1.0 alpha: 1.00]
                                          endingColor: [NSColor colorWithCalibratedWhite: 1.0 alpha: 0.90]];
}

@end

@implementation BXInspectorListTheme

+ (void) load
{
    [self registerWithName: nil];
}

- (NSColor *) textColor
{
    return [NSColor labelColor];
}

- (NSShadow *) dropShadow
{
    return nil;
}

@end



@implementation BXInspectorListSelectionTheme

+ (void) load
{
    [self registerWithName: nil];
}

- (NSColor *) textColor
{
    return [NSColor whiteColor];
}

- (NSColor *) disabledTextColor
{
    return [NSColor colorWithCalibratedWhite: 1 alpha: 0.66];
}

- (NSShadow *) dropShadow
{
    return [NSShadow shadowWithBlurRadius: 2.0f
                                   offset: NSMakeSize(0, -1.0f)
                                    color: [NSColor colorWithCalibratedWhite: 0 alpha: 0.75f]];
}

- (NSShadow *) textShadow
{
    return [NSShadow shadowWithBlurRadius: 2.0f
                                   offset: NSMakeSize(0, -1.0f)
                                    color: [NSColor colorWithCalibratedWhite: 0 alpha: 0.5f]];
}

- (NSShadow *) disabledImageDropShadow
{
    return [NSShadow shadowWithBlurRadius: 2.0f
                                   offset: NSMakeSize(0, -1.0f)
                                    color: [NSColor colorWithCalibratedWhite: 0 alpha: 0.5f]];
}

@end


@implementation BXInspectorListHelpTextTheme

+ (void) load
{
    [self registerWithName: nil];
}

@end



@implementation BXLauncherTheme

+ (void) load
{
    [self registerWithName: nil];
}

- (NSColor *) textColor
{
    return [NSColor whiteColor];
}

- (NSShadow *) dropShadow
{
    return [NSShadow shadowWithBlurRadius: 2.0f
                                   offset: NSMakeSize(0, -1.0f)
                                    color: [NSColor colorWithCalibratedWhite: 0 alpha: 0.5f]];
}

- (NSShadow *) textShadow	{ return self.dropShadow; }

@end


@implementation BXLauncherHelpTextTheme

+ (void) load
{
    [self registerWithName: nil];
}

- (NSColor *) textColor
{
    return [NSColor colorWithCalibratedWhite: 1.0 alpha: 0.75];
}

@end

@implementation BXLauncherHeadingTheme

+ (void) load
{
    [self registerWithName: nil];
}

- (NSColor *) textColor
{
    return [NSColor colorWithCalibratedWhite: 0.0 alpha: 0.5];
}

- (NSShadow *) dropShadow
{
    return [NSShadow shadowWithBlurRadius: 1.0f
                                   offset: NSMakeSize(0, -1.0f)
                                    color: [NSColor colorWithCalibratedWhite: 1.0 alpha: 0.25f]];
}

- (NSGradient *) imageFill
{
    return [[NSGradient alloc] initWithStartingColor: [NSColor colorWithCalibratedWhite: 0.0 alpha: 0.25]
                                          endingColor: [NSColor colorWithCalibratedWhite: 0.0 alpha: 0.33]];
}

- (NSShadow *) imageDropShadow
{
    return self.dropShadow;
}

- (NSShadow *) imageInnerShadow
{
    return [NSShadow shadowWithBlurRadius: 1.0
                                   offset: NSMakeSize(0, -1)
                                    color: [NSColor colorWithCalibratedWhite: 0.0 alpha: 0.5]];
}

@end


@implementation BXAboutTheme

+ (void) load
{
    [self registerWithName: nil];
}

- (NSShadow *) textShadow	{ return self.dropShadow; }

- (NSShadow *) dropShadow
{
    return [NSShadow shadowWithBlurRadius: 1.0f
                                   offset: NSMakeSize(0, 1.0f)
                                    color: [NSColor colorWithCalibratedWhite: 0 alpha: 1.0f]];
}

- (NSColor *) textColor
{
    return [NSColor colorWithCalibratedWhite: 1 alpha: 0.66f];
}

@end


@implementation BXAboutDarkTheme

+ (void) load
{
    [self registerWithName: nil];
}

- (NSShadow *) dropShadow
{
    return [NSShadow shadowWithBlurRadius: 1.0f
                                   offset: NSMakeSize(0, -1.0f)
                                    color: [NSColor colorWithCalibratedWhite: 1 alpha: 0.4f]];
}

- (NSColor *) textColor
{
    return [NSColor colorWithCalibratedWhite: 0 alpha: 0.9f];
}

@end

@implementation BXAboutLightTheme

+ (void) load
{
    [self registerWithName: nil];
}

- (NSColor *) textColor
{
    return [NSColor colorWithCalibratedWhite: 1 alpha: 0.8f];
}

@end
