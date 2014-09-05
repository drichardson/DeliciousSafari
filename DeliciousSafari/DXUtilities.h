//
//  DXUtilities.h
//  Safari Delicious Extension
//
//  Created by Douglas Richardson on 9/25/07.
//  Copyright 2007 Douglas Richardson. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DXUtilities : NSObject {

}

+(DXUtilities*)defaultUtilities;

#ifdef DELICIOUSSAFARI_PLUGIN_TARGET
- (NSString*)applicationName;
- (void) goToURL:(NSString*)url;
#endif

- (NSString*)decodeHTMLEntities:(NSString*)string;
- (NSString*)urlEncode:(NSString*)url;

//- (BOOL)isFunctionInCallstack:(const char*)function;

-(NSString*)applicationSupportPath;

@end

NSString *DXLocalizedString(NSString *key, NSString *comment);

const int kDXMaxMenuTitleLength;