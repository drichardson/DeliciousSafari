//
//  CreditsViewController.h
//  Bookmarks
//
//  Created by Brian Ganninger on 1/17/09.
//  Copyright 2009 Douglas Richardson. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CreditsViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource> {
	UIView *imageHeaderView;
}

@property (nonatomic, assign) IBOutlet UIView *imageHeaderView;

@end
