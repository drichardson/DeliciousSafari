//
//  DXSearchResultCell.h
//  ChildWindow
//
//  Created by Doug on 9/16/09.
//  Copyright 2009 Douglas Richardson. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DXSearchResultCell : NSActionCell {
@private
    NSImage *_favicon;
	NSString *_title;
    NSString *_urlString;
	NSString *_notes;	
}

+ (NSUInteger)defaultCellHeight;

- (NSImage*)favicon;
- (void)setFavicon:(NSImage *)newFavicon;

- (NSString*)title;
- (void)setTitle:(NSString*)newTitle;

- (NSString*)urlString;
- (void)setURLString:(NSString *)newURLString;

- (NSString*)notes;
- (void)setNotes:(NSString *)newNotes;

@end
