//
//  TagListViewController.h
//  DeliciousSafari
//
//  Created by Doug Richardson on 6/21/08.
//  Copyright 2008 Douglas Ryan Richardson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RefreshButtonTableViewController.h"

@interface AllTagsTableViewController : RefreshButtonTableViewController {
	NSArray *tagsBySection;
	NSDictionary *titleToSectionMap;
	UILabel *footerText;
	NSUInteger totalTags;
	NSNumberFormatter *numberFormatter;
}

@property (nonatomic, retain) NSArray *tagsBySection;
@property (nonatomic, retain) NSDictionary *titleToSectionMap;
@property (nonatomic, retain) NSNumberFormatter *numberFormatter;

// protected methods - Should only be used by sub-classes.
-(BOOL)isTagListEmpty;

@end
