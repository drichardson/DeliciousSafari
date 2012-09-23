//
//  DXPrincipleClass.h
//  DeliciousSafari
//
//  Created by Doug on 3/21/09.
//  Copyright 2009 Douglas Richardson. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// DXPrincipleClass does nothing. It is used as the principle class to make sure no
// unintended consequences occur from some other class's init method being called as a result
// of being chosen as the principle class during a bundle load.

@interface DXPrincipleClass : NSObject {

}

@end
