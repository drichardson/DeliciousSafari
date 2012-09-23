//
//  RefreshWindow.m
//  Bookmarks
//
//  Created by Brian Ganninger on 4/2/09.
//  Copyright 2009 Doug Richardson. All rights reserved.
//

#import "RefreshWindow.h"

@implementation RefreshWindow

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
	if (motion == UIEventSubtypeMotionShake && [[NSUserDefaults standardUserDefaults] boolForKey:@"shakeToRefresh"] && ![UIApplication sharedApplication].applicationSupportsShakeToEdit)
		[[NSNotificationCenter defaultCenter] postNotificationName:@"ShakeToRefreshNotification" object:nil];
	
	[super motionEnded:motion withEvent:event];
}

@end
