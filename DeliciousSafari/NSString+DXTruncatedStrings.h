//
//  NSString+DXTruncatedStrings.h
//  Safari Delicious Extension
//
//  Created by Doug on 5/15/08.
//  Copyright 2008 Douglas Richardson. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSString (NSString_DXTruncatedStrings)
-(NSString*)stringByTruncatedInMiddleIfLengthExceeds:(unsigned)maxCharacters;
@end
