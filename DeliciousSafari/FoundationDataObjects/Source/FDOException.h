//
//  FDOException.h
//  FoundationDataObjects
//
//  Created by Doug on 1/4/09.
//  Copyright 2009 Douglas Richardson. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kFDOInvalidArgumentException @"FDOInvalidArgument"
#define kFDOCommandClosedException @"FDOCommandClosedException"
#define kFDOTypeConversionFailedException @"FDOTypeConversionFailed"

@interface FDOException : NSException {

}

@end
