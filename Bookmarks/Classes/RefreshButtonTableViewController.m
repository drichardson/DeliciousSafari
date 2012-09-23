//
//  DeliciousRefreshButtonTableViewController.m
//  Bookmarks
//
//  Created by Doug on 10/14/08.
//  Copyright 2008 Douglas Richardson. All rights reserved.
//

#import "RefreshButtonTableViewController.h"
#import "BookmarksDeliciousAPIManager.h"

@interface RefreshButtonTableViewController (private)
- (void)addRefreshButton;
@end

@implementation RefreshButtonTableViewController

- (id)initWithStyle:(UITableViewStyle)style {
    if (self = [super initWithStyle:style]) {
		[[BookmarksDeliciousAPIManager sharedManager] addObserver:self forKeyPath:@"isUpdating" options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

-(void)dealloc
{
	[[BookmarksDeliciousAPIManager sharedManager] removeObserver:self forKeyPath:@"isUpdating"];
	[super dealloc];
}

- (void)refreshReceived:(NSNotification *)refreshNote
{
	[self refreshPressed:nil];
}

- (void)viewWillAppear:(BOOL)animated
{	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshReceived:) name:@"ShakeToRefreshNotification" object:nil];
	if([[BookmarksDeliciousAPIManager sharedManager] isUpdating])
		[self startActivityIndicator];
	else
		self.navigationItem.rightBarButtonItem = nil;

	[super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super viewWillDisappear:animated];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    // Configure the cell
    return cell;
}

- (void)addRefreshButton
{
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
																							target:self
																							action:@selector(refreshPressed:)] autorelease];
}

- (void)startActivityIndicator
{
	UIActivityIndicatorView *activityIndicatorView = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:activityIndicatorView] autorelease];
	[activityIndicatorView startAnimating];
}

-(void)refreshPressed:(id)sender
{
	//NSLog(@"Refresh pressed: %@", sender);	
	[[BookmarksDeliciousAPIManager sharedManager] updateRequest];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	//NSLog(@"Observed value changed: %@, %@, %@", keyPath, object, change);
	
	if(object == [BookmarksDeliciousAPIManager sharedManager])
	{
		if([keyPath isEqualToString:@"isUpdating"])
		{
			NSNumber *isUpdating = [change objectForKey:NSKeyValueChangeNewKey];
			
			if([isUpdating boolValue])
				[self startActivityIndicator];
			else
			{
				if ([self respondsToSelector:@selector(prepareForEdit)])
					[self performSelector:@selector(prepareForEdit)];
				else
					self.navigationItem.rightBarButtonItem = nil;
			}
		}
	}
}

@end

