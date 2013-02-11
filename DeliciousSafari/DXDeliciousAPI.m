//
//  DeliciousAPI.m
//  Safari Delicious Extension
//
//  Created by Douglas Richardson on 7/31/07.
//  Copyright 2007 Douglas Richardson. All rights reserved.
//

#import "DXDeliciousAPI.h"
#import "DXUtilities.h"
#import <Security/Security.h>
#import <CommonCrypto/CommonDigest.h>
#import "NSScanner+DXBSJSONAdditions.h"

#ifdef DELICIOUSSAFARI_PLUGIN_TARGET
#import <openssl/md5.h>
#import "NSScanner+DXBSJSONAdditions.h"
#else
#import <CoreFoundation/CoreFoundation.h>
#endif

#include <libxml/tree.h>
#include <libxml/parser.h>
#include <libxml/xpath.h>

const int kDXDeliciousThrottleCode = 503;

static BOOL DXRemoveDeliciousAPICredentials(void);
static NSString* GetXMLAttributeValue(xmlNode *node, NSString* attributeName);

@interface DXURLConnection : NSURLConnection
{
	NSMutableData *mReceivedData;
	SEL mResponseSelector;
	BOOL mExpectingXMLResponse;
}

-(id)initWithRequest:theRequest delegate:delegate withResponseSelector:(SEL)responseSelector withExpectingXMLResponse:(BOOL)expectsXMLResponse;

-(SEL)responseSelector;
-(BOOL)expectingXMLResponse;
-(NSMutableData*)receivedData;

@end


@interface DXXMLHelper : NSObject
{
	xmlDocPtr mDocument;
    xmlXPathContextPtr mXPathContext;
}

-(id)initWithXML:(NSData*)xmlDocData;
+(DXXMLHelper*)helperFromXMLDocData:(NSData*)xmlDocData;

-(xmlXPathObjectPtr)evaluateXPath:(NSString*)xPathQuery;
@end

@implementation DXXMLHelper

-(id)initWithXML:(NSData*)xmlDocData
{
	self = [super init];
	
	if(self)
	{
		if(xmlDocData == nil)
		{
			NSLog(@"[DXXMLHelper xmlDocData] - Got nil parameter for XML document data.");
			goto problem;
		}
		
		mDocument = xmlParseMemory([xmlDocData bytes], [xmlDocData length]);
		if (mDocument == NULL)
		{
			NSLog(@"[DXXMLHelper xmlDocData]: unable to parse XML document.");
			goto problem;
		}
	}

	return self;

problem:
	[self release];
	return nil;
}

-(void)dealloc
{
	//xmlXPathFreeObject(xpathObj);
	
	if(mXPathContext)
		xmlXPathFreeContext(mXPathContext);
	
	if(mDocument)
		xmlFreeDoc(mDocument); 
	
	[super dealloc];
}

+(DXXMLHelper*)helperFromXMLDocData:(NSData*)xmlDocData
{
	return [[[self alloc] initWithXML:xmlDocData] autorelease];
}

-(xmlXPathObjectPtr)evaluateXPath:(NSString*)xPathQuery
{
	if(mXPathContext != NULL)
		xmlXPathFreeContext(mXPathContext);
	
	if(xPathQuery == nil)
	{
		NSLog(@"[DXXMLHelper evaluateXPath] - Invalid (nil) XPath query parameter.");
		return NULL;
	}
	
    mXPathContext = xmlXPathNewContext(mDocument);
    if(mXPathContext == NULL)
	{
        NSLog(@"[DXXMLHelper evaluateXPath] - Could not create XPath context.");
        return NULL;
    }

	xmlXPathObjectPtr xpathObj = xmlXPathEvalExpression((xmlChar*)[xPathQuery UTF8String], mXPathContext);
    if(xpathObj == NULL)
	{
        NSLog(@"[DXXMLHelepr evaluateXPath] Unable to evaluate xpath expression \"%@\"\n", xPathQuery);
		return NULL;
    }
	
	return xpathObj;
}

@end


@implementation DXURLConnection
-(id)initWithRequest:theRequest delegate:delegate withResponseSelector:(SEL)responseSelector withExpectingXMLResponse:(BOOL)expectsXMLResponse;
{
	self = [super initWithRequest:theRequest delegate:delegate];
	
	if(self)
	{
		mResponseSelector = responseSelector;
		mExpectingXMLResponse = expectsXMLResponse;
		mReceivedData = [[NSMutableData alloc] init];
	}
	
	return self;
}

-(void)dealloc
{
	[mReceivedData release];
	[super dealloc];
}

-(SEL)responseSelector
{
	return mResponseSelector;
}

-(BOOL)expectingXMLResponse
{
	return mExpectingXMLResponse;
}

-(NSMutableData*)receivedData
{
	return mReceivedData;
}
@end




NSString* const kDXPostURLKey = @"href";
NSString* const kDXPostDescriptionKey = @"description";
NSString* const kDXPostExtendedKey = @"extended";
NSString* const kDXPostTagArrayKey = @"tagArray";
NSString* const kDXPostTimeKey = @"time";
NSString* const kDXPostHashKey = @"hash";

// These keys are not part of the Delicious API, but are used internally for saving information to the queue.
NSString* const kDXPostShouldReplace = @"shouldReplace";
NSString* const kDXPostShouldShare = @"shouldShare";


static NSDate* DXDeliciousAPITimeStringToNSDate(NSString *timeString);
static NSDictionary* DXMakePostDictionary(NSString *href, NSString *description,
										  NSArray *tagArray, NSDate *time,
										  NSString *hash, NSString *extended,
										  NSNumber *shouldShare, NSNumber *shouldReplace);


@interface DXDeliciousAPI (NSURLConnectionDelegates)
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
- (void)connection:(NSURLConnection *)connection
        didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;
@end

@interface DXDeliciousAPI (private)
- (void)startRequestToURL:(NSString*)urlFragment
			 withResponse:(SEL)selector
			isJSONRequest:(BOOL)isJSONRequest
		   relativeToBase:(NSURL*)baseURL;

- (void)startRequestToURL:(NSString*)urlFragment withResponse:(SEL)selector;

#ifdef DELICIOUSSAFARI_PLUGIN_TARGET
- (void)processNextQueueEntry;
- (void)saveQueue;
#endif

- (void)postAddResponse:(NSData*)xmlDoc;

- (NSDate*)nextAllowedRequestTime;

-(NSString*)makePostAddRequestURLWithURL:(NSString*)url
						 withDescription:(NSString*)description
							withExtended:(NSString*)extended
								withTags:(NSArray*)tags
								withDate:(NSDate*)dateStamp
					   withShouldReplace:(NSNumber*)shouldReplace
						 withShouldShare:(NSNumber*)shouldShare;

@end

@implementation DXDeliciousAPI

+(DXDeliciousAPI*)sharedInstance
{
	static DXDeliciousAPI* dsAPI = nil;
	
	if(dsAPI == nil)
	{
		NSBundle *bundle = [NSBundle mainBundle];
		
		NSString *shortVersion = [bundle objectForInfoDictionaryKey:@"CFBundleVersion"];
		if(shortVersion == nil)
			shortVersion = @"0.1";
		
		NSString *agentName = [bundle objectForInfoDictionaryKey:@"CFBundleIdentifier"];
		if(agentName == nil)
			agentName = @"DXDeliciousAPIAgent";
		
		NSString *userAgent = [NSString stringWithFormat:@"%@/%@", agentName, shortVersion];
		
		NSLog(@"Created shared instance with user agent = %@", userAgent);
		
		dsAPI = [[[self class] alloc] initWithUserAgent:userAgent];
	}
	
	return dsAPI;
}

-(id)initWithUserAgent:(NSString*)userAgent
{
    self = [super init];
    
	if(self)
	{
		mAreCredentialsCleared = NO;
		
		mBaseURL = [[NSURL alloc] initWithString:@"https://api.del.icio.us/v1/"];
		mBaseJSONURL = [[NSURL alloc] initWithString:@"http://feeds.delicious.com/v2/json/urlinfo/"];
		
		// Format dates like 1984-09-01T14:21:31Z		
		mDateStampFormatter = [[NSDateFormatter alloc] init];
		[mDateStampFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
		[mDateStampFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
		[mDateStampFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
				
		mUserAgent = [userAgent retain];
		
		// User agent debugging 
		// mBaseURL = [[NSURL alloc] initWithString:@"http://www.ericgiguere.com/tools/http-header-viewer.html;jsessionid=600E4011258C861E40B343BFA84F37C1"];
		
#ifdef DELICIOUSSAFARI_PLUGIN_TARGET
		mQueueFileDirectory = [[@"~/Library/Application Support/DeliciousSafari" stringByExpandingTildeInPath] retain];
		
#if 0
		// This could be used on the phone if ever needed.
		NSArray *pathList = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		if(pathList && [pathList count] > 0)
			mQueueFileDirectory = [[pathList objectAtIndex:0] retain];
		else
			NSLog(@"[DXDeliciousAPI initWithUserAgent:] Could not get directory for queue file.");
#endif
		
		mQueueFilePath = [[mQueueFileDirectory stringByAppendingPathComponent:@"Request Queue.plist"] retain];
		
		mRequestQueue = [NSMutableArray arrayWithContentsOfFile:mQueueFilePath];
		
		if(mRequestQueue == nil)
			mRequestQueue = [NSMutableArray array];
		[mRequestQueue retain];
#endif
		
		mNextAllowedRequestTime = [[NSDate alloc] init];
		mPostDeleteQueue = [[NSMutableArray alloc] init];
	}
	return self;
}

-(void)dealloc
{
	mDelegate = nil;
	[mBaseURL release];
	[mBaseJSONURL release];
	[mDateStampFormatter release];
	[mUserAgent release];
	
#ifdef DELICIOUSSAFARI_PLUGIN_TARGET
	[mRequestQueue release];
	[mQueueFilePath release];
	[mQueueFileDirectory release];
#else
	[mLastPostAddDictionary release];
#endif
	
	[mNextAllowedRequestTime release];
	[mPostDeleteQueue release];
	
	[super dealloc];
}

-(NSString*)makePostAddRequestURLWithURL:(NSString*)url
						 withDescription:(NSString*)description
							withExtended:(NSString*)extended
								withTags:(NSArray*)tags
								withDate:(NSDate*)dateStamp
					   withShouldReplace:(NSNumber*)shouldReplace
						 withShouldShare:(NSNumber*)shouldShare
{
	DXUtilities *utils = [DXUtilities defaultUtilities];
	
	// Required Attributes
	NSString *URLEncodedURL = [@"url=" stringByAppendingString:[utils urlEncode:url]];
	
	NSString *URLEncodedDescription = [@"&description=" stringByAppendingString:[utils urlEncode:description]];
	
	// Optional Attributes
	NSString *URLEncodedExtended = extended == nil ? nil : [@"&extended=" stringByAppendingString:[utils urlEncode:extended]];
	
	NSString *URLEncodedTags = tags == nil ? nil :
	[@"&tags=" stringByAppendingString:[utils urlEncode:[tags componentsJoinedByString:@","]]];
	
	NSString *URLEncodedDatestamp = dateStamp == nil ? nil :
	[@"&dt=" stringByAppendingString:[utils urlEncode:[mDateStampFormatter stringForObjectValue:dateStamp]]];
	
	NSString *URLEncodedShouldReplace = shouldReplace == nil ? nil :
	[@"&replace=" stringByAppendingString:[shouldReplace boolValue] ? @"yes" : @"no"];
	
	NSString *URLEncodedIsShared = shouldShare == nil ? nil :
	[@"&shared=" stringByAppendingString:[shouldShare boolValue] ? @"yes" : @"no"];
	
	// Build the URL request.
	NSMutableString *requestURL = [NSMutableString stringWithFormat:@"posts/add?%@%@", URLEncodedURL, URLEncodedDescription];
	
	if(URLEncodedExtended)
		[requestURL appendString:URLEncodedExtended];
	
	if(URLEncodedTags)
		[requestURL appendString:URLEncodedTags];
	
	if(URLEncodedDatestamp)
		[requestURL appendString:URLEncodedDatestamp];
	
	if(URLEncodedShouldReplace)
		[requestURL appendString:URLEncodedShouldReplace];
	
	if(URLEncodedIsShared)
		[requestURL appendString:URLEncodedIsShared];
	
	//NSLog(@"Request URL: %@", requestURL);
	
	return requestURL;
}

#ifdef DELICIOUSSAFARI_PLUGIN_TARGET
- (void)processNextQueueEntry
{	
	NSDictionary *queueEntry = nil;
	
	if([mRequestQueue count] > 0)
	{
		queueEntry = [mRequestQueue objectAtIndex:0];
		mIsProcessingQueueEntries = YES;
		//NSLog(@"DeliciousSafari - Processing queue entry while the queue count is %d", [mRequestQueue count]);
		//NSLog(@"DeliciousSafari - About to process queue entry: %@", queueEntry);
	}
	else
	{
		//NSLog(@"Done processing queue.");
		mIsProcessingQueueEntries = NO;
		return; // No entries to process.
	}
	
	NSString *url = [queueEntry objectForKey:kDXPostURLKey];
	NSString *description = [queueEntry objectForKey:kDXPostDescriptionKey];
	NSString *extended = [queueEntry objectForKey:kDXPostExtendedKey];
	NSArray *tags = [queueEntry objectForKey:kDXPostTagArrayKey];
	NSDate *dateStamp = [queueEntry objectForKey:kDXPostTimeKey];
	NSNumber *shouldReplace = [queueEntry objectForKey:kDXPostShouldReplace];
	NSNumber *shouldShare = [queueEntry objectForKey:kDXPostShouldShare];
	
	NSString *requestURL = [self makePostAddRequestURLWithURL:url
											  withDescription:description
												 withExtended:extended
													 withTags:tags
													 withDate:dateStamp
											withShouldReplace:shouldReplace
											  withShouldShare:shouldShare];
	
	[self startRequestToURL:requestURL withResponse:@selector(postAddResponse:)];
}

- (void)saveQueue
{
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL isDirectory = NO;
	BOOL exists = [fm fileExistsAtPath:mQueueFileDirectory isDirectory:&isDirectory];
	
	if(exists && !isDirectory)
	{
		// There is some rouge file in our way. Just delete that sucker. Anyone who has the audacity
		// to put a file named DeliciousSafari in their Application Support directory deserves to get burned ;)
		
        NSError* error = nil;
        if(![fm removeItemAtPath:mQueueFileDirectory error:&error])
        {
			NSLog(@"Could not remove rogue %@ file. Please remove it manually. %@", mQueueFileDirectory, error);
        }
		
		exists = NO;
	}
	
	if(!exists)
	{
        NSError* error = nil;
        if(![fm createDirectoryAtPath:mQueueFileDirectory withIntermediateDirectories:YES attributes:nil error:&error])
        {
			NSLog(@"Error creating queue file directory. Queue will not be saved when Safari is quit which may result in Delicious posts being lost. %@", error);
        }
	}
	
	if(![mRequestQueue writeToFile:mQueueFilePath atomically:YES])
		NSLog(@"Could not save Delicious request queue. New Delicious posts may be lost if Safari is quit before they are processed.");
}
#endif

- (void)setDelegate:(id <DXDeliciousAPIDelegate>)delegate
{
	mDelegate = delegate;
}

- (void)clearSavedCredentials
{
	mAreCredentialsCleared = YES;
	
	if(!DXRemoveDeliciousAPICredentials())
		NSLog(@"DeliciousSafari - Error removing Delicious credentials from the keychain.");
}

- (void)startRequestToURL:(NSString*)urlFragment withResponse:(SEL)selector
{
	[self startRequestToURL:urlFragment withResponse:selector isJSONRequest:NO relativeToBase:mBaseURL];
}

- (void)startRequestToURL:(NSString*)urlFragment
			 withResponse:(SEL)selector
			isJSONRequest:(BOOL)isJSONRequest
		   relativeToBase:(NSURL*)baseURL
{	
	//NSLog(@"Credentials: %@", [[NSURLCredentialStorage sharedCredentialStorage] allCredentials]);
	
	// create the request
	NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlFragment relativeToURL:baseURL]
															  cachePolicy:NSURLRequestReloadIgnoringCacheData
														  timeoutInterval:60.0];
	//NSLog(@"theRequest: %@", theRequest);
	[theRequest setValue:mUserAgent forHTTPHeaderField:@"User-Agent"];
		
	// create the connection with the request
	// and start loading the data
	
	
	NSDate *nextAllowedTime = [self nextAllowedRequestTime];
	NSTimeInterval delay = [nextAllowedTime timeIntervalSinceNow];
	if(delay <= 0)
		delay = 0;
	
	[self performSelector:@selector(delayedStartRequestToURL:)
			   withObject:[NSDictionary dictionaryWithObjectsAndKeys:theRequest, @"request",
						   [NSNumber numberWithBool:!isJSONRequest], @"expectingXMLResponse",
						   [NSData dataWithBytes:&selector length:sizeof(selector)], @"selector",
						   nil]
			   afterDelay:delay];
}

// delayedStartRequestToURL should only be called by startRequestToURL:withResponse:isJSONRequest:relativeToBase:
-(void)delayedStartRequestToURL:(NSDictionary*)arguments
{
	//NSLog(@"delayedStartRequestToURL called at %@", [NSDate date]);
	
	NSNumber *expectingXMLResponse = [arguments objectForKey:@"expectingXMLResponse"];
	NSData *selectorData = [arguments objectForKey:@"selector"];
	SEL selector = NULL;
	NSMutableURLRequest *theRequest = [arguments objectForKey:@"request"];

	[selectorData getBytes:&selector length:sizeof(selector)];
	
	if(expectingXMLResponse == nil || selectorData == nil || theRequest == nil)
		NSLog(@"DeliciousSafari - delayedStartRequestToURL got unexpected nil argument.");
	else
	{
		// theConnection is released later on during connection processing.
		DXURLConnection *theConnection = [[DXURLConnection alloc] initWithRequest:theRequest
																		 delegate:self
															 withResponseSelector:selector
														 withExpectingXMLResponse:[expectingXMLResponse boolValue]];
		
		if (theConnection == nil)
		{
			// TODO: inform the user that the download could not be made
			NSLog(@"DeliciousSafari - Communications error.");
		}
	}
}

// https://api.del.icio.us/v1/posts/update
// Returns the last update time for the user.
// Use this before calling https://api.del.icio.us/v1/posts/all? to see if the data has changed
// since the last fetch.
// Example Response
// <update time="2005-11-29T20:31:52Z" />
- (void)updateRequest
{
	//NSLog(@"updateRequest");
	[self startRequestToURL:@"posts/update" withResponse:@selector(updateResponse:)];
}

- (void)updateResponse:(NSData*)xmlDoc
{
	NSDate *lastUpdatedDate = nil;
	
	//NSLog(@"[DXDeliciousAPI updateResponse:]");
	
	//NSArray *nodes = [xmlDoc nodesForXPath:@"/update/@time" error:&error];
	xmlXPathObjectPtr xPathObject = [[DXXMLHelper helperFromXMLDocData:xmlDoc] evaluateXPath:@"/update/@time"];
	if(xPathObject)
	{
		xmlNodeSetPtr nodes = xPathObject->nodesetval;
		
		if(nodes != NULL && nodes->nodeNr > 0 && nodes->nodeTab[0]->type == XML_ATTRIBUTE_NODE)
		{
			xmlChar* timeValue = xmlNodeGetContent(nodes->nodeTab[0]);
			if(timeValue)
			{
				lastUpdatedDate = DXDeliciousAPITimeStringToNSDate([NSString stringWithUTF8String:(const char*)timeValue]);
				xmlFree(timeValue);
			}
		}
		
		xmlXPathFreeObject(xPathObject);
	}
	else
		NSLog(@"DXDeliciousAPI - Error evaluating XPath query in updateResponse.");
	
	if(lastUpdatedDate == nil)
	{
		NSLog(@"Could not get updated date.");
		lastUpdatedDate = [NSDate distantPast];
	}
	
	[mDelegate deliciousAPIUpdateResponse:lastUpdatedDate];
}

// https://api.del.icio.us/v1/tags/get
// Returns a list of tags and number of times used by a user.
// Example Response
// <tags>
//   <tag count="1" tag="activedesktop" />
//   <tag count="1" tag="business" />
//   <tag count="3" tag="radio" />
//   <tag count="5" tag="xml" />
//   <tag count="1" tag="xp" />
//   <tag count="1" tag="xpi" />
// </tags>
- (void)postsAllRequest
{
	[self startRequestToURL:@"posts/all" withResponse:@selector(postsAllResponse:)];
}

- (void)postsAllResponseThread:(NSData*)xmlDoc
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	//NSLog(@"[DXDeliciousAPI postsAllResponseThread]");
	NSMutableArray *postArray = [NSMutableArray array];
	
	xmlXPathObjectPtr xPathObject = [[DXXMLHelper helperFromXMLDocData:xmlDoc] evaluateXPath:@"/posts/post"];
	
	if(xPathObject)
	{
		xmlNodeSetPtr nodes = xPathObject->nodesetval;
		
		if(nodes != NULL && nodes->nodeNr > 0)
		{
			for(int i = 0; i < nodes->nodeNr; ++i)
			{
				xmlNodePtr node = nodes->nodeTab[i];
				
				if(node->type != XML_ELEMENT_NODE)
					continue;
				
				NSAutoreleasePool *innerPool = [[NSAutoreleasePool alloc] init];
				
				NSString *href =		GetXMLAttributeValue(node, kDXPostURLKey);
				NSString *description = GetXMLAttributeValue(node, kDXPostDescriptionKey);
				NSString *tag =			GetXMLAttributeValue(node, @"tag");
				NSString *timeString =	GetXMLAttributeValue(node, kDXPostTimeKey);
				NSString *hash =		GetXMLAttributeValue(node, kDXPostHashKey);
				NSString *extended =	GetXMLAttributeValue(node, kDXPostExtendedKey);
				NSNumber *shouldReplace = [NSNumber numberWithBool:YES];
				NSNumber *shouldShare = [NSNumber numberWithBool:YES];
				
				NSArray *tagArray = [tag componentsSeparatedByString:@" "];		
				NSDate *time = DXDeliciousAPITimeStringToNSDate(timeString);
				
				NSDictionary *post = DXMakePostDictionary(href, description, tagArray, time, hash, extended, shouldReplace, shouldShare);
				if(post)		
					[postArray addObject:post];
				else
				{
					NSLog(@"Error adding Delicious post because on of the values was nil (%@, %@, %@, %@, %@, %@)",
						  href, description, tagArray, time, hash, extended);
				}
				
				[innerPool release];
			}
		}
		
		xmlXPathFreeObject(xPathObject);
	}
	else
		NSLog(@"DXDeliciousAPI - Error processing postsAllResponse");
	
	//NSLog(@"[DXDeliciousAPI postsAllResponseThread] calling delegate");
	
	if([mDelegate isKindOfClass:[NSObject class]])
		[(NSObject*)mDelegate performSelectorOnMainThread:@selector(deliciousAPIPostAllResponse:) withObject:postArray waitUntilDone:NO];
	else
		NSLog(@"Expected delegate to be an NSObject but it is not. Cannot send message to it on the main thread.");
	
	//NSLog(@"[DXDeliciousAPI postsAllResponseThread] returning");
	
	[pool release];
}

- (void)postsAllResponse:(NSData*)xmlDoc
{
	[NSThread detachNewThreadSelector:@selector(postsAllResponseThread:) toTarget:self withObject:xmlDoc];	
}

#if 0
#error not used - needs testing
// Returns all posts. Please use sparingly.
// Call the update function to see if you need to fetch this at all.
- (void)getTagsRequest
{
	[self startRequestToURL:@"tags/get" withResponse:@selector(getTagsResponse:)];
}

- (void)getTagsResponse:(NSXMLDocument*)xmlDoc
{
	NSMutableArray *tagArray = [NSMutableArray array];
	NSError *error = nil;
	
	NSArray *nodes = [xmlDoc nodesForXPath:@"/tags/tag" error:&error];
	
	if(nodes == nil)
	{
		NSLog(@"getTagsResponse: %@", error);
	}
	
	//NSLog(@"getTagsResponse: nodes: %@", nodes);
	
	NSEnumerator *nodeEnum = [nodes objectEnumerator];
	NSXMLElement *tagElement = nil;
	while(tagElement = [nodeEnum nextObject])
	{
		NSString *tagName = [[tagElement attributeForName:@"tag"] stringValue];
		
		NSNumber *count = nil;
		const char* countStr = [[[tagElement attributeForName:@"count"] stringValue] UTF8String];
		count = [NSNumber numberWithInt:countStr ? atoi(countStr) : 0];
		
		[tagArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:tagName, @"tag", count, @"count", nil]];
	}
	
	[mDelegate deliciousAPIGetTagsResponse:tagArray];
}
#endif

- (void)postAddRequest:(NSString*)url withDescription:(NSString*)description
		  withExtended:(NSString*)extended withTags:(NSArray*)tags withDateStamp:(NSDate*)dateStamp
	 withShouldReplace:(NSNumber*)shouldReplace withIsShared:(NSNumber*)shouldShare
{
	// Make all the parameters acceptable.	
	if(url == nil || description == nil)
	{
		NSLog(@"postAddRequest a required parameter is nil: url = %@, description = %@", url, description);
		return;
	}
	
	if(extended == nil)
		extended = @"";
	
	if(tags == nil)
		tags = [NSArray array];
	
	if(dateStamp == nil)
		dateStamp = [NSDate date];
	
	if(shouldReplace == nil)
		shouldReplace = [NSNumber numberWithBool:YES];
	
	if(shouldShare == nil)
		shouldShare = [NSNumber numberWithBool:YES];
	
	NSDictionary *queueEntry = DXMakePostDictionary(url, description, tags, dateStamp, @"placeholder", extended, shouldShare, shouldReplace);
	
#ifdef DELICIOUSSAFARI_PLUGIN_TARGET
	// Add the object to the request queue.
	[mRequestQueue addObject:queueEntry];
	//NSLog(@"DeliciousSafari - Added item to request queue. Count is now %d", [mRequestQueue count]);
	[self saveQueue]; // Write the queue to file in case Safari is quit before it is saved to Delicious
	
	if(!mIsProcessingQueueEntries)
		[self processNextQueueEntry]; // Start processing the queue if the process is not already started.
#else
	NSString *requestURL = [self makePostAddRequestURLWithURL:url
											  withDescription:description
												 withExtended:extended
													 withTags:tags
													 withDate:dateStamp
											withShouldReplace:shouldReplace
											  withShouldShare:shouldShare];
	
	if(mLastPostAddDictionary)
		[mLastPostAddDictionary release];
	mLastPostAddDictionary = [queueEntry retain];
	
	[self startRequestToURL:requestURL withResponse:@selector(postAddResponse:)];
#endif
}

- (void)postAddResponse:(NSData*)xmlDocData
{
	BOOL didSucceed = NO;
	NSDictionary *postDictionary = nil;
	
#ifdef DELICIOUSSAFARI_PLUGIN_TARGET
	if([mRequestQueue count] > 0)
	{
		// Make sure the postDictionary says around after it is removed from the request queue.
		// It doesn't look like objectAtIndex: does a retain autorelease, so we'll do one ourself.
		postDictionary = [[[mRequestQueue objectAtIndex:0] retain] autorelease];
		[mRequestQueue removeObjectAtIndex:0];
		[self saveQueue];
	}
	else
	{
		NSLog(@"DeliciousSafari internal error - the request queue should never be <= 0 here.");
		return;
	}
#else
	postDictionary = [[mLastPostAddDictionary retain] autorelease];
#endif
	
	xmlXPathObjectPtr xPathObject = [[DXXMLHelper helperFromXMLDocData:xmlDocData] evaluateXPath:@"/result/@code"];
	
	if(xPathObject)
	{
		xmlNodeSetPtr nodes = xPathObject->nodesetval;
		
		if(nodes && nodes->nodeNr > 0 && nodes->nodeTab[0]->type == XML_ATTRIBUTE_NODE)
		{
			NSString *resultCode = nil;
			
			xmlChar *resultCodeStr = xmlNodeGetContent(nodes->nodeTab[0]);
			if(resultCodeStr)
			{
				resultCode = [NSString stringWithUTF8String:(const char*)resultCodeStr];
				xmlFree(resultCodeStr);
			}
			
			//NSLog(@"Result code: %@", resultCode);
			
			if([resultCode isEqual:@"done"] || [resultCode isEqual:@"item already exists"])
			{
				didSucceed = YES;
			}
			else
			{
				NSLog(@"Post did not succeed. Result code is: %@", resultCode);
				didSucceed = NO;
			}
		}
		
		xmlXPathFreeObject(xPathObject);
	}
	else
		NSLog(@"DXDeliciousAPI - Error evaluating XPath in postAddResponse");
	
	if(postDictionary == nil)
		postDictionary = [NSDictionary dictionary];
	
	[mDelegate deliciousAPIPostAddResponse:didSucceed withPost:postDictionary];
	
#ifdef DELICIOUSSAFARI_PLUGIN_TARGET
	// Only process the next queue entry if this post was successful. Otherwise, user intervention is required.
	if(didSucceed)
		[self processNextQueueEntry];
#endif
}

- (void)postDeleteRequest:(NSString*)url
{
	// Make all the parameters acceptable.	
	if(url == nil)
	{
		NSLog(@"postDeleteRequest: url is nil");
		return;
	}
	
	[mPostDeleteQueue addObject:url];
	
	NSString *requestURL = [NSString stringWithFormat:@"posts/delete?url=%@", [[DXUtilities defaultUtilities] urlEncode:url]];
	[self startRequestToURL:requestURL withResponse:@selector(postDeleteResponse:)];
}

- (void)postDeleteResponse:(NSData*)xmlDocData
{
	BOOL didSucceed = NO;
	NSString *urlBeingProcessed = @"";
	
	if([mPostDeleteQueue count] > 0)
	{
		urlBeingProcessed = [[[mPostDeleteQueue objectAtIndex:0] retain] autorelease];
		[mPostDeleteQueue removeObjectAtIndex:0];
	}
		
	xmlXPathObjectPtr xPathObject = [[DXXMLHelper helperFromXMLDocData:xmlDocData] evaluateXPath:@"/result/@code"];
	
	if(xPathObject)
	{
		xmlNodeSetPtr nodes = xPathObject->nodesetval;
		
		if(nodes && nodes->nodeNr > 0 && nodes->nodeTab[0]->type == XML_ATTRIBUTE_NODE)
		{
			NSString *resultCode = nil;
			
			xmlChar *resultCodeStr = xmlNodeGetContent(nodes->nodeTab[0]);
			if(resultCodeStr)
			{
				resultCode = [NSString stringWithUTF8String:(const char*)resultCodeStr];
				xmlFree(resultCodeStr);
			}
			
			//NSLog(@"Result code: %@", resultCode);
			
			if([resultCode isEqual:@"done"])
			{
				didSucceed = YES;
			}
			else
			{
				NSLog(@"Post did not succeed. Result code is: %@", resultCode);
				didSucceed = NO;
			}
		}
		
		xmlXPathFreeObject(xPathObject);
	}
	else
		NSLog(@"DXDeliciousAPI - Error evaluating XPath in postDeleteResponse");
	
	[mDelegate deliciousAPIPostDeleteResponse:didSucceed withRemovedURL:urlBeingProcessed];
}

- (void)URLInfoRequest:(NSString*)url
{
	if(url == nil)
	{
		NSLog(@"urlInfoRequest got nil url.");
		return;
	}
	
	unsigned char digest[CC_MD5_DIGEST_LENGTH];
	const char* valueToHash = [url UTF8String];
	
	CC_MD5_CTX ctx;
	CC_MD5_Init(&ctx);
	CC_MD5_Update(&ctx, valueToHash, strlen(valueToHash));
	CC_MD5_Final(digest, &ctx);
	
	NSString *requestURL = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
							digest[0], digest[1], digest[2], digest[3], digest[4], digest[5], digest[6], digest[7],
							digest[8], digest[9], digest[10], digest[11], digest[12], digest[13], digest[14], digest[15]];
	
	//NSLog(@"Made requestURL for url info = '%@'", requestURL);
	[self startRequestToURL:requestURL withResponse:@selector(URLInfoResponse:) isJSONRequest:YES relativeToBase:mBaseJSONURL];
}

- (void)URLInfoResponse:(NSMutableData*)responseData
{
	//NSLog(@"urlInfoResponse called with responseData = %@", responseData);
	
	if(responseData == nil)
	{
		NSLog(@"urlInfoResponse got nil for responseData.");
		return;
	}
	
	// Make sure there is a null terminator as we are using the bytes here to buid a string.
	[responseData appendBytes:"\0" length:1];
	
	NSString *jsonString = [NSString stringWithUTF8String:[responseData bytes]];
	
	//NSLog(@"jsonString = BEGIN|%@|END", jsonString);
	
	NSDictionary *urlInfoDictionary = nil;
	NSScanner *scanner = [[NSScanner alloc] initWithString:jsonString];
	NSObject* jsonValue = nil;
	BOOL scanSucceeded = [scanner dxScanJSONValue:&jsonValue];
	[scanner release];
	
	if(scanSucceeded)
	{
		if([jsonValue isKindOfClass:[NSDictionary class]])
		{
			//NSLog(@"Got JSON dictionary");
			urlInfoDictionary = (NSDictionary*)jsonValue;
		}
		else if([jsonValue isKindOfClass:[NSArray class]])
		{
			//NSLog(@"Got JSON array");
			NSArray *jsonArray = (NSArray*)jsonValue;
			NSEnumerator *jsonArrayEnum = [jsonArray objectEnumerator];
			NSObject *arrayItem;
			while((arrayItem = [jsonArrayEnum nextObject]) != nil)
			{
				// Just use the first entry of the array. Unless they have different tag entries, in which case
				// they should probably be merged.
				
				if([arrayItem isKindOfClass:[NSDictionary class]])
				{
					urlInfoDictionary = (NSDictionary*)arrayItem;
					break;
				}
			}
		}
		else
		{
			NSLog(@"[DXDeliciousAPI URLInfoResponse:] Unexpected JSON response value. %@", [jsonValue class]);
		}
	}
	
	if(urlInfoDictionary == nil)
	{
		urlInfoDictionary = [NSDictionary dictionary];
		NSLog(@"[DXDeliciousAPI URLInfoResponse:] Didn't get JSON value. Using empty info dictionary.");
	}
	else
	{
		NSObject *top_tags = [urlInfoDictionary objectForKey:@"top_tags"];
		if(top_tags && ![top_tags isKindOfClass:[NSDictionary class]])
		{
			// If top_tags is empty, the json code will return it as an array which complicates
			// matters for the delegate, so simplify it here.
			NSMutableDictionary *d = [[urlInfoDictionary mutableCopy] autorelease];
			[d removeObjectForKey:@"top_tags"];
			urlInfoDictionary = d;
		}	
	}

	
	//NSLog(@"urlInfoDictionary: %@", urlInfoDictionary);
	
	[mDelegate deliciousAPIURLInfoResponse:urlInfoDictionary];
}

#ifdef DELICIOUSSAFARI_PLUGIN_TARGET
-(void)startProcessingPendingBookmarks
{
	if(!mIsProcessingQueueEntries)
		[self processNextQueueEntry]; // Start processing if it isn't already started.
}
#endif


#pragma mark  NSURLConnection Delegates
- (void)connection:(NSURLConnection *)connectionObj didReceiveResponse:(NSURLResponse *)response
{
	if(![connectionObj isKindOfClass:[DXURLConnection class]])
	{
		NSLog(@"DeliciousSafari internal error: expecting DXURLConnection for connection:didReceiveResponse:");
		return;
	}
	
	mAreCredentialsCleared = NO; // Got a response, so the credentials should be good.
	
	DXURLConnection *connection = (DXURLConnection*)connectionObj;
	
	//NSLog(@"connection didReceiveResponse: %@, %@", connection, response);
	const int kHTTP_OK = 200;
	
	int statusCode = kHTTP_OK;
	
	if([response isKindOfClass:[NSHTTPURLResponse class]])
	{
		NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
		statusCode = [httpResponse statusCode];
		//NSLog(@"Status Code: %d", statusCode);
		//NSLog(@"Received data length: %d", [mReceivedData length]);
	}
	
	if(statusCode == kDXDeliciousThrottleCode)
	{
		NSLog(@"Delicious returned the throttle response. That means Delicious data won't be updated for a few minutes.");
		
		// Stop processing this message as we will only get an HTML status page that is useless to us.
		[connection cancel];
		
		NSString *deliciousThrottleMessage = DXLocalizedString(@"Delicious throttled your connection. Please try agian later.",
															   @"Error message to display when Delicious returns a throttle response.");
		
		NSError *error = [NSError errorWithDomain:kDeliciousAPIErrorDomain
											 code:statusCode
										 userInfo:[NSDictionary dictionaryWithObject:deliciousThrottleMessage
																			  forKey:NSLocalizedDescriptionKey]];
		
		// Since cancel is called above, we need to let the delegate know that there is an API error.
		[mDelegate deliciousAPIConnectionFailedWithError:error];
	}
	
    // this method is called when the server has determined that it
    // has enough information to create the NSURLResponse
	
    // it can be called multiple times, for example in the case of a 
    // redirect, so each time we reset the data.
    [[connection receivedData] setLength:0];
}

- (void)connection:(NSURLConnection *)connectionObj didReceiveData:(NSData *)data
{
	if(![connectionObj isKindOfClass:[DXURLConnection class]])
	{
		NSLog(@"DeliciousSafari internal error. Expected DXURLConnection for connection:didReceiveData:");
		return;
	}
	
	DXURLConnection *connection = (DXURLConnection*)connectionObj;
	
	//NSLog(@"connection didReceiveData: %@, %@", connection, data);
	
    // append the new data to the mReceivedData
    [[connection receivedData] appendData:data];
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
    // release the connection, and the data object
    [connection release];
	
    // Log the problem.
    NSLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
	
	[mDelegate deliciousAPIConnectionFailedWithError:error];
}

#if 0
#warning Redirects can screw up Tiger. It appears that a redirect will cause Tiger's URL loading system to create a new NSURLConnection
#warning Unfortunately, that NSURLConnection isn't a DXURLConnection that has the received data associated with it, which means it won't
#warning work with this class correctly. Instead of figuring out how to deal with it here, I've just updated the URLs for the delicious.com 2.0 update.
-(NSURLRequest *)connection:(NSURLConnection *)connection
			willSendRequest:(NSURLRequest *)request
		   redirectResponse:(NSURLResponse *)redirectResponse
{
	NSLog(@"Redirect: request: %@, redirectResponse: %@", request, redirectResponse);
	// Do not handle redirects - at least not on Tiger as it doesn't use our DXURLConnection so our connection data isn't stored,
	// which results in empty data at the end.
	return nil;
}
#endif

- (void)connectionDidFinishLoading:(NSURLConnection *)connectionObj
{
	if(![connectionObj isKindOfClass:[DXURLConnection class]])
	{
		NSLog(@"DeliciousSafari internal error. Expected DXURLConnection for connectionDidFinishLoading:");
		return;
	}
	
	DXURLConnection *connection = (DXURLConnection*)connectionObj;
	
    // do something with the data
    //NSLog(@"Succeeded! Received %d bytes of data", [mReceivedData length]);
	
	// TODO: Look for 503 errors. That means you have been throttled and you should back off.
	
	SEL responseSelector = [connection responseSelector];
	
	if(responseSelector)
	{
		//char buf[20000];
		//[mReceivedData getBytes:buf length:sizeof(buf)];
		//NSLog(@"Data to String is: %s", buf);
		
		//[mReceivedData writeToFile:[@"~/Desktop/test.html" stringByExpandingTildeInPath] atomically:NO];
		[self performSelector:responseSelector withObject:[connection receivedData]];
	}
	
    // release the connection, and the data object
    [connection release];
}

-(void)connection:(NSURLConnection *)connection
        didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	//NSLog(@"connection: %@ didReceiveAuthChallenge", connection);
	
    if (mAreCredentialsCleared || [challenge previousFailureCount] == 0)
	{		
		mAreCredentialsCleared = NO;
		
		NSString *username = @"";
		NSString *password = @"";
        NSURLCredential *newCredential = nil;
		
		username = [mDelegate deliciousAPIGetUsername];
		if(username == nil)
			username = @"";
		
		password = [mDelegate deliciousAPIGetPassword];
		if(password == nil)
			password = @"";
		
        newCredential = [NSURLCredential credentialWithUser:username
												   password:password
												persistence:NSURLCredentialPersistencePermanent];
        [[challenge sender] useCredential:newCredential forAuthenticationChallenge:challenge];
    } else {
		[connection cancel];
		[connection release];
		
		[mDelegate deliciousAPIBadCredentials];
    }
}

- (NSDate*)nextAllowedRequestTime
{
	// Compare the next second on the wall clock with the second following the current allowed request time and return the later.
	// The result of this method must be used to schedule a perform selector after delay call immediately. That is, you should
	// not cache the results of this method. Use it immediately.
	const NSTimeInterval kDelayBetweenDeliciousCalls = 1.0; // Delicious requests 1 second between requests. See http://del.icio.us/help/api/
	NSDate *result = [mNextAllowedRequestTime autorelease];
	NSDate *secondAfterResult = [[[NSDate alloc] initWithTimeInterval:kDelayBetweenDeliciousCalls sinceDate:result] autorelease];
	NSDate *nextSecond = [NSDate dateWithTimeIntervalSinceNow:kDelayBetweenDeliciousCalls];
	
	mNextAllowedRequestTime = ([secondAfterResult laterDate:nextSecond] == secondAfterResult) ? secondAfterResult : nextSecond;
	
	[mNextAllowedRequestTime retain];
	
	return result;
}

@end


// Example timeString: 2007-07-30T18:15:41Z
NSDate*
DXDeliciousAPITimeStringToNSDate(NSString *timeString)
{
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
	[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
	[dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	
	NSDate *result = [dateFormatter dateFromString:timeString];
	
	[dateFormatter release];
	
	//NSLog(@"DXDeliciousAPITimeStringToNSDate is returning %@ for string '%@'", result, timeString);
	
	return result;
}

NSDictionary*
DXMakePostDictionary(NSString *href, NSString *description, NSArray *tagArray, NSDate *time, NSString *hash, NSString *extended, NSNumber *shouldShare, NSNumber *shouldReplace)
{	
	NSDictionary *result = nil;
	
	// Make sure none of the values are nil.
	if(href != nil && description != nil && tagArray != nil && time != nil && hash != nil && shouldShare != nil && shouldReplace != nil)
	{
		result = [NSDictionary dictionaryWithObjectsAndKeys:
				  href, kDXPostURLKey,
				  description, kDXPostDescriptionKey,
				  tagArray, kDXPostTagArrayKey,
				  time, kDXPostTimeKey,
				  hash, kDXPostHashKey,
				  extended, kDXPostExtendedKey,
				  shouldShare, kDXPostShouldShare,
				  shouldReplace, kDXPostShouldReplace,
				  nil];
	}
	
	return result;
}

#if defined(DELICIOUSSAFARI_PLUGIN_TARGET)
static BOOL DXRemoveDeliciousAPICredentials(void)
{
	SecKeychainItemRef keychainItem = NULL;
	const char* serverName = "api.del.icio.us";
	
	OSStatus err = SecKeychainFindInternetPassword(NULL,
												   strlen(serverName), serverName,
												   0, NULL,
												   0, NULL,
												   0, "",
												   0, // It's 443 but when this is set on Tiger it doesn't delete the entry correctly.
												   kSecProtocolTypeHTTPS,
												   kSecAuthenticationTypeDefault,
												   NULL, NULL, &keychainItem);
	
	if(err == noErr)
	{
		err = SecKeychainItemDelete(keychainItem);
		CFRelease(keychainItem);
		
		if(err != noErr)
			NSLog(@"Error deleting credential (error = %d)", err);
	}
	else if(err == errSecItemNotFound)
	{
		// Do nothing since the credentials aren't there.
		//NSLog(@"Credentials not found, so no need to delete.");
	}
	else
	{
		// An unexpected error occurred, so log it.
		NSLog(@"Could not find credentials for %s (error = %d)", serverName, err);
	}
	
	return err == noErr || err == errSecItemNotFound ? YES : NO;
}
#else
static BOOL DXRemoveDeliciousAPICredentials(void)
{
	CFMutableDictionaryRef query = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	CFDictionarySetValue(query, kSecClass, kSecClassInternetPassword);
	CFDictionarySetValue(query, kSecAttrProtocol, kSecAttrProtocolHTTPS);
	CFDictionarySetValue(query, kSecAttrPort, [NSNumber numberWithUnsignedShort:443]);
	CFDictionarySetValue(query, kSecAttrServer, @"api.del.icio.us");
	
	OSStatus err = SecItemDelete(query);
	
	if(err != noErr)
		NSLog(@"Error removing item from keychain. SecItemDelete returned %ld", err);
	
	CFRelease(query);
	
	return err == noErr;
}

#endif

static NSString* GetXMLAttributeValue(xmlNode *node, NSString* attributeName)
{
	NSString *result = nil;
	
	xmlChar* attributeValue = xmlGetProp(node, (const xmlChar*)[attributeName UTF8String]);
	if(attributeValue)
	{
		result = [NSString stringWithUTF8String:(const char*)attributeValue];
		xmlFree(attributeValue);
	}
	
	return result;
}
