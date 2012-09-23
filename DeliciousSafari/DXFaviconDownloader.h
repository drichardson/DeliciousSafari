//
//  DXFaviconDownloader.h
//  DeliciousSafari
//
//  Created by Douglas Richardson on 8/14/08.
//  Copyright 2008 Douglas Richardson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DXFaviconDatabase.h"

@interface DXFaviconDownloader : NSObject
{
	NSArray *mFaviconURLsToDownload;
	NSEnumerator *mItemEnumerator;
	NSMutableDictionary *mFaviconResults;
	NSMutableArray *mFaviconFailures;
	MPSemaphoreID mThreadWaitSemaphore;
	unsigned mRunningThreadCount;
	unsigned mSuccessfulDownloadCount;
	
	DXFaviconDatabase *mFaviconDatabase;
}

-(id)initWithURLArray:(NSArray*)urlArray withFaviconDatabase:(DXFaviconDatabase*)faviconDatabase;
-(id)initWithURLArray:(NSArray*)urlArray;

-(void)waitForDownloadsToComplete;
-(NSArray*)failures;

-(unsigned)successfulDownloadCount;

@end
