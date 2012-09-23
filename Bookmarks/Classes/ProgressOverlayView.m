//
//  ProgressOverlayView.m
//  Bookmarks
//
//  Created by Brian Ganninger on 9/26/09.
//  Copyright 2009 Infinite Nexus Software. All rights reserved.
//

#import "ProgressOverlayView.h"


@implementation ProgressOverlayView


- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // Initialization code
		self.backgroundColor = [UIColor clearColor];
		self.alpha = 0.0;
		self.opaque = NO;
		spinnerView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		[self addSubview:spinnerView];
		
		CGRect spinnerStart = spinnerView.frame;
		spinnerStart.origin.x = (frame.size.width - spinnerStart.size.width) / 2;
		spinnerStart.origin.y = (frame.size.height - spinnerStart.size.height) / 2 - 15;
		spinnerView.frame = spinnerStart;
		
		displayText = [[UILabel alloc] initWithFrame:CGRectZero];
		displayText.textColor = [UIColor whiteColor];
		displayText.backgroundColor = [UIColor clearColor];
		displayText.opaque = NO;
		displayText.text = @"Saving Bookmark…";
		displayText.font = [UIFont boldSystemFontOfSize:17];
		[displayText sizeToFit];
		[self addSubview:displayText];
		
		CGRect labelStart = displayText.frame;
		labelStart.origin.y = frame.size.height - labelStart.size.height - 34;
		labelStart.origin.x = (frame.size.width - labelStart.size.width) / 2;
		displayText.frame = labelStart;
    }
    return self;
}


- (void)drawRect:(CGRect)drawingRect {
	float radius = 20.0f;
	
	CGRect rect = self.bounds;
	CGContextRef context = UIGraphicsGetCurrentContext();   
	rect = CGRectInset(rect, 1.0f, 1.0f);
	
	CGContextBeginPath(context);
	CGContextSetRGBFillColor(context, 0.0, 0.0, 0.0, 0.6);
	CGContextMoveToPoint(context, CGRectGetMinX(rect) + radius, CGRectGetMinY(rect));
	CGContextAddArc(context, CGRectGetMaxX(rect) - radius, CGRectGetMinY(rect) + radius, radius, 3 * M_PI / 2, 0, 0);
	CGContextAddArc(context, CGRectGetMaxX(rect) - radius, CGRectGetMaxY(rect) - radius, radius, 0, M_PI / 2, 0);
	CGContextAddArc(context, CGRectGetMinX(rect) + radius, CGRectGetMaxY(rect) - radius, radius, M_PI / 2, M_PI, 0);
	CGContextAddArc(context, CGRectGetMinX(rect) + radius, CGRectGetMinY(rect) + radius, radius, M_PI, 3 * M_PI / 2, 0);
	
	CGContextClosePath(context);
	CGContextFillPath(context);
}


- (void)dealloc {
    [super dealloc];
}

- (void)showOverlay
{
	[UIView beginAnimations:@"ProgressFadeIn" context:nil];
	[UIView setAnimationDuration:0.3];
	[UIView setAnimationBeginsFromCurrentState:YES];
	
	[self setAlpha:1.0];
	
	[UIView commitAnimations];
	
	[spinnerView startAnimating];
}

- (void)endOverlay
{
	[spinnerView stopAnimating];
	
//	[UIView beginAnimations:@"ProgressFadeOut" context:nil];
//	[UIView setAnimationDuration:0.3];
//	[UIView setAnimationBeginsFromCurrentState:YES];
	
	[self setAlpha:0.0];
	
//	[UIView commitAnimations];	
}

@end
