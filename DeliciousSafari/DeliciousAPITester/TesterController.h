//
//  TesterController.h
//  Safari Delicious Extension Test Code
//
//  Created by Douglas Richardson.
//  Copyright 2007 Douglas Richardson. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DXDeliciousAPI.h"
#import "DXDeliciousDatabase.h"

@interface TesterController : NSObject
{
    IBOutlet NSTextField *password;
    IBOutlet NSTextField *postDescription;
    IBOutlet NSTextField *postExtendedDescription;
    IBOutlet NSTextField *postURL;
	IBOutlet NSTextField* postTags;
    IBOutlet NSTextView *results;
    IBOutlet NSTextField *username;
	
	DXDeliciousAPI *mAPI;
	DXDeliciousDatabase *mDB;
}

// API Testing
- (IBAction)getAllPosts:(id)sender;
- (IBAction)getTags:(id)sender;
- (IBAction)post:(id)sender;
- (IBAction)update:(id)sender;

// Database Testing
- (IBAction)getAllDatabasePosts:(id)sender;
- (IBAction)getAllDatabaseTags:(id)sender;
@end
