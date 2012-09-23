//
//  NSString+DXTruncatedStrings.m
//  Safari Delicious Extension
//
//  Created by Doug on 5/15/08.
//  Copyright 2008 Douglas Richardson. All rights reserved.
//

#import "NSString+DXTruncatedStrings.h"


@implementation NSString (DXTruncationAddon)
-(NSString*)stringByTruncatedInMiddleIfLengthExceeds:(unsigned)maxCharacters
{
	unsigned len = [self length];
	NSString *result = self;
	
	if(len > maxCharacters)
	{
		// Needs to be truncated. This is the max characters plus 1 for the ellipses.
		unsigned charactersToRemove = len - maxCharacters + 1;
		unsigned characterToRemoveLeftOfMiddle = charactersToRemove / 2;
		unsigned characterToRemoveRightOfMiddle = charactersToRemove - characterToRemoveLeftOfMiddle;
		unsigned middle = len / 2;
		unsigned endOfFirstSubstring = middle - characterToRemoveLeftOfMiddle;
		unsigned beginningOfLastSubstring = middle + characterToRemoveRightOfMiddle;
		
		NSString *s1 = [self substringToIndex:endOfFirstSubstring];
		NSString *s2 = [self substringFromIndex:beginningOfLastSubstring];
		
		const unichar ellipseCode = 0x2026;
		NSString *ellipse = [NSString stringWithCharacters:&ellipseCode length:1];
		result = [NSString stringWithFormat:@"%@%@%@", s1, ellipse, s2];
	}
	
	return result;
}
@end
