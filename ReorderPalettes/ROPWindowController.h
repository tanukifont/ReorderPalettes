//
//  ROPWindowController.h
//  ReorderPalettes
//
//  Created by Takaaki Fuji on 13/10/2021.
//  Copyright © 2021 Morisawa Inc. All rights reserved.
//

// Modified for Glyphs 4 compatibility in 2026.
#import <Cocoa/Cocoa.h>

@protocol ROPWindowControllerDelegate;

@interface ROPWindowController : NSWindowController

@property (nonatomic, weak) id<ROPWindowControllerDelegate> delegate;

- (IBAction)handleClose:(id)sender;
- (IBAction)handleReset:(id)sender;

@end

@protocol ROPWindowControllerDelegate <NSObject>
@optional
- (void)windowController:(ROPWindowController *)windowController didReorderPalettePluginsWithDictionary:(NSDictionary<NSString *, NSNumber *> *)dictionary;
- (void)windowController:(ROPWindowController *)windowController willCloseWindow:(NSWindow *)window;
@end
