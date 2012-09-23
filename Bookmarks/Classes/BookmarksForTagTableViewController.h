//
//  TagListTableViewController.h
//  Bookmarks
//
//  Created by Doug on 10/20/08.
//  Copyright 2008 Douglas Richardson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BookmarkListViewController.h"

@interface BookmarksForTagTableViewController : BookmarkListViewController {
	NSString *_tag;
}

-(id)initWithTag:(NSString*)tag;

@end
