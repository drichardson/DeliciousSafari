//
//  DXToolbarController.h
//  Safari Delicious Extension
//
//  Created by Doug on 5/9/08.
//  Copyright 2008 Douglas Richardson. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DXToolbarController : NSObject {
	NSMutableDictionary *mItemsDictionary;
	NSToolbar *mBrowserWindowToolbar;
}

// There is only one controller. It cannot be reused for other toolbars.
+(DXToolbarController*)theController;

-(void)addToolbarItem:(NSToolbarItem*)toolbarItem withDefaultPosition:(NSInteger)defaultPosition;

@end
