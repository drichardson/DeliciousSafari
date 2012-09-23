//
//  BrowserViewController.m
//  Bookmarks
//
//  Created by Brian Ganninger on 2/23/09.
//  Copyright 2009 Infinite Nexus Software. All rights reserved.
//

#import "BrowserViewController.h"
#import "DeliciousSafariAppDelegate.h"
#import "SaveBookmarkViewController.h"
#import "FixedMailComposerViewController.h"
#import <SystemConfiguration/SystemConfiguration.h>

@interface BrowserViewController (private)
- (BOOL)isNetworkReachableForURL:(NSURL *)aURL;
- (void)enableButtonsForWebView:(UIWebView *)currentView;
- (void)updateToolbarItems;
- (void)showConnectionAlert;
@end

@implementation BrowserViewController

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle
{
	self = [super initWithNibName:nibName bundle:nibBundle];
	
	stopButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(stop:)];
	refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh:)];
	
	return self;
}

- (void)viewDidAppear:(BOOL)animated
{
	[UIApplication sharedApplication].applicationSupportsShakeToEdit = YES;

	self.navigationController.navigationBar.clipsToBounds = NO;
	pathBarItem.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	pathBarItem.frame = CGRectMake(pathBarItem.frame.origin.x, pathBarItem.frame.origin.y, 400, pathBarItem.frame.size.height);	
	self.navigationItem.titleView = pathBarItem;
	
	pathURLField.textColor = [UIColor grayColor];
		
	[self updateToolbarItems];
	[self enableButtonsForWebView:webView];
	
	[super viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	if (didStartAnimation)
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	
	[UIApplication sharedApplication].applicationSupportsShakeToEdit = NO;
	[super viewDidDisappear:animated];
}
 
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

- (void)dealloc {
	[pathBarItem release];
	[pathURLField release];
	[activityView release];
	[browserToolbar release];
	
	[webView setDelegate:nil];
	[webView release];

	[toolbarItems release];
	[stopButton release];
	[refreshButton release];
	[lastRequest release];
	[attemptedURL release];
    [super dealloc];
}

- (BOOL)webView:(UIWebView *)incomingWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	[lastRequest release];
	lastRequest = [[request mainDocumentURL] copy];
	
	if (navigationType == UIWebViewNavigationTypeLinkClicked)
		[self performSelector:@selector(reloadLinkRequest:) withObject:request afterDelay:1.0];
	
	return YES;
}

- (void)reloadLinkRequest:(NSURLRequest *)request
{
	[webView loadRequest:request];
}

- (void)webViewDidStartLoad:(UIWebView *)loadingView
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timedTest:) object:nil];
	
	didStartAnimation = YES;
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	[activityView startAnimating];
	
	[self updateToolbarItems];
	[self enableButtonsForWebView:loadingView];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	// do we want to present an error to the user in this case? 
}

- (void)webViewDidFinishLoad:(UIWebView *)loadingView
{
	pathURLField.text = [[loadingView.request mainDocumentURL] description];
	[pathURLField setNeedsDisplay];

	[activityView stopAnimating];
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	
	didStartAnimation = NO;
	
	[self updateToolbarItems];
	[self enableButtonsForWebView:loadingView];
}

- (void)openURL:(NSURL *)aURL
{
	if ([self isNetworkReachableForURL:aURL])
	{		
		NSURLRequest *docRequest = [NSURLRequest requestWithURL:aURL];
		[webView loadRequest:docRequest];
	}
	else
	{
		[attemptedURL release];
		attemptedURL = [aURL copy];
		[self showConnectionAlert];
	}
}

- (IBAction)addBookmark:(id)sender
{
	NSString *url = [[webView.request mainDocumentURL] description];
	NSString *title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
	
	SaveBookmarkViewController *saveBookmarkViewController = [[[SaveBookmarkViewController alloc] initWithNibName:@"SaveBookmarkView" bundle:[NSBundle mainBundle]] autorelease];
	
	saveBookmarkViewController.urlString = url;
	saveBookmarkViewController.titleString = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	[UIApplication sharedApplication].applicationSupportsShakeToEdit = YES;
	[self.navigationController presentModalViewController:saveBookmarkViewController animated:YES];
	
	if (url == nil && title == nil)
		[saveBookmarkViewController configureForAdd];
}

- (IBAction)actionClicked:(id)sender
{
	UIActionSheet *actionSheet = [[[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Open in Safari", nil), NSLocalizedString(@"Mail Link to this Page", nil), NSLocalizedString(@"Copy Link to this Page", nil), nil] autorelease];
	[actionSheet showInView:[webView superview]];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 0)
	{
		[[UIApplication sharedApplication] openURL:[webView.request mainDocumentURL]];		
	}
	else if (buttonIndex == 1)
	{
		[UIApplication sharedApplication].applicationSupportsShakeToEdit = YES;
		FixedMailComposerViewController *newMailMsg = [[[FixedMailComposerViewController alloc] init] autorelease];
		newMailMsg.mailComposeDelegate = self;
		[newMailMsg setSubject:[webView stringByEvaluatingJavaScriptFromString:@"document.title"]];
		[newMailMsg setMessageBody:[NSString stringWithFormat:@"%@", [webView.request mainDocumentURL]] isHTML:YES];
		[self presentModalViewController:newMailMsg animated:YES];
	}
	else if (buttonIndex == 2)
	{
		[[UIPasteboard generalPasteboard] setString:pathURLField.text];
	}
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
	[UIApplication sharedApplication].applicationSupportsShakeToEdit = NO;
	[self dismissModalViewControllerAnimated:YES];
}

- (IBAction)refresh:(id)sender
{
	NSURL *requestToTry = nil;
	
	if (lastRequest && [self isNetworkReachableForURL:lastRequest])
		requestToTry = lastRequest;
	else if (attemptedURL && [self isNetworkReachableForURL:attemptedURL])
		requestToTry = attemptedURL;
	
	if (requestToTry)
	{
		[webView loadRequest:[NSURLRequest requestWithURL:requestToTry]];
		
		[activityView startAnimating];
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
		
		if ([toolbarItems containsObject:refreshButton])
			[toolbarItems removeObject:refreshButton];
		
		if (![toolbarItems containsObject:stopButton])
			[toolbarItems insertObject:stopButton atIndex:5];
		
		[browserToolbar setItems:toolbarItems animated:NO];
		
		[self enableButtonsForWebView:webView];		
	}
	else
	{
		[self showConnectionAlert];
	}
}

- (IBAction)stop:(id)sender
{
	[webView stopLoading];

	[activityView stopAnimating];
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
		
	if ([toolbarItems containsObject:stopButton])
		[toolbarItems removeObject:stopButton];
	
	if (![toolbarItems containsObject:refreshButton])
		[toolbarItems insertObject:refreshButton atIndex:5];
	
	[browserToolbar setItems:toolbarItems animated:NO];

	[self enableButtonsForWebView:webView];
}

- (void)enableButtonsForWebView:(UIWebView *)currentView
{
	backButton.enabled = currentView.canGoBack;
	forwardButton.enabled = currentView.canGoForward;
	
	BOOL isURLPresent = !([currentView.request mainDocumentURL] == nil);
	
	actionButton.enabled = isURLPresent;
	addButton.enabled = isURLPresent;	
}

- (void)updateToolbarItems
{
	if (toolbarItems)
		[toolbarItems release];
	toolbarItems = [[browserToolbar items] mutableCopy];

	if (webView.loading)
	{
		if ([toolbarItems containsObject:refreshButton])
			[toolbarItems removeObject:refreshButton];
		
		if (![toolbarItems containsObject:stopButton])
			[toolbarItems insertObject:stopButton atIndex:5];
	}
	else
	{
		if ([toolbarItems containsObject:stopButton])
			[toolbarItems removeObject:stopButton];
		
		if (![toolbarItems containsObject:refreshButton])
			[toolbarItems insertObject:refreshButton atIndex:5];
	}
	
	[browserToolbar setItems:toolbarItems animated:NO];
}

- (BOOL)isNetworkReachableForURL:(NSURL *)aURL
{
	// Before trying to connect, verify we have a network connection
	SCNetworkReachabilityFlags flags;
	SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, [[aURL host] UTF8String]);
	BOOL gotFlags = NO;
	BOOL result = YES;
	
	if(reachability)
	{
		gotFlags = SCNetworkReachabilityGetFlags(reachability, &flags);
		CFRelease(reachability);
	}
	
	if(gotFlags)
	{
		if (flags & kSCNetworkReachabilityFlagsConnectionRequired || !(flags & kSCNetworkReachabilityFlagsReachable)) 
		{
			//NSLog(@"Network Reachability: No, we are not connected.");
			result = NO;
		}
		else 
		{
			//NSLog(@"Network Reachability: Yes, we are connected.");
			result = YES;
		}
	}
	else
	{
		//NSLog(@"Network Reachability: Can't tell for sure, try anyway.");
		result = YES;
	}
	
	return result;
}

- (void)showConnectionAlert
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Cannot Open Page", @"Title of connection unavailable alert.")
													message:NSLocalizedString(@"Bookmarks cannot open the page because it is not connected to the Internet.", @"Message text of connection unavailable alert.")
												   delegate:nil
										  cancelButtonTitle:NSLocalizedString(@"OK", nil)
										  otherButtonTitles:nil];
	[alert show];
	[alert release];	
}

@end
