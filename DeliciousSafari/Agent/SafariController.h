//
//  SafariController.h
//  DeliciousSafari
//
//  Created by Doug on 8/29/09.
//  Copyright 2009 Douglas Richardson. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SafariController : NSObject
{
}

+(SafariController*)sharedController;

-(void)loadDeliciousSafariIntoApplication:(NSString*)applicationName;

@end
