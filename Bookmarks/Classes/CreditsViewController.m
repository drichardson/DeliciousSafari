//
//  CreditsViewController.m
//  Bookmarks
//
//  Created by Brian Ganninger on 1/17/09.
//  Copyright 2009 Douglas Richardson. All rights reserved.
//

#import "CreditsViewController.h"
#import "UITableViewController+BrowserViewAdditions.h"

@implementation CreditsViewController

@synthesize imageHeaderView;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	self.tableView.tableHeaderView = imageHeaderView;
    [super viewDidLoad];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *creditsIdentifier = @"CreditsCell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:creditsIdentifier];
	
	if (!cell)
	{
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
									   reuseIdentifier:creditsIdentifier] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	}
	
	switch (indexPath.row)
	{
		case 0:
			cell.textLabel.text = @"DeliciousSafari";
			break;
		case 1:
			cell.textLabel.text = @"Infinite Nexus Software";
			break;
		default:
			break;
	}
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *urlString = nil;
	
	if (indexPath.row == 0)
		urlString = @"http://delicioussafari.com";
	else if (indexPath.row == 1)
		urlString = @"http://www.infinitenexus.com";
	
	[self openURLInBrowser:urlString];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return @"Brought to you by:";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

- (void)dealloc {
    [super dealloc];
}

@end
