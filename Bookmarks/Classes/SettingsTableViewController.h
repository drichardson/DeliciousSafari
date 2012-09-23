//
//  SettingsTableViewController.h
//  Bookmarks
//
//  Created by Doug on 10/14/08.
//  Copyright 2008 Douglas Richardson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RefreshButtonTableViewController.h"

@interface SettingsTableViewController : RefreshButtonTableViewController <UITextFieldDelegate> {
	UITextField *_usernameTextField;
	UITextField *_passwordTextField;
	UISwitch	*_shakeSwitch;
}

@end
