//
//  EditNotesViewController.h
//  Bookmarks
//
//  Created by Brian Ganninger on 9/27/09.
//  Copyright 2009 Infinite Nexus Software. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface EditNotesViewController : UIViewController {
	UITextView *notesText;
	UIView *notesContainer;
}

- (void)setEditEnabled:(BOOL)shouldEdit;

@end
