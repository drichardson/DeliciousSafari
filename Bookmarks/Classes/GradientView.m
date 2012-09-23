//
//  GradientView.m
//  ShadowedTableView
//
//  Created by Matt Gallagher on 2009/08/21.
//  Copyright 2009 Matt Gallagher. All rights reserved.
//

#import "GradientView.h"
#import <QuartzCore/QuartzCore.h>

@implementation GradientView

//
// layerClass
//
// returns a CAGradientLayer class as the default layer class for this view
//
+ (Class)layerClass
{
	return [CAGradientLayer class];
}

//
// setupGradientLayer
//
// Construct the gradient for either construction method
//
- (void)setupGradientLayer
{
	UIColor *standardColor = [UIColor colorWithRed:0.864 green:0.883 blue:0.910 alpha:1.000];

	CAGradientLayer *gradientLayer = (CAGradientLayer *)self.layer;
	gradientLayer.colors =
		[NSArray arrayWithObjects:
			(id)standardColor.CGColor,
			(id)standardColor.CGColor,
		nil];
	self.backgroundColor = [UIColor clearColor];
}

//
// initWithFrame:
//
// Initialise the view.
//
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
	if (self)
	{
		UIColor *standardColor = [UIColor colorWithRed:0.864 green:0.883 blue:0.910 alpha:1.000];

		CAGradientLayer *gradientLayer = (CAGradientLayer *)self.layer;
		gradientLayer.colors =
			[NSArray arrayWithObjects:
				(id)standardColor.CGColor,
				(id)standardColor.CGColor,
				//(id)[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0].CGColor,
				//(id)[UIColor colorWithRed:0.85 green:0.85 blue:0.85 alpha:1.0].CGColor,
			nil];
		self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

@end
