//
//  DXDeliciousMenuItem.m
//  Safari Delicious Extension
//
//  Created by Douglas Richardson on 7/30/07.
//  Copyright 2007 Douglas Richardson. All rights reserved.
//

#import "DXDeliciousMenuItem.h"


@implementation DXDeliciousMenuItem

-(id)initWithTitle:(NSString*)title withURL:(NSString*)url withTarget:(id)target withSelector:(SEL)selector
{
	if([super initWithTitle:title action:selector keyEquivalent:@""])
	{
		[self setTarget:target];
		mURL = [url copy];
	}
	
	return self;
}

-(void)dealloc
{
	[mURL release];
	[super dealloc];
}

-(NSString*)url
{
	return mURL;
}

@end
