//
//  BookmarkListViewController.h
//  DeliciousSafari
//
//  Created by Doug Richardson on 6/21/08.
//  Copyright 2008 Douglas Ryan Richardson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RefreshButtonTableViewController.h"

@interface BookmarkListViewController : RefreshButtonTableViewController {
	NSMutableArray *_postsArray;
	UILabel *footerText;
	NSNumberFormatter *numberFormatter;
}

@property (nonatomic, retain) NSArray* postsArray;
@property (nonatomic, retain) NSNumberFormatter* numberFormatter;

@end

#define kBookmarkCellLabelViewTag 1
UITableViewCell* CreateBookmarkTableViewCell(NSString *reuseIdentifier);
