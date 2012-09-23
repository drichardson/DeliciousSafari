//
//  UITableViewController+BrowserViewAdditions.m
//  Bookmarks
//
//  Created by Doug on 7/10/09.
//  Copyright 2009 Douglas Richardson. All rights reserved.
//

#import "UITableViewController+BrowserViewAdditions.h"
#import "BrowserViewController.h"

@implementation UITableViewController (BrowserViewAdditions)


- (void)openURLInBrowser:(NSString*)urlString
{
	if(urlString == nil)
	{
		NSLog(@"openURLInBrowser: urlString is nil. Will not open browser.");
		return;
	}
	
	NSURL *url = [NSURL URLWithString:urlString];
	
	if(!url)
	{
		NSLog(@"openURLInBrowser: URL is nil. Will not open browser");
		return;
	}
	
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"OpenInSafari"])
	{
		[[UIApplication sharedApplication] openURL:url];
	}
	else
	{	
		BrowserViewController *browserController = [[BrowserViewController alloc] initWithNibName:@"BrowserView" bundle:nil];
		[self.navigationController pushViewController:browserController animated:YES];	
		[browserController openURL:url];
		[browserController release];
	}
}

@end
