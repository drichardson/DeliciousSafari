//
//  DeliciousAPI.h
//  Safari Delicious Extension
//
//  Created by Douglas Richardson on 7/31/07.
//  Copyright 2007 Douglas Richardson. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const kDXPostURLKey;
extern NSString* const kDXPostDescriptionKey;
extern NSString* const kDXPostExtendedKey;
extern NSString* const kDXPostTagArrayKey;
extern NSString* const kDXPostTimeKey;
extern NSString* const kDXPostHashKey;
extern NSString* const kDXPostShouldReplace;
extern NSString* const kDXPostShouldShare;

@protocol DXDeliciousAPIDelegate <NSObject>
// Response to [DXDeliciousAPI updateRequest]
- (void)deliciousAPIUpdateResponse:(NSDate*)lastUpdatedTime;

// Response to [DXDeliciousAPI postsAllRequest]
- (void)deliciousAPIPostAllResponse:(NSArray*)posts;

// Response to [DXDeliciousAPI postAddRequest:...]
- (void)deliciousAPIPostAddResponse:(BOOL)didSucceed withPost:(NSDictionary*)postDictionary;

// Response to [DXDeliciousAPI postDeleteRequest:...]
- (void)deliciousAPIPostDeleteResponse:(BOOL)didSucceed withRemovedURL:(NSString*)removedURL;

// Delicious credential management. Called when the API needs to login.
- (NSString*)deliciousAPIGetUsername;
- (NSString*)deliciousAPIGetPassword;
- (void)deliciousAPIBadCredentials;

// Called when there is an error talking to Delicious
- (void)deliciousAPIConnectionFailedWithError:(NSError*)error;

// Response to a [DXDeliciousAPI URLInfoRequest:]
- (void)deliciousAPIURLInfoResponse:(NSDictionary*)urlInfo;
@end

@interface DXDeliciousAPI : NSObject {
	id <DXDeliciousAPIDelegate> mDelegate;
	NSString *mUserAgent;
	
	NSURL *mBaseURL;
	NSURL *mBaseJSONURL;
	
	NSDateFormatter *mDateStampFormatter;
	BOOL mAreCredentialsCleared;
	NSDate *mNextAllowedRequestTime;
	
#ifdef DELICIOUSSAFARI_PLUGIN_TARGET
	NSMutableArray *mRequestQueue;
	NSString *mQueueFilePath;
	NSString *mQueueFileDirectory;
	BOOL mIsProcessingQueueEntries;
#else
	NSDictionary *mLastPostAddDictionary;
#endif
	
	NSMutableArray *mPostDeleteQueue;
}

+(DXDeliciousAPI*)sharedInstance;

- (id)initWithUserAgent:(NSString*)userAgent;
- (void)setDelegate:(id <DXDeliciousAPIDelegate>)delegate;

- (void)clearSavedCredentials;

// Returns the last update time for the user.
// Use this before calling postsAll to see if the data has changed since the last fetch.
- (void)updateRequest;

#if 0
#error Needs testing
// Returns a list of tags and number of times used by a user.
- (void)getTagsRequest;
#endif

// Returns all posts. Please use sparingly.
// Call the update function to see if you need to fetch this at all.
- (void)postsAllRequest;

// Save a bookmark to Delicious.
- (void)postAddRequest:(NSString*)url withDescription:(NSString*)description
		  withExtended:(NSString*)extended withTags:(NSArray*)tags withDateStamp:(NSDate*)dateStamp
	 withShouldReplace:(NSNumber*)shouldReplace withIsShared:(NSNumber*)shouldShare;

- (void)postDeleteRequest:(NSString*)url;

// Get tag suggestions for a URL with URLInfoRequest:
- (void)URLInfoRequest:(NSString*)url;

#ifdef DELICIOUSSAFARI_PLUGIN_TARGET
// TODO: Refactor startProcessPendingBookmarks into another class.
// Start processing any bookmarks that haven't been saved to Delicious yet. This logic really should
// be in a consumer of this API. This is trying up application logic to close to the Delicious API.
-(void)startProcessingPendingBookmarks;
#endif

@end

#define kDeliciousAPIErrorDomain @"com.delicioussafari.DeliciousSafari.ErrorDomain"
extern const int kDXDeliciousThrottleCode;