//
//  DXSafariBookmarkDataSource.h
//  Safari Delicious Extension
//
//  Created by Doug on 1/2/08.
//  Copyright 2008 Douglas Richardson. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DXSafariBookmarkDataSource : NSObject {
	NSMutableDictionary *safariBookmarksDict;
}

-(NSString*)titleForItem:(id)item;
-(BOOL)isListItem:(id)item;
-(BOOL)isLeafItem:(id)item;

-(int)checkStateOfItem:(id)item;
-(void)setCheckState:(int)state forItem:(id)item;

// Returns an array of dictionaries, each dictionary containing the information to import
// 1 bookmark. The dictionary has the following keys:
extern NSString *const kImportTagsSet;
extern NSString *const kImportURLString;
extern NSString *const kImportTitleString;
-(NSArray*)itemsToImport;

@end
