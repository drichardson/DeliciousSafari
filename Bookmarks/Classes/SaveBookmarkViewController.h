//
//  SaveBookmarkViewController.h
//  Bookmarks
//
//  Created by Doug on 8/1/08.
//  Copyright 2008 Doug Richardson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FlowLayoutView.h"

@interface SaveBookmarkViewController : UIViewController <UIAlertViewDelegate> {
	IBOutlet UITextField *urlTextField;
	IBOutlet UITextField *titleTextField;
	IBOutlet UITextField *descriptionTextField;
	IBOutlet UITextField *tagsTextField;
	IBOutlet UISwitch *sharedSwitch;
	IBOutlet UIBarButtonItem *saveButton;
	IBOutlet UIBarButtonItem *cancelButton;
	IBOutlet UINavigationBar *navigationBar;
	IBOutlet UIButton *addBookmarkButton;
	
	IBOutlet UILabel *popularTagsLabel;
	IBOutlet UIActivityIndicatorView *popularTagsLoadingIndicator;
	
	IBOutlet FlowLayoutView *popularTagsFlowLayoutView;
	
	IBOutlet UIView *bottomMostView; // For determining the content size for the scroll view.
	
	BOOL isKeyboardVisible;
	
	NSString *urlString;
	NSString *titleString;
	
	UIView *viewToSetAsFirstResponderAfterAlert;
}

-(IBAction)saveBookmarkPressed:(id)sender;
-(IBAction)cancelPressed:(id)sender;
-(IBAction)addBookmarklet:(id)sender;

- (void)configureForAdd;

@property (nonatomic, retain) NSString* urlString;
@property (nonatomic, retain) NSString* titleString;

@end
