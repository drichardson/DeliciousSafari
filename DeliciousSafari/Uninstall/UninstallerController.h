//
//  UninstallerController.h
//  Uninstall
//
//  Created by Douglas Richardson on 10/5/07.
//  Copyright 2007 Douglas Richardson. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface UninstallerController : NSObject <NSWindowDelegate> {
	IBOutlet NSWindow *window;
	IBOutlet NSButton *uninstallButton;
	IBOutlet NSButton *cancelButton;
	IBOutlet NSTextField *uninstallSuccessfulTextField;
	IBOutlet NSImageView *uninstallSuccessfulImageView;
}

- (IBAction)uninstall:(id)sender;
- (IBAction)cancel:(id)sender;

@end
