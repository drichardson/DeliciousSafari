#import "MethodSwizzle.h"

BOOL DXMethodSwizzle(Class aClass, SEL orig_sel, SEL alt_sel)
{
	BOOL result = NO;
    Method orig_method = nil, alt_method = nil;
	
    // First, look for the methods
    orig_method = class_getInstanceMethod(aClass, orig_sel);
    alt_method = class_getInstanceMethod(aClass, alt_sel);
	
    // If both are found, swizzle them
    if ((orig_method != nil) && (alt_method != nil))
	{
#if 0
        char *temp1;
        IMP temp2;
		
        temp1 = orig_method->method_types;
        orig_method->method_types = alt_method->method_types;
        alt_method->method_types = temp1;
		
        temp2 = orig_method->method_imp;
        orig_method->method_imp = alt_method->method_imp;
        alt_method->method_imp = temp2;
#else
		method_exchangeImplementations(orig_method, alt_method);
#endif
		//NSLog(@"Swizzled: %s for %s", sel_getName(orig_sel), sel_getName(alt_sel));
		result = YES;
	}
	//else
	//	NSLog(@"Could not swizzle: %s for %s", sel_getName(orig_sel), sel_getName(alt_sel));
	
	return result;
}
