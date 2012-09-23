//
//  SelectFavoriteTagTableViewController.m
//  Bookmarks
//
//  Created by Doug on 10/9/08.
//  Copyright 2008 Douglas Richardson. All rights reserved.
//

#import "SelectFavoriteTagViewController.h"
#import "DXDeliciousDatabase.h"

NSString *kFavoriteTagsListUpdatedNotification = @"FavoriteTagsListUpdatedNotification";

@implementation SelectFavoriteTagViewController

/*
// Override initWithNibName:bundle: to load the view using a nib file then perform additional customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically.
- (void)loadView {
}
*/


// Implement viewDidLoad to do additional setup after loading the view.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	CGRect navBarFrame = _navigationBar.frame;
	
	CGRect tableViewFrame = self.view.frame;
	tableViewFrame.origin.y = navBarFrame.size.height + navBarFrame.origin.y;
	tableViewFrame.size.height -= tableViewFrame.origin.y;
	[_tagSelectTableViewController.view setFrame:tableViewFrame];
	
	[_tagSelectTableViewController setDelegate:self];
	
	[self.view addSubview:_tagSelectTableViewController.view];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

- (void)dealloc {
    [super dealloc];
}

- (void)dismissMe
{
    if ( [self respondsToSelector:@selector(presentingViewController)] )
    {
        [self.presentingViewController dismissModalViewControllerAnimated:YES];
    }
    else
    {
        [self.parentViewController dismissModalViewControllerAnimated:YES];
    }
}

-(IBAction)cancelPressed:(id)sender
{
    [self dismissMe];
}

-(void)selectFavoriteTagsTableViewControllerTagSelected:(NSString*)tag
{
	NSMutableArray *favoriteTags = [[[[DXDeliciousDatabase defaultDatabase] favoriteTags] mutableCopy] autorelease];
	[favoriteTags addObject:[NSArray arrayWithObject:tag]];
	[[DXDeliciousDatabase defaultDatabase] setFavoriteTags:favoriteTags];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kFavoriteTagsListUpdatedNotification object:nil];
	
    [self dismissMe];
}

@end
