//
//  DXDeliciousExtender.h
//  Safari Delicious Extension
//
//  Created by Douglas Richardson on 7/29/07.
//  Copyright 2007 Douglas Richardson. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <SystemConfiguration/SystemConfiguration.h>

#import "DXDeliciousAPI.h"
#import "DXDeliciousDatabase.h"
#import "DXHyperlinkedTextField.h"
#import "DXFavoritesDataSource.h"
#import "DXSafariBookmarkDataSource.h"
#import "DXFlowLayoutView.h"
#import "DXTagMenuController.h"

@interface DXDeliciousExtender : NSObject <DXDeliciousAPIDelegate, DXDeliciousDatabaseFaviconCallback, NSTextViewDelegate> {
	DXDeliciousAPI *mAPI;
	NSDate *mAPILastUpdatedTime;
	DXDeliciousDatabase *mDB;
	NSWindow *mCurrentSheet;
	NSMenu *mDeliciousMenu;
	BOOL mIsDeliciousMenuAdded;
	NSImage *folderImage;
	NSImage *urlImage;
	NSImage *toolbarItemImage;
	SEL afterLoginCallback;
	NSBundle *deliciousSafariBundle;
    NSArray* deliciousSafariBundleTopLevelObjects;
	
	DXTagMenuController *mAllTagsController;
	DXTagMenuController *mFavoriteTagsController;
	
	IBOutlet NSWindow *loginWindow;
	IBOutlet NSTextField *loginUsername;
	IBOutlet NSTextField *loginPassword;
	IBOutlet NSProgressIndicator *loginProgress;
	IBOutlet NSTextField *loginErrorMessage;
	IBOutlet DXHyperlinkedTextField *loginWindowUserRegistrationLink;
	
	IBOutlet NSWindow *postWindow;
	IBOutlet NSTextField *postURL;
	IBOutlet NSTextField *postName;
	IBOutlet NSTextView *postNotes;
	IBOutlet NSTextField *postNotesCharactersUsed;
	IBOutlet NSTokenField *postTags;
	IBOutlet NSButton *doNotShare;
	IBOutlet NSProgressIndicator *postLoadingPopularTagsProgress;
	IBOutlet DXFlowLayoutView *postPopularTagsLayoutView;
	IBOutlet NSTextField *postErrorMessage;
	NSTextView *spellCheckingFieldEditor;
	
	IBOutlet NSWindow *favoriteTagsWindow;
	IBOutlet NSTableView *favoriteTagsTable;
	IBOutlet NSTokenField *favoriteTagsToAdd;
	DXFavoritesDataSource *favoritesDataSource;
	
	IBOutlet NSWindow *importerWindow;
	IBOutlet NSOutlineView *importerBookmarkOutlineView;
	IBOutlet NSProgressIndicator *importerProgress;
	IBOutlet NSTextField *importerMessage;
	IBOutlet NSTokenField *importerAddTags;
	IBOutlet NSButton *importerImportButton;
	IBOutlet NSButton *importerDoNotShareButton;
	IBOutlet NSButton *importerShouldReplaceButton;
	DXSafariBookmarkDataSource *importerDataSource;
	NSMutableArray *itemsToImport;
	BOOL isImportCancelled;
	NSArray *importTagsToAdd;
	
	IBOutlet NSWindow *aboutWindow;
	IBOutlet DXHyperlinkedTextField *aboutWindowDeliciousSafariLink;
	IBOutlet NSTextField *aboutWindowVersion;

	SCNetworkReachabilityRef mNetworkReachabilityRef;
}

- (IBAction)loginPressed:(id)sender;
- (IBAction)loginCancelPressed:(id)sender;

- (IBAction)postPressed:(id)sender;
- (IBAction)postCancelPressed:(id)sender;

- (IBAction)favoriteMoveUpPressed:(id)sender;
- (IBAction)favoriteMoveDownPressed:(id)sender;
- (IBAction)favoriteRemovePressed:(id)sender;
- (IBAction)favoriteAddTagPressed:(id)sender;
- (IBAction)favoriteOKPressed:(id)sender;
- (IBAction)favoriteCancelPressed:(id)sender;

- (IBAction)importerImportPressed:(id)sender;
- (IBAction)importerCancelPressed:(id)sender;
- (IBAction)importerItemCheckPressed:(id)sender;

@end
