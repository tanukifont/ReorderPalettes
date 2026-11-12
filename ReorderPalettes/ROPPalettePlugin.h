//
//  ROPPalettePlugin.h
//  ReorderPalettes
//
//  Created by Takaaki Fuji on 13/10/2021.
//  Copyright © 2021 Morisawa Inc. All rights reserved.
//

// Modified for Glyphs 4 compatibility in 2026.
#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>


FOUNDATION_EXPORT NSString *const ROPOrderKey;

typedef NS_ENUM(NSUInteger, ROPPalettePluginEnumeratingOptions) {
    ROPPalettePluginEnumeratingOptionsNone = 0,
    ROPPalettePluginEnumeratingOptionsPreferOriginalSortID = 1 << 0
};

@interface ROPPalettePlugin : NSObject <NSCopying>

@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSString *className;

// Called with the live palette instances after Glyphs sorts them.
+ (void)applySavedOrderToPaletteInstances:(NSMutableArray *)instances;
+ (NSArray *)paletteInstancesInSavedOrder:(NSArray *)instances;
+ (NSArray<ROPPalettePlugin *> *)availablePalettePluginsWithOptions:(ROPPalettePluginEnumeratingOptions)options;
+ (NSDictionary<NSString *, NSNumber *> *)dictionaryFromPalettePlugins:(NSArray<ROPPalettePlugin *> *)plugins;

@end
