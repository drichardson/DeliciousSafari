//
//  FavoriteTagsTableViewController.h
//  Bookmarks
//
//  Created by Doug on 10/6/08.
//  Copyright 2008 Douglas Richardson. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface FavoriteTagsTableViewController : UITableViewController {
	NSArray *favoriteTags;
	NSNumberFormatter *numberFormatter;
	UIBarButtonItem *savedNavigationBarItem;
	UILabel *footerText;
	BOOL _isDirty;
}

@property (nonatomic, retain) NSArray* favoriteTags;
@property (nonatomic, retain) UIBarButtonItem* savedNavigationBarItem;
@property (nonatomic, retain) NSNumberFormatter* numberFormatter;

@end
