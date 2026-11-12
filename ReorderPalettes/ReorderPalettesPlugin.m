//
//  ReorderPalettesPlugin.m
//  ReorderPalettes
//
//  Created by tfuji on 13/10/2021.
//  Copyright © 2021 Morisawa Inc. All rights reserved.
//

// Modified for Glyphs 4 compatibility in 2026.
#import "ReorderPalettesPlugin.h"
#import "ROPWindowController.h"
#import "ROPPalettePlugin.h"
#import <objc/runtime.h>

// Glyphs 4 sorts the mutable palette array before laying out its sidebar.
typedef void (*SortPaletteInstances)(id, SEL, NSMutableArray *);
static SortPaletteInstances originalSort;
static NSHashTable *loadedSidebars;

@protocol ROPSidebar <NSObject>
- (NSScrollView *)panelScrollView;
@end

@protocol ROPPaletteContent <NSObject>
- (NSView *)theView;
@end

@protocol ROPDisclosureContent <NSObject>
- (NSView *)disclosedView;
@end

static NSArray *ReadArrayIvar(id object, const char *name) {
    Ivar ivar = class_getInstanceVariable([object class], name);
    if (!ivar || ivar_getTypeEncoding(ivar)[0] != '@') return nil;
    id value = object_getIvar(object, ivar);
    return [value isKindOfClass:NSArray.class] ? value : nil;
}

static void RefreshSidebar(id<ROPSidebar> sidebar) {
    if (![sidebar respondsToSelector:@selector(panelScrollView)]) return;
    NSStackView *stack = (NSStackView *)sidebar.panelScrollView.documentView;
    if (![stack isKindOfClass:NSStackView.class]) return;

    NSArray *controllers = ReadArrayIvar(stack, "_viewControllers");
    NSMutableArray *palettes = [ReadArrayIvar(sidebar, "_paletteInstances") mutableCopy];
    if (!controllers.count || !palettes.count) return;

    // Reuse the existing disclosure views, including their expansion state.
    NSStackViewGravity gravity = NSStackViewGravityTop;
    NSArray<NSView *> *currentViews = [stack viewsInGravity:gravity];
    NSMapTable *paneForContent = [NSMapTable strongToStrongObjectsMapTable];
    for (NSViewController<ROPDisclosureContent> *controller in controllers) {
        if (![controller respondsToSelector:@selector(disclosedView)] || !controller.isViewLoaded) continue;
        NSView *content = controller.disclosedView;
        if (content && [currentViews containsObject:controller.view]) {
            [paneForContent setObject:controller.view forKey:content];
        }
    }

    originalSort(sidebar, NSSelectorFromString(@"sortPaletteInstance:"), palettes);
    NSMutableArray<NSView *> *orderedPanes = [NSMutableArray array];
    NSMutableSet<NSView *> *matchedPanes = [NSMutableSet set];
    for (id<ROPPaletteContent> palette in [ROPPalettePlugin paletteInstancesInSavedOrder:palettes]) {
        if (![palette respondsToSelector:@selector(theView)]) continue;
        NSView *content = palette.theView;
        NSView *pane = content ? [paneForContent objectForKey:content] : nil;
        if (pane && ![matchedPanes containsObject:pane]) {
            [orderedPanes addObject:pane];
            [matchedPanes addObject:pane];
        }
    }

    // Keep spacers and any views Glyphs added outside the palette list in place.
    NSMutableArray<NSView *> *updatedViews = [currentViews mutableCopy];
    NSUInteger nextPane = 0;
    for (NSUInteger index = 0; index < currentViews.count; index++) {
        if ([matchedPanes containsObject:currentViews[index]]) {
            updatedViews[index] = orderedPanes[nextPane++];
        }
    }
    if (![currentViews isEqualToArray:updatedViews]) [stack setViews:updatedViews inGravity:gravity];
}

static void SortWithSavedOrder(id sidebar, SEL selector, NSMutableArray *instances) {
    originalSort(sidebar, selector, instances);
    if ([instances isKindOfClass:NSMutableArray.class]) {
        [loadedSidebars addObject:sidebar];
        [ROPPalettePlugin applySavedOrderToPaletteInstances:instances];
    }
}

static BOOL InstallSidebarHook(void) {
    if (originalSort) return YES;
    Class sidebar = NSClassFromString(@"GSPanelSidebarViewController");
    SEL selector = NSSelectorFromString(@"sortPaletteInstance:");
    Method method = class_getInstanceMethod(sidebar, selector);
    if (!method || strcmp(method_getTypeEncoding(method), "v24@0:8@16") != 0) return NO;

    loadedSidebars = [NSHashTable weakObjectsHashTable];
    originalSort = (SortPaletteInstances)method_getImplementation(method);
    class_replaceMethod(sidebar, selector, (IMP)SortWithSavedOrder, method_getTypeEncoding(method));
    return YES;
}

@interface ReorderPalettesPlugin () <ROPWindowControllerDelegate>
@property (nonatomic, readonly) ROPWindowController *windowController;
@end

@implementation ReorderPalettesPlugin

+ (void)load {
    // Match the host protocol without linking against a particular SDK build.
    Protocol *protocol = objc_getProtocol("GlyphsPlugin");
    if (protocol) class_addProtocol(self, protocol);
}

- (NSUInteger)interfaceVersion {
    return 1;
}

- (NSMenuItem *)showRegistrationWindowMenuItem {
    for (NSMenuItem *menuItem in [[NSApp mainMenu] itemArray]) {
        for (NSMenuItem *submenuItem in [[menuItem submenu] itemArray]) {
            if ([submenuItem action] == NSSelectorFromString(@"showRegistrationWindow:")) {
                return submenuItem;
            }
        }
    }
    return nil;
}

- (NSString *)title {
    return NSLocalizedString(@"Reorder Palettes...", nil);
}

- (void)loadPlugin {
    if (!InstallSidebarHook()) {
        NSLog(@"Reorder Palettes: this Glyphs build does not expose the expected sidebar sort method.");
        return;
    }
    NSMenuItem *registrationItem = [self showRegistrationWindowMenuItem];
    NSMenu *menu = registrationItem.menu ?: NSApp.mainMenu.itemArray.firstObject.submenu;
    if (!menu) return;

    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:self.title
                                                action:@selector(handleMenuItemAction:)
                                         keyEquivalent:@""];
    item.target = self;
    NSInteger index = registrationItem ? [menu indexOfItem:registrationItem] + 1 : menu.numberOfItems;
    [menu insertItem:[NSMenuItem separatorItem] atIndex:index];
    [menu insertItem:item atIndex:index + 1];
}

- (void)handleMenuItemAction:(id)sender {
    if (_windowController) {
        [_windowController showWindow:nil];
        [_windowController.window makeKeyAndOrderFront:nil];
        return;
    }
    if (![ROPPalettePlugin availablePalettePluginsWithOptions:ROPPalettePluginEnumeratingOptionsNone].count) {
        NSAlert *alert = [NSAlert new];
        alert.messageText = @"Open a font window first";
        alert.informativeText = @"Glyphs loads the palettes when it builds the font window.";
        [alert runModal];
        return;
    }
    ROPWindowController *windowController = [[ROPWindowController alloc] init];
    _windowController = windowController;
    windowController.delegate = self;
    [windowController.window center];
    [windowController showWindow:nil];
}

#pragma mark -

- (void)windowController:(ROPWindowController *)windowController didReorderPalettePluginsWithDictionary:(NSDictionary<NSString *, NSNumber *> *)dictionary {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (dictionary) [defaults setObject:dictionary forKey:ROPOrderKey];
    else [defaults removeObjectForKey:ROPOrderKey];

    for (id sidebar in loadedSidebars.allObjects) {
        @try {
            RefreshSidebar(sidebar);
        } @catch (NSException *exception) {
            NSLog(@"Reorder Palettes: could not update the open sidebar: %@", exception);
        }
    }
}

- (void)windowController:(ROPWindowController *)windowController willCloseWindow:(NSWindow *)window {
    // Release the controller after its window-close callback has returned.
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self->_windowController == windowController) self->_windowController = nil;
    });
}

@end
