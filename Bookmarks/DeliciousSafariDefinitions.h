/*
 *  DeliciousSafariDefinitions.h
 *  DeliciousSafariPhoneApp
 *
 *  Created by Doug Richardson on 6/27/08.
 *  Copyright 2008 Douglas Ryan Richardson. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>

// Notifications related to del.icio.us messages
extern NSString* kDeliciousBadCredentialsNotification;
extern NSString* kDeliciousConnectionFailedNotification;
extern NSString* kDeliciousPostsUpdatedNotification;
extern NSString* kDeliciousPostAddResponseNotification;
extern NSString* kDeliciousURLInfoResponseNotification;

extern NSString* kDeliciousURLInfoResponse_URLInfoKey;

extern NSString* kDeliciousPostAddResponse_DidSucceedKey;
extern NSString* kDeliciousPostAddResponse_PostDictionaryKey;



// Keys for optional notification userInfo dictionaries.
extern NSString* kDeliciousConnectionFailedNotification_NSErrorKey;

// Higher level notifications.
extern NSString* kDeliciousLoginCompleteNotification;

// Settings
extern NSString* kUserDefault_Password;
extern NSString *kUserDefault_LastViewKey;
extern NSString *kUserDefault_LastViewTop;
extern NSString *kUserDefault_LastViewAllTags;
extern NSString *kUserDefault_LastViewFavorites;
extern NSString *kUserDefault_LastViewRecents;
extern NSString *kUserDefault_LastViewContacts;
