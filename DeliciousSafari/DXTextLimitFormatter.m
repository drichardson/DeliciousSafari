//
//  DXTextLimitFormatter.m
//  DeliciousSafari
//
//  Created by Doug on 9/30/09.
//  Copyright 2009 Douglas Richardson. All rights reserved.
//

#import "DXTextLimitFormatter.h"


@implementation DXTextLimitFormatter

@synthesize maximumLength;

- (id)init
{
	self = [super init];
	if(self)
	{
		maximumLength = NSUIntegerMax;
	}
	return self;
}

- (NSString *)stringForObjectValue:(id)object
{
	return (NSString *)object;
}

- (BOOL)getObjectValue:(id *)object forString:(NSString *)string errorDescription:(NSString **)error
{
	*object = string;
	return YES;
}

- (BOOL)isPartialStringValid:(NSString *)partialString newEditingString:(NSString **)newString errorDescription:(NSString **)error
{
	if ([partialString length] > maximumLength)
	{
		*newString = [partialString substringWithRange:NSMakeRange(0, maximumLength)];
		return NO;
	}
	
	return YES;
}

- (NSAttributedString *)attributedStringForObjectValue:(id)anObject withDefaultAttributes:(NSDictionary *)attributes
{
	return nil;
}

@end
