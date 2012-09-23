//
//  DXButtonIconCell.h
//  Safari Delicious Extension
//
//  Created by Doug on 1/6/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DXButtonIconCell : NSButtonCell {
	NSImage *image;
}

-(void)setIconImage:(NSImage*)image;

@end
