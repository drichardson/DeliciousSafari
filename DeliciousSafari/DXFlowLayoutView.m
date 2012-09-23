//
//  DXFlowLayoutView.m
//  DXFlowLayoutView
//
//  Created by Doug Richardson on 1/20/08.
//  Copyright 2008 Douglas Richardson. All rights reserved.
//

#import "DXFlowLayoutView.h"

@interface DXFlowLayoutView (private)
-(void)layout;
@end

@implementation DXFlowLayoutView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		horizontalPadding = 0.0;
		verticalPadding = 0.0;
    }
    return self;
}

-(void)addSubview:(NSView*)aView
{
	[super addSubview:aView];
	[self layout];
}

- (void)addSubview:(NSView *)aView positioned:(NSWindowOrderingMode)place relativeTo:(NSView *)otherView
{
	[super addSubview:aView positioned:place relativeTo:otherView];
	[self layout];
}

-(void)removeAllSubviews
{
	NSView *view;
	while((view = [[self subviews] lastObject]) != nil)
		[view removeFromSuperview];
	
	[self layout];
}

-(void)setHorizontalPadding:(float)padding
{
	horizontalPadding = padding;
	[self setNeedsDisplay:YES];
}

-(void)setVerticalPadding:(float)padding
{
	verticalPadding = padding;
	[self setNeedsDisplay:YES];
}

- (BOOL)isFlipped
{
	return YES;
}

-(void)layout
{
	// Starting from the first control, draw it and maintain a width and height.
	// Keep moving to the right + padding until you can't draw a control, then wrap. Wrap
	// using the max control height in the row we just finished + padding.
	
	NSSize myFrameSize = [self frame].size;
	
	NSEnumerator *viewEnum = [[self subviews] objectEnumerator];
	NSView *view;
	float currentX = 0, currentY = 0;
	float maxHeightForCurrentRow = 0;
	int objectCountForRow = 0;
	
	while(view = [viewEnum nextObject])
	{
		NSRect frame = [view frame];
		
		if(objectCountForRow > 0 && currentX + frame.size.width >= myFrameSize.width)
		{
			currentY += maxHeightForCurrentRow + verticalPadding;
			currentX = 0;
			objectCountForRow = 0;
		}
		else
			objectCountForRow++;
		
		NSPoint origin = NSMakePoint(currentX, currentY);
		[view setFrameOrigin:origin];
		
		currentX += horizontalPadding + frame.size.width;
		if(frame.size.height > maxHeightForCurrentRow)
			maxHeightForCurrentRow = frame.size.height;
	}
}

-(void)setFrame:(NSRect)newFrame
{
	[super setFrame:newFrame];
	[self layout];
}

@end
