/*
 *  main.c
 *  DeliciousSafari
 *
 *  Created by Doug on 8/30/09.
 *  Copyright 2009 Douglas Richardson. All rights reserved.
 *
 */

#include <Carbon/Carbon.h>
#include <CoreFoundation/CoreFoundation.h>


#pragma mark Declarations of external entry points

#pragma GCC visibility push(default)

#ifdef __cplusplus
extern "C" {
#endif
	
	OSErr MyEventHandler(const AppleEvent *ev, AppleEvent *reply, SRefCon refcon);
	
#ifdef __cplusplus
}
#endif

#pragma GCC visibility pop



#pragma mark Event handler
#include <syslog.h>
OSErr MyEventHandler(const AppleEvent *ev, AppleEvent *reply, SRefCon refcon)
{	
	// Set the reply so the agent knows we did something.
	//syslog(LOG_ERR, "MyEventHandler called - DOUG DOUG DOUG");
	
	CFMutableStringRef bundlePath = NULL;
	CFURLRef bundleURL = NULL;
	CFBundleRef bundle = NULL;
	
	
	bundlePath = CFStringCreateMutable(NULL, 0);
	
#if 0
	// Use this for a user specific bundle
	const char* homeDir = getenv("HOME");
	if(homeDir == NULL)
	{
		syslog(LOG_ERR, "Can't load DeliciousSafari because HOME enviornment variable isn't set.");
		// TODO: Set apple script error here.
		goto bail;
	}
	
	CFStringAppendCString(bundlePath, homeDir, kCFStringEncodingUTF8);
#endif
	
	CFStringAppendCString(bundlePath, "/Library/InputManagers/DeliciousSafari/DeliciousSafari.bundle", kCFStringEncodingUTF8);
	
	bundleURL = CFURLCreateWithFileSystemPath(NULL, bundlePath, kCFURLPOSIXPathStyle, false);
	if(bundleURL == NULL)
	{
		syslog(LOG_ERR, "Can't load DeliciousSafari because a URL couldn't be created.");
		goto bail;
	}
	
	bundle = CFBundleCreate(NULL, bundleURL);
	if(bundle == NULL)
	{
		syslog(LOG_ERR, "Can't load DeliciousSafari because the bundle could not be loaded.");
		goto bail;
	}
	
	if(!CFBundleLoadExecutable(bundle))
	{
		syslog(LOG_ERR, "Can't load DeliciousSafari because the bundle failed to load.");
		goto bail;
	}
	
	typedef void (*DXLoadPluginPrototype)(void);
	DXLoadPluginPrototype DXLoadPlugin = (DXLoadPluginPrototype)CFBundleGetFunctionPointerForName(bundle, CFSTR("DXLoadPlugin"));
	if(!DXLoadPlugin)
	{
		syslog(LOG_ERR, "Couldn't find DXLoadPlugin function in bundle.");
		goto bail;
	}
	
	DXLoadPlugin();
	
	// TODO: Set the apple script reply for success here.
	
bail:
	if(bundlePath)
		CFRelease(bundlePath);
	
	if(bundleURL)
		CFRelease(bundleURL);

	// Do NOT release the bundle or DeliciousSafari will be unloaded.
	//if(bundle)
	//	CFRelease(bundle);
		
	return noErr;
}
