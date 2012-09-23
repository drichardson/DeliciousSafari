//
//  FixedMailComposerViewController.m
//  Bookmarks
//
//  Created by Brian Ganninger on 10/5/09.
//  Copyright 2009 Infinite Nexus Software. All rights reserved.
//

#import "FixedMailComposerViewController.h"


@implementation FixedMailComposerViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	if (interfaceOrientation == UIDeviceOrientationPortraitUpsideDown)
		return NO;
	return YES;
}

@end
