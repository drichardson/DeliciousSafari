//
//  SaveBookmarkViewController.m
//  Bookmarks
//
//  Created by Doug on 8/1/08.
//  Copyright 2008 Doug Richardson. All rights reserved.
//

#import "SaveBookmarkViewController.h"
#import "BookmarksDeliciousAPIManager.h"
#import "DeliciousSafariAppDelegate.h"

const NSUInteger kBottomPadding = 10;


@interface SaveBookmarkViewController (private)
-(void)showAlertWithMessage:(NSString*)message withFirstResponderAfterOK:(UIView*)newFirstResponder;
@end

@implementation SaveBookmarkViewController

@synthesize urlString, titleString;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		isKeyboardVisible = NO;
	}
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	urlTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
	titleTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
	descriptionTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
	tagsTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
	
	NSDictionary *post = [[DXDeliciousDatabase defaultDatabase] postForURL:urlString];
	NSString *title = nil;
	NSString *notes = nil;
	NSString *tags = nil;
	
	if(post != nil)
	{
		// This entry already exists so display the existing information.
		// At this point, the shared flag isn't available via the API.
		title = [post objectForKey:kDXPostDescriptionKey];
		notes = [post objectForKey:kDXPostExtendedKey];
		tags = [[post objectForKey:kDXPostTagArrayKey] componentsJoinedByString:@" "];
	}
	
	if(title == nil)
		title = titleString;
	
	urlTextField.text = urlString;
	titleTextField.text = title;
	descriptionTextField.text = notes;
	tagsTextField.text = tags;
	
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	[nc addObserver:self selector:@selector(urlInfoResponse:) name:kDeliciousURLInfoResponseNotification object:nil];
	[nc addObserver:self selector:@selector(failureNotification:) name:kDeliciousBadCredentialsNotification object:nil];
	[nc addObserver:self selector:@selector(failureNotification:) name:kDeliciousConnectionFailedNotification object:nil];
	
	popularTagsFlowLayoutView.horizontalPadding = 2.0;
	popularTagsFlowLayoutView.verticalPadding = 2.0;
	
	[popularTagsLoadingIndicator startAnimating];
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

	[[BookmarksDeliciousAPIManager sharedManager] URLInfoRequest:urlString];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void)dismissMe
{
    if ( [self respondsToSelector:@selector(presentingViewController)] )
    {
        [self.presentingViewController dismissModalViewControllerAnimated:YES];
    }
    else
    {
        [self.parentViewController dismissModalViewControllerAnimated:YES];
    }
}

-(void)postAddResponseHandler:(NSNotification*)notification
{
	//NSLog(@"postAddResponseHandler; %@", [notification userInfo]);
	
	NSNumber *didSucceed = [[notification userInfo] objectForKey:kDeliciousPostAddResponse_DidSucceedKey];
	NSDictionary *postDictionary = [[notification userInfo] objectForKey:kDeliciousPostAddResponse_PostDictionaryKey];
	
	if(didSucceed == nil || postDictionary == nil)
		NSLog(@"[SaveBookmarkViewController postAddResponseHandler:] - Got nil for didSucceed (%p) or postDictionary (%p)", didSucceed, postDictionary);
	
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	
	if([didSucceed boolValue])
	{
		[UIApplication sharedApplication].applicationSupportsShakeToEdit = NO;
        [self dismissMe];
	}
	else
	{
		NSString *message = NSLocalizedString(@"The bookmark was not saved. Please try again later.", @"Message displayed when error occurs while saving a bookmark.");
		[self showAlertWithMessage:message withFirstResponderAfterOK:nil];
		
		cancelButton.enabled = YES;
		navigationBar.topItem.rightBarButtonItem = saveButton;
	}
}

-(IBAction)addBookmarklet:(id)sender
{
	[(DeliciousSafariAppDelegate *)[[UIApplication sharedApplication] delegate] createBookmarklet];
}

-(IBAction)saveBookmarkPressed:(id)sender
{
	if(urlTextField.text.length == 0)
	{
		[self showAlertWithMessage:NSLocalizedString(@"You must enter a URL.", @"Error message when the user tries to save a bookmark with a blank URL.")
		 withFirstResponderAfterOK:urlTextField];
		return;
	}
	
	if(titleTextField.text.length == 0)
	{
		[self showAlertWithMessage:NSLocalizedString(@"You must enter a title.", @"Error message when the user tries to save a bookmark with a blank title.")
		 withFirstResponderAfterOK:titleTextField];
		return;
	}
	
	cancelButton.enabled = NO;
	
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	
	UIActivityIndicatorView *activityIndicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
	[activityIndicator startAnimating];
	navigationBar.topItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:activityIndicator] autorelease];
	
	[urlTextField resignFirstResponder];
	[descriptionTextField resignFirstResponder];
	[tagsTextField resignFirstResponder];
	[titleTextField resignFirstResponder];
	
	BOOL isShared = sharedSwitch.on;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postAddResponseHandler:) name:kDeliciousPostAddResponseNotification object:nil];
	
	[[BookmarksDeliciousAPIManager sharedManager] postAddRequest:urlTextField.text
									withDescription:titleTextField.text
									   withExtended:descriptionTextField.text
										   withTags:[tagsTextField.text componentsSeparatedByString:@" "]
									  withDateStamp:[NSDate date]
								  withShouldReplace:[NSNumber numberWithBool:YES]
									   withIsShared:[NSNumber numberWithBool:isShared]];
}

-(IBAction)cancelPressed:(id)sender
{
	[UIApplication sharedApplication].applicationSupportsShakeToEdit = NO;
    [self dismissMe];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return NO;
}

-(void)urlInfoResponse:(NSNotification*)notification
{
	//NSLog(@"urlInfoResponse: %@", [notification userInfo]);
	
	[popularTagsLoadingIndicator stopAnimating];
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	
	NSDictionary *urlInfo = [[notification userInfo] objectForKey:kDeliciousURLInfoResponse_URLInfoKey];
	if(urlInfo == nil)
		goto bail;
	
	for(NSString *tag in [urlInfo objectForKey:@"top_tags"])
	{
		UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
		[button addTarget:self action:@selector(postPopularTagPressed:) forControlEvents:UIControlEventTouchUpInside];
		[button setTitle:tag forState:UIControlStateNormal];
		[button sizeToFit];
		[popularTagsFlowLayoutView addSubview:button];
	}
    
    [popularTagsFlowLayoutView sizeToFit];
	
bail:
	;
}

-(void)failureNotification:(NSNotification*)notification
{
	navigationBar.topItem.rightBarButtonItem = saveButton;
	cancelButton.enabled = YES;
	
	if([[notification name] isEqual:kDeliciousConnectionFailedNotification])
	{
		// If there is a connection error then the URL info request isn't going to complete either.
		[popularTagsLoadingIndicator stopAnimating];
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	}
}

-(void)postPopularTagPressed:(id)sender
{
	NSString *tags = tagsTextField.text;
	if(tags == nil)
		tags = @"";
	else
		tags = [tags stringByAppendingString:@" "];
	
	tagsTextField.text = [tags stringByAppendingString:[((UIButton*)sender) titleForState:UIControlStateNormal]];
}

-(void)showAlertWithMessage:(NSString*)message withFirstResponderAfterOK:(UIView*)newFirstResponder
{
	viewToSetAsFirstResponderAfterAlert = newFirstResponder;
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error Saving Bookmark", @"Alert title when error occurs while saving a bookmark.")
													message:message
												   delegate:self
										  cancelButtonTitle:NSLocalizedString(@"OK", nil)
										  otherButtonTitles:nil];
	[alert show];
	[alert release];
}

- (void)configureForAdd
{
	navigationBar.topItem.title = NSLocalizedString(@"Add Bookmark", @"Title for adding instead of saving a bookmark from Safari.");
	popularTagsLabel.hidden = YES;
	popularTagsLoadingIndicator.hidden = YES;
	popularTagsFlowLayoutView.hidden = YES;
	addBookmarkButton.hidden = NO;
	
	// reset all fields since the sheet can be invoked multiple times
	urlTextField.text = @"";
	titleTextField.text = @"";
	tagsTextField.text = @"";
	descriptionTextField.text = @"";
	sharedSwitch.on = YES;
	cancelButton.enabled = YES;
	navigationBar.topItem.rightBarButtonItem = saveButton;
	
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

#pragma mark UIAlertViewDelegate Methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if(viewToSetAsFirstResponderAfterAlert != nil)
		[viewToSetAsFirstResponderAfterAlert becomeFirstResponder];
}

@end
