//
//  DXTagMenuController.h
//  Safari Delicious Extension
//
//  Created by Doug on 4/27/08.
//  Copyright 2008 Douglas Richardson. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DXDeliciousDatabase.h"

@interface DXTagMenuController : NSObject {
	NSMenu *mMenu;
	int mMenuIndex;
	DXDeliciousDatabase *mDatabase;
	NSArray *mRestrictToTags;
	NSImage *mTagImage;
	NSImage *mDefaultURLImage;
	BOOL mHasAddedTopLevelItems;
	NSMutableDictionary *mMenuToTagArrayMap;
	NSObject* mMenuItemTarget;
	SEL mMenuItemAction;
	NSString *mEmptyTagsTitle;
}

-(id)initWithDatabase:(DXDeliciousDatabase*)database
			 withMenu:(NSMenu*)menu
		 withTagImage:(NSImage*)tagImage
  withDefaultURLImage:(NSImage*)defaultURLImage
   withMenuItemTarget:(NSObject*)target
   withMenuItemAction:(SEL)action;

-(id)initWithDatabase:(DXDeliciousDatabase*)database
			 withMenu:(NSMenu*)menu atIndex:(int)index
		 withTagImage:(NSImage*)tagImage
  withDefaultURLImage:(NSImage*)defaultURLImage
   withMenuItemTarget:(NSObject*)target
   withMenuItemAction:(SEL)action
   withRestrictToTags:(NSArray*)tagArray;

@end
