//
//  DeliciousSafariAppDelegate.h
//  DeliciousSafari
//
//  Created by Doug Richardson on 6/21/08.
//  Copyright Douglas Ryan Richardson 2008. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MainNavigationViewController.h"

@interface DeliciousSafariAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate> 
{
	IBOutlet UIWindow *window;
	
	MainNavigationViewController *navigationViewController;
}

- (void)createBookmarklet;
- (void)showSaveBookmarkViewWithURL:(NSString*)url withTitle:(NSString*)title animated:(BOOL)shouldAnimate;

@property (nonatomic, retain) UIWindow *window;

@end
