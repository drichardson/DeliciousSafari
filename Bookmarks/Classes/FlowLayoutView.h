//
//  FlowLayoutView.h
//  Bookmarks
//
//  Created by Doug on 10/12/08.
//  Copyright 2008 Douglas Richardson. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface FlowLayoutView : UIView {
	CGFloat horizontalPadding;
	CGFloat verticalPadding;
}

@property (nonatomic) CGFloat horizontalPadding;
@property (nonatomic) CGFloat verticalPadding;

// -(void)removeAllSubviews;

@end
