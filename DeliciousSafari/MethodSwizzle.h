#import <objc/objc-class.h>

// DXMethodSwizzle swaps the selectors in aClass. After the swizzle,
// calling the orig_sel selector causes the alt_sel selector to be
// invoked and vice versa.
// Returns YES if the swizzle was successful and NO if it was not.
BOOL DXMethodSwizzle(Class aClass, SEL orig_sel, SEL alt_sel);
