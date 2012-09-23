//
//  BSJSONAdditions
//
//  Created by Blake Seely on 2/1/06.
//  Copyright 2006 Blake Seely - http://www.blakeseely.com  All rights reserved.
//  Permission to use this code:
//
//  Feel free to use this code in your software, either as-is or 
//  in a modified form. Either way, please include a credit in 
//  your software's "About" box or similar, mentioning at least 
//  my name (Blake Seely).
//
//  Permission to redistribute this code:
//
//  You can redistribute this code, as long as you keep these 
//  comments. You can also redistribute modified versions of the 
//  code, as long as you add comments to say that you've made 
//  modifications (keeping these original comments too).
//
//  If you do use or redistribute this code, an email would be 
//  appreciated, just to let me know that people are finding my 
//  code useful. You can reach me at blakeseely@mac.com
//
//
//  Version 1.2: Includes modifications by Bill Garrison: http://www.standardorbit.com , which included
//    Unit Tests adapted from Jonathan Wight's CocoaJSON code: http://www.toxicsoftware.com 
//    I have included those adapted unit tests in this package.

#import "NSScanner+DXBSJSONAdditions.h"

NSString *dxJsonObjectStartString = @"{";
NSString *dxJsonObjectEndString = @"}";
NSString *dxJsonArrayStartString = @"[";
NSString *dxJsonArrayEndString = @"]";
NSString *dxJsonKeyValueSeparatorString = @":";
NSString *dxJsonValueSeparatorString = @",";
NSString *dxJsonStringDelimiterString = @"\"";
NSString *dxJsonStringEscapedDoubleQuoteString = @"\\\"";
NSString *dxJsonStringEscapedSlashString = @"\\\\";
NSString *dxJsonTrueString = @"true";
NSString *dxJsonFalseString = @"false";
NSString *dxJsonNullString = @"null";

@implementation NSScanner (PrivateDXBSJSONAdditions)

- (BOOL)dxScanJSONObject:(NSDictionary **)dictionary
{
	//[self setCharactersToBeSkipped:nil];
	
	BOOL result = NO;
	
    /* START - April 21, 2006 - Updated to bypass irrelevant characters at the beginning of a JSON string */
    NSString *ignoredString;
    [self scanUpToString:dxJsonObjectStartString intoString:&ignoredString];
    /* END - April 21, 2006 */

	if (![self dxScanJSONObjectStartString]) {
		// TODO: Error condition. For now, return false result, do nothing with the dictionary handle
	} else {
		NSMutableDictionary *jsonKeyValues = [[[NSMutableDictionary alloc] init] autorelease];
		NSString *key = nil;
		id value;
		[self dxScanJSONWhiteSpace];
		while (([self dxScanJSONString:&key]) && ([self dxScanJSONKeyValueSeparator]) && ([self dxScanJSONValue:&value])) {
			[jsonKeyValues setObject:value forKey:key];
			[self dxScanJSONWhiteSpace];
			// check to see if the character at scan location is a value separator. If it is, do nothing.
			if ([[[self string] substringWithRange:NSMakeRange([self scanLocation], 1)] isEqualToString:dxJsonValueSeparatorString]) {
				[self dxScanJSONValueSeparator];
			}
		}
		if ([self dxScanJSONObjectEndString]) {
			// whether or not we found a key-val pair, we found open and close brackets - completing an object
			result = YES;
			*dictionary = jsonKeyValues;
		}
	}
	return result;
}

- (BOOL)dxScanJSONArray:(NSArray **)array
{
	BOOL result = NO;
	NSMutableArray *values = [[[NSMutableArray alloc] init] autorelease];
	[self dxScanJSONArrayStartString];
	id value = nil;
	
	while ([self dxScanJSONValue:&value]) {
		[values addObject:value];
		[self dxScanJSONWhiteSpace];
		if ([[[self string] substringWithRange:NSMakeRange([self scanLocation], 1)] isEqualToString:dxJsonValueSeparatorString]) {
			[self dxScanJSONValueSeparator];
		}
	}
	if ([self dxScanJSONArrayEndString]) {
		result = YES;
		*array = values;
	}
	
	return result;
}

- (BOOL)dxScanJSONString:(NSString **)string
{
	BOOL result = NO;
	if ([self dxScanJSONStringDelimiterString]) {
		NSMutableString *chars = [[[NSMutableString alloc] init] autorelease];
		NSString *characterFormat = @"%C";
		
		// process character by character until we finish the string or reach another double-quote
		while ((![self isAtEnd]) && ([[self string] characterAtIndex:[self scanLocation]] != '\"')) {
			unichar currentChar = [[self string] characterAtIndex:[self scanLocation]];
			unichar nextChar;
			if (currentChar != '\\') {
				[chars appendFormat:characterFormat, currentChar];
				[self setScanLocation:([self scanLocation] + 1)];
			} else {
				nextChar = [[self string] characterAtIndex:([self scanLocation] + 1)];
				switch (nextChar) {
				case '\"':
					[chars appendString:@"\""];
					[self setScanLocation:([self scanLocation] + 2)];
					break;
				case '\\':
					[chars appendString:@"\\"]; // debugger shows result as having two slashes, but final output is correct. Possible debugger error?
					[self setScanLocation:([self scanLocation] + 2)];
					break;
				/* TODO: json.org docs mention this seq, so does yahoo, but not recognized here by xcode, note from crockford: not a required escape
				case '\/':
					[chars appendString:@"\/"];
					[self setScanLocation:([self scanLocation] + 2)];
					break;
				*/
				case 'b':
					[chars appendString:@"\b"];
					[self setScanLocation:([self scanLocation] + 2)];
					break;
				case 'f':
					[chars appendString:@"\f"];
					[self setScanLocation:([self scanLocation] + 2)];
					break;
				case 'n':
					[chars appendString:@"\n"];
					[self setScanLocation:([self scanLocation] + 2)];
					break;
				case 'r':
					[chars appendString:@"\r"];
					[self setScanLocation:([self scanLocation] + 2)];
					break;
				case 't':
					[chars appendString:@"\t"];
					[self setScanLocation:([self scanLocation] + 2)];
					break;
				case 'u': // unicode sequence - get string of hex chars, convert to int, convert to unichar, append
					[self setScanLocation:([self scanLocation] + 2)]; // advance past '\u'
					NSString *digits = [[self string] substringWithRange:NSMakeRange([self scanLocation], 4)];
					/* START Updated code modified from code fix submitted by Bill Garrison - March 28, 2006 - http://www.standardorbit.net */
                    NSScanner *hexScanner = [NSScanner scannerWithString:digits];
                    NSString *verifiedHexDigits;
                    NSCharacterSet *hexDigitSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789ABCDEFabcdef"];
					if (NO == [hexScanner scanCharactersFromSet:hexDigitSet intoString:&verifiedHexDigits])
                        return NO;
                    if (4 != [verifiedHexDigits length])
                        return NO;
                        
                    // Read in the hex value
                    [hexScanner setScanLocation:0];
                    unsigned unicodeHexValue;
                    if (NO == [hexScanner scanHexInt:&unicodeHexValue]) {
                        return NO;
                    }
                    [chars appendFormat:characterFormat, unicodeHexValue];
                    /* END update - March 28, 2006 */
					[self setScanLocation:([self scanLocation] + 4)];
					break;
				default:
					[chars appendFormat:@"\\%C", nextChar];
					[self setScanLocation:([self scanLocation] + 2)];
					break;
				}
			}
		}
		
		if (![self isAtEnd]) {
			result = [self dxScanJSONStringDelimiterString];
			*string = chars;
		}
		
		return result;
	
		/* this code is more appropriate if you have a separate method to unescape the found string
			for example, between inputting json and outputting it, it may make more sense to have a category on NSString to perform
			escaping and unescaping. Keeping this code and looking into this for a future update.
		unsigned int searchLength = [[self string] length] - [self scanLocation];
		unsigned int quoteLocation = [[self string] rangeOfString:jsonStringDelimiterString options:0 range:NSMakeRange([self scanLocation], searchLength)].location;
		searchLength = [[self string] length] - quoteLocation;
		while (([[[self string] substringWithRange:NSMakeRange((quoteLocation - 1), 2)] isEqualToString:jsonStringEscapedDoubleQuoteString]) &&
			   (quoteLocation != NSNotFound) &&
			   (![[[self string] substringWithRange:NSMakeRange((quoteLocation -2), 2)] isEqualToString:jsonStringEscapedSlashString])){
			searchLength = [[self string] length] - (quoteLocation + 1);
			quoteLocation = [[self string] rangeOfString:jsonStringDelimiterString options:0 range:NSMakeRange((quoteLocation + 1), searchLength)].location;
		}
		
		*string = [[self string] substringWithRange:NSMakeRange([self scanLocation], (quoteLocation - [self scanLocation]))];
		// TODO: process escape sequences out of the string - replacing with their actual characters. a function that does just this belongs
		// in another class. So it may make more sense to change this whole implementation to just go character by character instead.
		[self setScanLocation:(quoteLocation + 1)];
		*/
		result = YES;
		
	}
	
	return result;
}

- (BOOL)dxScanJSONValue:(id *)value
{
	BOOL result = NO;
	
	[self dxScanJSONWhiteSpace];
	NSString *substring = [[self string] substringWithRange:NSMakeRange([self scanLocation], 1)];
	unsigned int trueLocation = [[self string] rangeOfString:dxJsonTrueString options:0 range:NSMakeRange([self scanLocation], ([[self string] length] - [self scanLocation]))].location;
	unsigned int falseLocation = [[self string] rangeOfString:dxJsonFalseString options:0 range:NSMakeRange([self scanLocation], ([[self string] length] - [self scanLocation]))].location;
	unsigned int nullLocation = [[self string] rangeOfString:dxJsonNullString options:0 range:NSMakeRange([self scanLocation], ([[self string] length] - [self scanLocation]))].location;
	
	if ([substring isEqualToString:dxJsonStringDelimiterString]) {
		result = [self dxScanJSONString:value];
	} else if ([substring isEqualToString:dxJsonObjectStartString]) {
		result = [self dxScanJSONObject:value];
	} else if ([substring isEqualToString:dxJsonArrayStartString]) {
		result = [self dxScanJSONArray:value];
	} else if ([self scanLocation] == trueLocation) {
		result = YES;
		*value = [NSNumber numberWithBool:YES];
		[self setScanLocation:([self scanLocation] + [dxJsonTrueString length])];
	} else if ([self scanLocation] == falseLocation) {
		result = YES;
		*value = [NSNumber numberWithBool:NO];
		[self setScanLocation:([self scanLocation] + [dxJsonFalseString length])];
	} else if ([self scanLocation] == nullLocation) {
		result = YES;
		*value = [NSNull null];
		[self setScanLocation:([self scanLocation] + [dxJsonNullString length])];
	} else if (([[NSCharacterSet decimalDigitCharacterSet] characterIsMember:[[self string] characterAtIndex:[self scanLocation]]]) ||
			   ([[self string] characterAtIndex:[self scanLocation]] == '-')){ // check to make sure it's a digit or -
		result =  [self dxScanJSONNumber:value];
	}
	return result;
}

- (BOOL)dxScanJSONNumber:(NSNumber **)number
{
	NSDecimal decimal;
	BOOL result = [self scanDecimal:&decimal];
	*number = [NSDecimalNumber decimalNumberWithDecimal:decimal];
	return result;
}

- (BOOL)dxScanJSONWhiteSpace
{
	//NSLog(@"Scanning white space - here are the next ten chars ---%@---", [[self string] substringWithRange:NSMakeRange([self scanLocation], 10)]);
	BOOL result = NO;
	NSCharacterSet *space = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	while ([space characterIsMember:[[self string] characterAtIndex:[self scanLocation]]]) {
		[self setScanLocation:([self scanLocation] + 1)];
		result = YES;
	}
	//NSLog(@"Done Scanning white space - here are the next ten chars ---%@---", [[self string] substringWithRange:NSMakeRange([self scanLocation], 10)]);
	return result;
}

- (BOOL)dxScanJSONKeyValueSeparator
{
	return [self scanString:dxJsonKeyValueSeparatorString intoString:nil];
}

- (BOOL)dxScanJSONValueSeparator
{
	return [self scanString:dxJsonValueSeparatorString intoString:nil];
}

- (BOOL)dxScanJSONObjectStartString
{
	return [self scanString:dxJsonObjectStartString intoString:nil];
}

- (BOOL)dxScanJSONObjectEndString
{
	return [self scanString:dxJsonObjectEndString intoString:nil];
}

- (BOOL)dxScanJSONArrayStartString
{
	return [self scanString:dxJsonArrayStartString intoString:nil];
}

- (BOOL)dxScanJSONArrayEndString
{
	return [self scanString:dxJsonArrayEndString intoString:nil];
}

- (BOOL)dxScanJSONStringDelimiterString;
{
	return [self scanString:dxJsonStringDelimiterString intoString:nil];
}

@end
