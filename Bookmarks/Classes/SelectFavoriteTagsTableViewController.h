//
//  SelectFavoriteTagsTableViewController.h
//  Bookmarks
//
//  Created by Doug on 10/9/08.
//  Copyright 2008 Douglas Richardson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AllTagsTableViewController.h"

@protocol SelectFavoriteTagsTableViewControllerDelegate
-(void)selectFavoriteTagsTableViewControllerTagSelected:(NSString*)tag;
@end

@interface SelectFavoriteTagsTableViewController : AllTagsTableViewController {
	id <SelectFavoriteTagsTableViewControllerDelegate> _delegate;
}

-(void)setDelegate:(id <SelectFavoriteTagsTableViewControllerDelegate>)delegate;

@end
