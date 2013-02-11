//
//  DXFavoritesDataSource.m
//  Safari Delicious Extension
//
//  Created by Douglas Richardson on 9/8/07.
//  Copyright 2007 Douglas Richardson. All rights reserved.
//

#import "DXFavoritesDataSource.h"


@implementation DXFavoritesDataSource

-(id)initWithTags:(NSArray*)tags
{
	if([super init])
	{
		records = [tags mutableCopy];
	}
	return self;
}

-(void)dealloc
{
	[records release];
	[super dealloc];
}

- (id)tableView:(NSTableView *)aTableView
    objectValueForTableColumn:(NSTableColumn *)aTableColumn
			row:(NSInteger)rowIndex
{
	NSParameterAssert(rowIndex >= 0 && rowIndex < (int)[records count]);
	NSArray *tagArray = [records objectAtIndex:rowIndex];
	return [tagArray componentsJoinedByString:@"+"];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [records count];
}

-(NSArray*)favorites
{
	return records;
}

-(void)addTagFilterArray:(NSArray*)tagArray
{
	[records addObject:tagArray];
}

-(void)setTags:(NSArray*)tags
{
	[records removeAllObjects];
	
	if(tags)
		[records addObjectsFromArray:tags];
}

-(void)removeFavoritesAtIndexes:(NSIndexSet*)indexes
{
	[records removeObjectsAtIndexes:indexes];
}

-(void)swapFavoriteAtIndex:(unsigned int)favorite1Index
	   withFavoriteAtIndex:(unsigned int)favorite2Index
{
	NSParameterAssert(favorite1Index < [records count] && favorite2Index < [records count]);
	if(favorite1Index != favorite2Index)
		[records exchangeObjectAtIndex:favorite1Index withObjectAtIndex:favorite2Index];
}

@end
