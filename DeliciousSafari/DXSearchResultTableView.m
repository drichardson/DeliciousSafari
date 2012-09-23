//
//  DXSearchResultTableView.m
//  SearchPrototype
//
//  Created by Doug on 9/23/09.
//  Copyright 2009 Douglas Richardson. All rights reserved.
//

#import "DXSearchResultTableView.h"


@implementation DXSearchResultTableView

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (BOOL)acceptsFirstResponder
{
	return NO;
}

- (void)highlightSelectionInClipRect:(NSRect)clipRect
{
    NSIndexSet *rowIndexes = [self selectedRowIndexes];
	NSColor *highlightColor = [[self window] isKeyWindow] ? [NSColor selectedControlColor] : [NSColor secondarySelectedControlColor];
    
    if ([rowIndexes count] > 0)
    {
        NSRange rowsInClipRect = [self rowsInRect:clipRect];
        for (NSUInteger rowIndex = rowsInClipRect.location; rowIndex < NSMaxRange(rowsInClipRect); rowIndex++)
        {
            if ([rowIndexes containsIndex:rowIndex])
            {				
                NSRect rowRect = NSIntersectionRect([self rectOfRow:rowIndex], clipRect);
				
				[highlightColor set];
                NSRectFill(rowRect);
            }
        }
    }
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	if(newWindow)
	{
		[nc addObserver:self selector:@selector(windowDidBecomeKey:) name:NSWindowDidBecomeKeyNotification object:newWindow];
		[nc addObserver:self selector:@selector(windowDidResignKey:) name:NSWindowDidResignKeyNotification object:newWindow];
	}
	else
	{
		[nc removeObserver:self name:NSWindowDidBecomeKeyNotification object:nil];
		[nc removeObserver:self name:NSWindowDidResignKeyNotification object:nil];
	}

	
	[super viewWillMoveToWindow:newWindow];
}

- (void)windowDidBecomeKey:(NSNotification*)notification
{
	[self setNeedsDisplay];
}

- (void)windowDidResignKey:(NSNotification*)notification
{
	[self setNeedsDisplay];
}

@end
