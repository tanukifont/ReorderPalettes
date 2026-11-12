//
//  ROPWindowController.m
//  ReorderPalettes
//
//  Created by Takaaki Fuji on 13/10/2021.
//  Copyright © 2021 Morisawa Inc. All rights reserved.
//

// Adapted for the Glyphs 4 sidebar.
// Modified for Glyphs 4 compatibility in 2026.
#import "ROPWindowController.h"
#import "ROPPalettePlugin.h"
#import "ROPTableColumn.h"

static NSString *const RowPasteboardType = @"jp.co.morisawa.ReorderPalettes.row";

@interface ROPWindowController () <NSTableViewDataSource>
@property (nonatomic, readwrite) NSMutableArray<ROPPalettePlugin *> *mutablePalettePlugins;
@property (nonatomic, weak) IBOutlet NSTableView *tableView;
@property (nonatomic, weak) IBOutlet NSArrayController *arrayController;
@end

@implementation ROPWindowController

- (instancetype)init {
    if ((self = [self initWithWindowNibName:NSStringFromClass([self class]) owner:self])) {
        _mutablePalettePlugins = [[NSMutableArray alloc] initWithCapacity:0];
        [_mutablePalettePlugins addObjectsFromArray:[ROPPalettePlugin availablePalettePluginsWithOptions:ROPPalettePluginEnumeratingOptionsNone]];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [_tableView registerForDraggedTypes:@[RowPasteboardType]];
    [_tableView setDataSource:self];
}

- (IBAction)handleReset:(id)sender {
    [self willChangeValueForKey:@"mutablePalettePlugins"];
    [_mutablePalettePlugins setArray:[ROPPalettePlugin availablePalettePluginsWithOptions:ROPPalettePluginEnumeratingOptionsPreferOriginalSortID]];
    [self didChangeValueForKey:@"mutablePalettePlugins"];
    [_arrayController rearrangeObjects];
    [_tableView reloadData];
}

- (IBAction)handleClose:(id)sender {
    [self close];
}

#pragma mark -

- (BOOL)hasModifiedFromDefaultOrder {
    NSArray<ROPPalettePlugin *> *originallyAvailablePalettePlugins = [ROPPalettePlugin availablePalettePluginsWithOptions:ROPPalettePluginEnumeratingOptionsPreferOriginalSortID];
    return ![_mutablePalettePlugins isEqualToArray:originallyAvailablePalettePlugins];
}

#pragma mark -

- (void)windowWillClose:(NSNotification *)notification {
    if ([[self delegate] respondsToSelector:@selector(windowController:didReorderPalettePluginsWithDictionary:)]) {
        if ([self hasModifiedFromDefaultOrder]) {
            [[self delegate] windowController:self didReorderPalettePluginsWithDictionary:[ROPPalettePlugin dictionaryFromPalettePlugins:_mutablePalettePlugins]];
        } else {
            [[self delegate] windowController:self didReorderPalettePluginsWithDictionary:nil];
        }
    }
    if ([[self delegate] respondsToSelector:@selector(windowController:willCloseWindow:)]) {
        [[self delegate] windowController:self willCloseWindow:[self window]];
    }
}


#pragma mark - Column Autoresizing

- (CGFloat)tableView:(NSTableView *)tableView sizeToFitWidthOfColumn:(NSInteger)column {
    return [(ROPTableColumn *)[[tableView tableColumns] objectAtIndex:column] fittingSize].width;
}

#pragma mark - Drag and Drop Row Reordering

- (nullable id <NSPasteboardWriting>)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row {
    NSPasteboardItem *item = [[NSPasteboardItem alloc] init];
    [item setString:[NSString stringWithFormat:@"%ld", row] forType:RowPasteboardType];
    return item;
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation {
    return (info.draggingSource == tableView && dropOperation == NSTableViewDropAbove &&
            row >= 0 && row <= tableView.numberOfRows) ? NSDragOperationMove : NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation {
    if (![self tableView:tableView validateDrop:info proposedRow:row proposedDropOperation:dropOperation]) return NO;
    NSMutableIndexSet *mutableOriginalRowIndexes = [[NSMutableIndexSet alloc] init];
    [info enumerateDraggingItemsWithOptions:0 forView:tableView classes:@[[NSPasteboardItem class]] searchOptions:@{} usingBlock:^(NSDraggingItem * _Nonnull draggingItem, NSInteger idx, BOOL * _Nonnull stop) {
        NSPasteboardItem *item = [draggingItem item];
        NSString *stringValue = [item stringForType:RowPasteboardType];
        if (stringValue && stringValue.integerValue >= 0 && stringValue.integerValue < tableView.numberOfRows) {
            [mutableOriginalRowIndexes addIndex:[stringValue integerValue]];
        }
    }];
    if (!mutableOriginalRowIndexes.count) return NO;
    NSArray *movedPalettes = [_mutablePalettePlugins objectsAtIndexes:mutableOriginalRowIndexes];
    NSUInteger destination = (NSUInteger)row - [mutableOriginalRowIndexes countOfIndexesInRange:NSMakeRange(0, (NSUInteger)row)];
    NSIndexSet *destinationIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(destination, movedPalettes.count)];

    // Notify the NSArrayController binding once for the complete change.
    [self willChangeValueForKey:@"mutablePalettePlugins"];
    [_mutablePalettePlugins removeObjectsAtIndexes:mutableOriginalRowIndexes];
    [_mutablePalettePlugins insertObjects:movedPalettes atIndexes:destinationIndexes];
    [self didChangeValueForKey:@"mutablePalettePlugins"];
    [_arrayController rearrangeObjects];
    [tableView reloadData];
    [tableView selectRowIndexes:destinationIndexes byExtendingSelection:NO];
    return YES;
}

@end
