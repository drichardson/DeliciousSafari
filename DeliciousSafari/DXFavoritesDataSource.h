//
//  DXFavoritesDataSource.h
//  Safari Delicious Extension
//
//  Created by Douglas Richardson on 9/8/07.
//  Copyright 2007 Douglas Richardson. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DXFavoritesDataSource : NSObject <NSTableViewDataSource> {
	NSMutableArray *records;
}

- (id)initWithTags:(NSArray*)tags;

-(NSArray*)favorites;

-(void)addTagFilterArray:(NSArray*)tagArray;
-(void)setTags:(NSArray*)tags;

-(void)removeFavoritesAtIndexes:(NSIndexSet*)indexes;

-(void)swapFavoriteAtIndex:(unsigned int)favorite1Index withFavoriteAtIndex:(unsigned int)favorite2Index;

@end
