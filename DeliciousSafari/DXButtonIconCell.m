//
//  DXButtonIconCell.m
//  Safari Delicious Extension
//
//  Created by Doug on 1/6/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "DXButtonIconCell.h"

@implementation DXButtonIconCell

-(void)dealloc
{
	[self setIconImage:nil];
	[super dealloc];
}

-(void)setIconImage:(NSImage*)newImage
{
	image = newImage;
	
#if 0
	// this causes a crash - probably due to weak references being used in the outline view. If this
	// is released here but the outline view has a weak reference to it, then the object will be destroyed
	// and when the outlive view tries to access it a crash will occur. Probably, the outline view should
	// be informed the images are gone.
	if(image != newImage)
	{
		NSImage *tmp = image;
		image = [newImage retain];
		[tmp release];
	}
#endif
}


- (NSRect)drawTitle:(NSAttributedString *)title withFrame:(NSRect)frame inView:(NSView *)controlView
{	
	if (image != nil) {
        NSRect	imageFrame;
        NSSize imageSize = [image size];
        NSDivideRect(frame, &imageFrame, &frame, 3 + imageSize.width, NSMinXEdge);
        imageFrame.origin.x += 0;//3;
        imageFrame.size = imageSize;
		
        if ([controlView isFlipped])
            imageFrame.origin.y += ceil((frame.size.height + imageFrame.size.height) / 2);
        else
            imageFrame.origin.y += ceil((frame.size.height - imageFrame.size.height) / 2);
		
        [image compositeToPoint:imageFrame.origin operation:NSCompositeSourceOver];
    }
	
	return [super drawTitle:title withFrame:frame inView:controlView];
}

@end
