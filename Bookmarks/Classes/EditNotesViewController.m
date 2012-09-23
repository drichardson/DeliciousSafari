//
//  EditNotesViewController.m
//  Bookmarks
//
//  Created by Brian Ganninger on 9/27/09.
//  Copyright 2009 Infinite Nexus Software. All rights reserved.
//

#import "EditNotesViewController.h"


@implementation EditNotesViewController


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView 
{
	self.navigationItem.title = @"Notes";
	
	if (notesText == nil)
	{
		notesText = [[UITextView alloc] initWithFrame:CGRectZero];
		notesContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
	}
	
	self.view = notesContainer;
	[self.view addSubview:notesText];
	notesText.font = [UIFont systemFontOfSize:20];
	notesText.frame = CGRectMake(0, 0, 320, 200);
}

- (void)setEditEnabled:(BOOL)shouldEdit
{
	notesText.editable = shouldEdit;
	if (shouldEdit)
		[notesText becomeFirstResponder];
	else
		[notesText resignFirstResponder];
}

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}

@end
