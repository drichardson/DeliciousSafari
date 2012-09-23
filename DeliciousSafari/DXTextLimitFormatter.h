//
//  DXTextLimitFormatter.h
//  DeliciousSafari
//
//  Created by Doug on 9/30/09.
//  Copyright 2009 Douglas Richardson. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DXTextLimitFormatter : NSFormatter
{
	NSUInteger maximumLength;
}

@property NSUInteger maximumLength;

@end
