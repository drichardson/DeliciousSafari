//
//  FlowLayoutView.m
//  Bookmarks
//
//  Created by Doug on 10/12/08.
//  Copyright 2008 Douglas Richardson. All rights reserved.
//

#import "FlowLayoutView.h"

@interface FlowLayoutView ()
-(void)layoutInternalShouldUpdateSubviewFrames:(BOOL)shouldUpdateSubviewFrames usingSize:(CGSize)size idealSize:(CGSize*)idealSize;
@end

@implementation FlowLayoutView

@synthesize horizontalPadding, verticalPadding;

-(void)addSubview:(UIView*)aView
{
	[super addSubview:aView];
    [self setNeedsLayout];
}

-(void)layoutInternalShouldUpdateSubviewFrames:(BOOL)shouldUpdateSubviewFrames usingSize:(CGSize)size idealSize:(CGSize*)idealSize
{
    // Starting from the first control, draw it and maintain a width and height.
	// Keep moving to the right + padding until you can't draw a control, then wrap. Wrap
	// using the max control height in the row we just finished + padding.
	
	float currentX = 0, currentY = 0;
	float maxHeightForCurrentRow = 0;
	int objectCountForRow = 0;
	
	for(UIView* view in self.subviews)
	{
		CGRect frame = view.frame;
		
		if(objectCountForRow > 0 && currentX + frame.size.width >= size.width)
		{
			currentY += maxHeightForCurrentRow + verticalPadding;
			currentX = 0;
			objectCountForRow = 0;
            maxHeightForCurrentRow = 0;
		}
		else
			objectCountForRow++;
		
		frame.origin = CGPointMake(currentX, currentY);
        
        if ( shouldUpdateSubviewFrames )
        {
            view.frame = frame;
        }
		
		currentX += horizontalPadding + frame.size.width;
		if(frame.size.height > maxHeightForCurrentRow)
			maxHeightForCurrentRow = frame.size.height;
	}
    
    if ( idealSize )
    {
        *idealSize = CGSizeMake(size.width, currentY + maxHeightForCurrentRow);
    }
}

-(void)layoutSubviews
{
    [self layoutInternalShouldUpdateSubviewFrames:YES usingSize:self.bounds.size idealSize:NULL];
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGSize result = CGSizeZero;
    [self layoutInternalShouldUpdateSubviewFrames:NO usingSize:size idealSize:&result];
    return result;
}

-(void)setFrame:(CGRect)newFrame
{
	[super setFrame:newFrame];
	[self setNeedsLayout];
}

@end
