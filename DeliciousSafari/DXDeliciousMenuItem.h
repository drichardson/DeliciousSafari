//
//  DXDeliciousMenuItem.h
//  Safari Delicious Extension
//
//  Created by Douglas Richardson on 7/30/07.
//  Copyright 2007 Douglas Richardson. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DXDeliciousMenuItem : NSMenuItem {
	NSString *mURL;
}

-(id)initWithTitle:(NSString*)title withURL:(NSString*)url withTarget:(id)target withSelector:(SEL)selector;

-(NSString*)url;

@end
