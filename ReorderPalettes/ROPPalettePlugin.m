//
//  ROPPalettePlugin.m
//  ReorderPalettes
//
//  Created by Takaaki Fuji on 13/10/2021.
//  Copyright © 2021 Morisawa Inc. All rights reserved.
//

// Adapted for the Glyphs 4 sidebar.
// Modified for Glyphs 4 compatibility in 2026.
#import "ROPPalettePlugin.h"

NSString *const ROPOrderKey = @"jp.co.morisawa.ReorderPalettes";
static NSArray<ROPPalettePlugin *> *defaultPalettes;

@protocol ROPPaletteTitle <NSObject>
- (NSString *)title;
@end

@interface ROPPalettePlugin ()
- (instancetype)initWithPalette:(id<ROPPaletteTitle>)palette;
@end

static NSArray *SortedPalettes(NSArray *palettes, NSString *(^className)(id)) {
    NSDictionary *order = [[NSUserDefaults standardUserDefaults] dictionaryForKey:ROPOrderKey];
    if (!order.count) return palettes;

    return [palettes sortedArrayWithOptions:NSSortStable usingComparator:^NSComparisonResult(id left, id right) {
        NSNumber *leftRank = order[className(left)];
        NSNumber *rightRank = order[className(right)];
        if (![leftRank isKindOfClass:NSNumber.class]) leftRank = nil;
        if (![rightRank isKindOfClass:NSNumber.class]) rightRank = nil;
        if (leftRank && rightRank) return [leftRank compare:rightRank];
        if (leftRank) return NSOrderedAscending;
        if (rightRank) return NSOrderedDescending;
        return NSOrderedSame;
    }];
}

// Python-defined classes belong to the host executable at the Objective-C
// runtime level. Resolve their owning plug-in from its declared principal classes.
static NSString *BundleIdentifierForPalette(id palette) {
    Class paletteClass = [palette class];
    NSString *className = NSStringFromClass(paletteClass);
    for (NSBundle *bundle in NSBundle.allBundles) {
        NSString *principalClass = [bundle objectForInfoDictionaryKey:@"NSPrincipalClass"];
        id principalClasses = [bundle objectForInfoDictionaryKey:@"Principal Classes"];
        BOOL containsClass = [principalClasses isKindOfClass:NSArray.class] &&
                             [principalClasses containsObject:className];
        if ([principalClass isEqualToString:className] || containsClass) {
            if (bundle.bundleIdentifier.length) return bundle.bundleIdentifier;
        }
    }

    NSBundle *classBundle = [NSBundle bundleForClass:paletteClass];
    if (classBundle != NSBundle.mainBundle && classBundle.bundleIdentifier.length) {
        return classBundle.bundleIdentifier;
    }
    return @"—";
}

@implementation ROPPalettePlugin

+ (void)applySavedOrderToPaletteInstances:(NSMutableArray *)instances {
    NSMutableArray *entries = [NSMutableArray arrayWithCapacity:instances.count];
    NSMutableSet *classNames = [NSMutableSet setWithCapacity:instances.count];
    for (id palette in instances) {
        NSString *className = NSStringFromClass([palette class]);
        if ([classNames containsObject:className]) continue;
        [classNames addObject:className];
        [entries addObject:[[self alloc] initWithPalette:palette]];
    }
    if (entries.count) defaultPalettes = [entries copy];

    [instances setArray:[self paletteInstancesInSavedOrder:[instances copy]]];
}

+ (NSArray *)paletteInstancesInSavedOrder:(NSArray *)instances {
    return SortedPalettes(instances, ^NSString *(id palette) {
        return NSStringFromClass([palette class]);
    });
}

+ (NSArray<ROPPalettePlugin *> *)availablePalettePluginsWithOptions:(ROPPalettePluginEnumeratingOptions)options {
    NSArray *palettes = defaultPalettes ?: @[];
    if (options & ROPPalettePluginEnumeratingOptionsPreferOriginalSortID) return palettes;
    return SortedPalettes(palettes, ^NSString *(ROPPalettePlugin *palette) {
        return palette.className;
    });
}

+ (NSDictionary<NSString *, NSNumber *> *)dictionaryFromPalettePlugins:(NSArray<ROPPalettePlugin *> *)plugins {
    NSMutableDictionary *order = [NSMutableDictionary dictionaryWithCapacity:plugins.count];
    [plugins enumerateObjectsUsingBlock:^(ROPPalettePlugin *palette, NSUInteger index, BOOL *stop) {
        order[palette.className] = @(index * 10);
    }];
    return [order copy];
}

- (instancetype)initWithPalette:(id<ROPPaletteTitle>)palette {
    if ((self = [super init])) {
        _className = NSStringFromClass([palette class]);
        _identifier = BundleIdentifierForPalette(palette);
        @try {
            if ([palette respondsToSelector:@selector(title)]) _title = [[palette title] copy];
        } @catch (NSException *exception) {
            NSLog(@"Reorder Palettes: could not read the title of %@: %@", _className, exception);
        }
        if (!_title.length) _title = _className;
    }
    return self;
}

- (NSUInteger)hash {
    return self.className.hash;
}

- (BOOL)isEqual:(id)object {
    return object == self || ([object isKindOfClass:ROPPalettePlugin.class] &&
                              [self.className isEqualToString:[object className]]);
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

@end
