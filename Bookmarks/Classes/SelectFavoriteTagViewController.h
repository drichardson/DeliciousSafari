//
//  SelectFavoriteTagTableViewController.h
//  Bookmarks
//
//  Created by Doug on 10/9/08.
//  Copyright 2008 Douglas Richardson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SelectFavoriteTagsTableViewController.h"

extern NSString *kFavoriteTagsListUpdatedNotification;

@interface SelectFavoriteTagViewController : UIViewController <SelectFavoriteTagsTableViewControllerDelegate> {
	IBOutlet UINavigationBar *_navigationBar;
	IBOutlet SelectFavoriteTagsTableViewController *_tagSelectTableViewController;
}

-(IBAction)cancelPressed:(id)sender;

@end
