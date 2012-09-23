//
//  DXFaviconDownloader.m
//  DeliciousSafari
//
//  Created by Douglas Richardson on 8/14/08.
//  Copyright 2008 Douglas Richardson. All rights reserved.
//

#import "DXFaviconDownloader.h"


static NSData* FaviconDataFromURL(NSURL* url);

@implementation DXFaviconDownloader

-(id)initWithURLArray:(NSArray*)urlArray withFaviconDatabase:(DXFaviconDatabase*)faviconDatabase
{
	self = [super init];
	if(self)
	{
		if(urlArray == nil || faviconDatabase == nil)
		{
			NSLog(@"[DXFaviconDatabase initWithURLArray:withFaviconDatabase:] - urlArray (%p) or faviconDatabase (%p) is nil", urlArray, faviconDatabase);
			[self release];
			return nil;
		}
		
		mFaviconDatabase = [faviconDatabase retain];
		
		mFaviconURLsToDownload = [urlArray retain];
		if(mFaviconURLsToDownload)
		{
			mItemEnumerator = [[mFaviconURLsToDownload objectEnumerator] retain];
			mFaviconResults = [[NSMutableDictionary alloc] init];
			mFaviconFailures = [[NSMutableArray alloc] init];
			
			const unsigned kMaxThreadsToStart = 25;
			mRunningThreadCount = [mFaviconURLsToDownload count];
			if(mRunningThreadCount > kMaxThreadsToStart)
				mRunningThreadCount = kMaxThreadsToStart;
			
			if(MPCreateSemaphore(mRunningThreadCount, 0, &mThreadWaitSemaphore) != noErr)
			{
				NSLog(@"Error creating semaphore for favicon download thread pool.");
				[self release];
				return nil;
			}
			
			//NSLog(@"Starting %d threads", mRunningThreadCount);
			
			unsigned i;
			for(i = 0; i < mRunningThreadCount; ++i)
			{
				[NSThread detachNewThreadSelector:@selector(downloaderThread:) toTarget:self withObject:nil];
			}
		}		
	}
	return self;
}

-(id)initWithURLArray:(NSArray*)urlArray
{
	return [self initWithURLArray:urlArray withFaviconDatabase:[DXFaviconDatabase defaultDatabase]];
}

-(void)dealloc
{
	// Wait for all threads to finish before completing the dealloc.
	[self waitForDownloadsToComplete];
	
	[mItemEnumerator release];
	[mFaviconURLsToDownload release];
	[mFaviconResults release];
	[mFaviconFailures release];
	[mFaviconDatabase release];
	MPDeleteSemaphore(mThreadWaitSemaphore);
	[super dealloc];
}

-(NSURL*)getNextURL
{
	NSURL *result = nil;
	
	if(mItemEnumerator != nil)
	{
		@synchronized(mItemEnumerator)
		{
			result = [mItemEnumerator nextObject];
		}
	}
	
	return result;
}

-(void)addToFailedResultsWithURL:(NSURL*)failedURL
{
	NSString *host = [failedURL host];
	
	if(host != nil && mFaviconResults != nil)
	{
		@synchronized(mFaviconFailures)
		{
			[mFaviconFailures addObject:host];
		}
	}
}

-(void)downloaderThread:(id)arg
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSURL *faviconURL;
	
	while((faviconURL = [self getNextURL]) != nil)
	{
		NSAutoreleasePool *subpool = [[NSAutoreleasePool alloc] init];
		
		//NSLog(@"Processing %@ in thread %@", faviconURL, [NSThread currentThread]);
		
		NSData *faviconImageData = FaviconDataFromURL(faviconURL);
		
		if(faviconImageData != nil)
		{
			[mFaviconDatabase addFavicon:faviconImageData forURLString:[faviconURL absoluteString]];
			mSuccessfulDownloadCount++;
		}
		else if(faviconURL != nil)
			[self addToFailedResultsWithURL:faviconURL];
		else
			NSLog(@"DeliciousSafari got unexpected nil faviconURL in favicon download thread.");
		
		[subpool release];
	}
	
	//NSLog(@"Exiting thread about to signal semaphore");
	MPSignalSemaphore(mThreadWaitSemaphore);
	
	[pool release];
}

-(void)waitForDownloadsToComplete
{
	// Block until threads are done processing.
	while(mRunningThreadCount > 0)
	{
		MPWaitOnSemaphore(mThreadWaitSemaphore, kDurationForever);
		mRunningThreadCount--;
		//NSLog(@"Got %d left", mRunningThreadCount);
	}
}

-(NSArray*)failures
{
	[self waitForDownloadsToComplete];
	return mFaviconFailures;
}

-(unsigned)successfulDownloadCount
{
	return mSuccessfulDownloadCount;
}

@end

//
// Favicon routines
//

// Create a CGImageSourceRef from raw data
static CGImageRef CreateCGImageFromURL(NSURL* url)
{
    CGImageRef imageRef = NULL;
    CGImageSourceRef sourceRef = CGImageSourceCreateWithURL((CFURLRef)url, NULL);
    
	if(sourceRef)
	{
        imageRef = CGImageSourceCreateImageAtIndex(sourceRef, 0, NULL);
        CFRelease(sourceRef);
    }
	
	return imageRef;
}

static CGImageRef ResizeFaviconToStandardSize(CGImageRef faviconImageRef)
{
	CGColorSpaceRef rgbRef = NULL;
	CGContextRef contextRef = NULL;
	CGImageRef resultRef = NULL;
	const CGRect standardRect = CGRectMake(0, 0, 16, 16);
	const size_t kBytesPerPixel = 4;
	const size_t kBitsPerComponent = 8;
	
	rgbRef = CGColorSpaceCreateDeviceRGB();
	if(rgbRef == NULL)
		goto bail;
	
	contextRef = CGBitmapContextCreate(NULL,
									   standardRect.size.width,
									   standardRect.size.height,
									   kBitsPerComponent,
									   standardRect.size.width * kBytesPerPixel,
									   rgbRef,
									   kCGImageAlphaPremultipliedLast);
	if(contextRef == NULL)
		goto bail;
	
	CGContextSetInterpolationQuality(contextRef, kCGInterpolationHigh);
	CGContextDrawImage(contextRef, standardRect, faviconImageRef);
	
	resultRef = CGBitmapContextCreateImage(contextRef);
	
bail:
	if(rgbRef)
		CGColorSpaceRelease(rgbRef);
	
	if(contextRef)
		CGContextRelease(contextRef);
	
	return resultRef;
}

static NSData* FaviconDataFromURL(NSURL* url)
{	
	NSMutableData *imageData = nil;
	CGImageDestinationRef destination = NULL;
	CGImageRef resizedFaviconImageRef = NULL;
	CGImageRef faviconImageRef = CreateCGImageFromURL(url);
	
	if(faviconImageRef == NULL)
		goto bail;
	
	imageData = [NSMutableData data];
	destination = CGImageDestinationCreateWithData((CFMutableDataRef)imageData, kUTTypePNG, 1, NULL);
	if(destination == NULL)
		goto bail;
	
	resizedFaviconImageRef = ResizeFaviconToStandardSize(faviconImageRef);
	if(resizedFaviconImageRef == NULL)
		goto bail;
	
	CGImageDestinationAddImage(destination, resizedFaviconImageRef, NULL);
	CGImageDestinationFinalize(destination);
	
bail:
	
	if(resizedFaviconImageRef)
		CGImageRelease(resizedFaviconImageRef);
	
	if(faviconImageRef)
		CFRelease(faviconImageRef);
	
	if(destination)
		CFRelease(destination);
	
	return imageData;
}
