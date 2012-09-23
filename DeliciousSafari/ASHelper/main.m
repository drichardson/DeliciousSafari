//
//  main.m
//  ASHelper
//
//  Created by Doug on 8/2/11.
//  Copyright 2011 Doug Richardson. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString*
documentURL(NSString* applicationName)
{
	NSString *url = nil;
	NSString *script = [NSString stringWithFormat:@"tell application \"%@\"\nget URL of document 1\nend tell", applicationName];
	NSAppleScript *as = [[NSAppleScript alloc] initWithSource:script];
    NSDictionary* errorInfo = nil;
	NSAppleEventDescriptor* scriptResult = [as executeAndReturnError:&errorInfo];
	[as release];
	
	if(scriptResult != nil)
	{
		url = [scriptResult stringValue];
	}
    else
    {
        NSLog(@"Error executing script for document URL: %@", errorInfo);
    }
	
	return url;
}

static NSString*
documentHTML(NSString* applicationName)
{
	NSString *html = nil;
	NSString *script = [NSString stringWithFormat:@"with timeout of (30 * 60) seconds\ntell application \"%@\"\nget source of document 1\nend tell\nend timeout",
						applicationName];
	
	NSAppleScript *as = [[NSAppleScript alloc] initWithSource:script];
    NSDictionary* errorInfo = nil;
	NSAppleEventDescriptor* scriptResult = [as executeAndReturnError:&errorInfo];
	[as release];
	
	if(scriptResult != nil)
	{
		html = [scriptResult stringValue];
	}
    else
    {
        NSLog(@"Error executing script for document title: %@", errorInfo);
    }
	
	return html;
}

static NSString*
documentSelectedText(NSString* applicationName)
{
	NSString *selectedText = nil;
	NSString *script = [NSString stringWithFormat:@"tell application \"%@\"\nset theSelection to do JavaScript \"window.getSelection().toString()\" in document 1\nreturn theSelection as string\nend tell", applicationName];
	
	NSAppleScript *as = [[NSAppleScript alloc] initWithSource:script];
    NSDictionary* errorInfo = nil;
	NSAppleEventDescriptor* scriptResult = [as executeAndReturnError:&errorInfo];
	[as release];
	
	if(scriptResult != nil)
    {
		selectedText = [scriptResult stringValue];
    }
    else
    {
        NSLog(@"Error executing script for document selected text: %@", errorInfo);
    }
	
	return selectedText;
}

int main (int argc, const char * argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    if ( argc == 3 )
    {
        NSString* applicationName = [NSString stringWithUTF8String:argv[1]];
        const char* command = argv[2];
        NSString* result = nil;
        
        if ( strcmp(command, "url") == 0 )
        {
            result = documentURL(applicationName);
        }
        else if ( strcmp(command, "html") == 0 )
        {
            result = documentHTML(applicationName);
        }
        else if ( strcmp(command, "selected-text") == 0 )
        {
            result = documentSelectedText(applicationName);
        }
        
        if ( result )
        {
            printf("%s", [result UTF8String]);
            return 0;
        }
    }
    
    [pool drain];
    return 1;
}
