//
//  TopLevelViewController.h
//  Bookmarks
//
//  Created by Doug on 10/6/08.
//  Copyright 2008 Douglas Richardson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RefreshButtonTableViewController.h"
#import "GradientView.h"

@interface TopLevelViewController : RefreshButtonTableViewController <UISearchDisplayDelegate, UISearchBarDelegate>
{
	GradientView *gradientView;
	
	BOOL shouldReloadTable;
	
	NSArray *tagSearchResults;
	NSArray *bookmarkSearchResults;
}

- (void)prepareForEdit;

@end
