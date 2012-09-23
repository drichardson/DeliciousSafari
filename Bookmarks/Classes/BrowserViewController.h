//
//  CreditsViewController.h
//  Bookmarks
//
//  Created by Brian Ganninger on 2/23/09.
//  Copyright 2009 Douglas Richardson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface BrowserViewController : UIViewController <UIWebViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate> {
	IBOutlet	UIBarButtonItem		*backButton;
	IBOutlet	UIBarButtonItem		*forwardButton;
	IBOutlet	UIBarButtonItem		*actionButton;
	IBOutlet	UIBarButtonItem		*addButton;
	
	IBOutlet	UIToolbar		*browserToolbar;
	
	IBOutlet	UIView			*pathBarItem;
	IBOutlet	UITextField		*pathURLField;

	IBOutlet	UIActivityIndicatorView	*activityView;
	IBOutlet	UIWebView	*webView;
	
	UIBarButtonItem *stopButton;
	UIBarButtonItem *refreshButton;
	
	NSMutableArray *toolbarItems;
	
	NSURL *lastRequest;
	NSURL *attemptedURL;
	
	BOOL didStartAnimation;
}

- (IBAction)addBookmark:(id)sender;
- (IBAction)actionClicked:(id)sender;

- (IBAction)stop:(id)sender;
- (IBAction)refresh:(id)sender;

- (void)openURL:(NSURL *)aURL;

@end
