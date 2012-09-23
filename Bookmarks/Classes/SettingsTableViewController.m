//
//  SettingsTableViewController.m
//  Bookmarks
//
//  Created by Doug on 10/14/08.
//  Copyright 2008 Douglas Richardson. All rights reserved.
//

#import "SettingsTableViewController.h"
#import "BookmarksDeliciousAPIManager.h"
#import "DeliciousSafariAppDelegate.h"
#import "CreditsViewController.h"
#import "UITableViewController+BrowserViewAdditions.h"

static NSString *kRegularCellIdentifier = @"RegularCell";
static NSString *kUsernameCellIdentifier = @"UsernameCell";
static NSString *kPasswordFieldCellIdentifier = @"PasswordCell";
static NSString *kLoginFieldCellIdentifier = @"LoginCell";
static NSString *kShakeCellIdentifier = @"ShakeCell";

#define LABEL_TAG 1
#define TEXTFIELD_TAG 2
#define SWITCH_TAG 3

#define ROW_HEIGHT 60

#define LEFT_COLUMN_OFFSET 10.0
#define LEFT_COLUMN_WIDTH 110.0

#define RIGHT_COLUMN_OFFSET 125.0
#define RIGHT_COLUMN_WIDTH 162.0

#define MAIN_FONT_SIZE 18.0
#define LABEL_HEIGHT 26.0
#define TEXTFIELD_HEIGHT 22.0

enum
{
	kCredentialsSection,
	kFetchSection,
	kOpenBookmarksInSection,
	kEnhancementsSection,
	kExtrasSection,
	kCreditsSection,
	kSectionCount
};

enum
{
	kCredentialsUsernameRow = 0,
	kCredentialsPasswordRow,
	kCredentialsLoginLogoutRow,
	kCredentialsSectionCount
};

enum
{
	kOpenInBuiltInWebView,
	kOpenInSafari,
	kOpenInCount
};

enum
{
	kFetchOnLaunch,
	kFetchManually,
	kFetchSectionCount
};

enum
{
	kShakeToRefresh,
	kEnhancementsSectionCount
};

enum
{
	kAddBookmarkletRow,
	kRegisterForDeliciousAccountRow,
	kExtrasSectionCount
};

enum
{
	kCreditsRow,
	kCreditsSectionCount
};

@interface SettingsTableViewController (private)
- (UITableViewCell *)tableviewCellWithReuseIdentifier:(NSString *)identifier;
- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath;

- (void)updateLoginLogoutCellWithCell:(UITableViewCell*)cell;
- (void)updateLoginLogoutCell;
@end


@implementation SettingsTableViewController

- (id)initWithStyle:(UITableViewStyle)style {

    if (self = [super initWithStyle:style]) {
		self.title = NSLocalizedString(@"Settings", @"Settings table view title.");
		
		_usernameTextField = [[UITextField alloc] initWithFrame:CGRectZero];
		_usernameTextField.tag = TEXTFIELD_TAG;
		_usernameTextField.font = [UIFont systemFontOfSize:MAIN_FONT_SIZE];
		_usernameTextField.textAlignment = UITextAlignmentLeft;
		_usernameTextField.secureTextEntry = NO;
		_usernameTextField.delegate = self;
		_usernameTextField.returnKeyType = UIReturnKeyNext;
		_usernameTextField.autocorrectionType = UITextAutocorrectionTypeNo;
		_usernameTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
		
		_passwordTextField = [[UITextField alloc] initWithFrame:CGRectZero];
		_passwordTextField.tag = TEXTFIELD_TAG;
		_passwordTextField.font = [UIFont systemFontOfSize:MAIN_FONT_SIZE];
		_passwordTextField.textAlignment = UITextAlignmentLeft;
		_passwordTextField.secureTextEntry = YES;
		_passwordTextField.delegate = self;
		_passwordTextField.returnKeyType = UIReturnKeyDone;
		
		_shakeSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
		_shakeSwitch.tag = SWITCH_TAG;
		_shakeSwitch.on = NO;
		[_shakeSwitch addTarget:self action:@selector(shakeChanged) forControlEvents:UIControlEventAllTouchEvents];
				
		[[BookmarksDeliciousAPIManager sharedManager] addObserver:self forKeyPath:@"isUserLoggedIn" options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (void)shakeChanged
{
	[[NSUserDefaults standardUserDefaults] setBool:_shakeSwitch.on forKey:@"shakeToRefresh"];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return kSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	switch(section)
	{
		case kCredentialsSection:
			return kCredentialsSectionCount;
		case kFetchSection:
			return kFetchSectionCount;
		case kOpenInCount:
			return kOpenInCount;
		case kEnhancementsSection:
			return kEnhancementsSectionCount;
		case kExtrasSection:
			return kExtrasSectionCount;
		case kCreditsSection:
			return kCreditsSectionCount;
	}
	
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
	NSString *cellIdentifier = nil;
	
	if (indexPath.section == kCredentialsSection)
	{
		switch(indexPath.row)
		{
			case kCredentialsUsernameRow:
				cellIdentifier = kUsernameCellIdentifier;
				break;
				
			case kCredentialsPasswordRow:
				cellIdentifier = kPasswordFieldCellIdentifier;
				break;
				
			case kCredentialsLoginLogoutRow:
				cellIdentifier = kLoginFieldCellIdentifier;
				break;
		}
	}
	else if (indexPath.section == kEnhancementsSection)
	{
		switch(indexPath.row)
		{
			case kShakeToRefresh:
				cellIdentifier = kShakeCellIdentifier;
				break;
		}
	}
	
	if(cellIdentifier == nil)
		cellIdentifier = kRegularCellIdentifier;
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	if (cell == nil) {
		cell = [self tableviewCellWithReuseIdentifier:cellIdentifier];
	}
	
	[self configureCell:cell forIndexPath:indexPath];
	return cell;
}

- (UITableViewCell *)tableviewCellWithReuseIdentifier:(NSString *)identifier
{
    UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
	
	if ([identifier isEqualToString:kUsernameCellIdentifier] || [identifier isEqualToString:kPasswordFieldCellIdentifier])
	{
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		
		CGRect rect = CGRectMake(LEFT_COLUMN_OFFSET, (cell.bounds.size.height - LABEL_HEIGHT) / 2.0, LEFT_COLUMN_WIDTH, LABEL_HEIGHT);
		UILabel *label = [[UILabel alloc] initWithFrame:rect];
		label.tag = LABEL_TAG;
		label.font = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE];
		label.adjustsFontSizeToFitWidth = YES;
        label.backgroundColor = [UIColor clearColor];
		[cell.contentView addSubview:label];
		[label release];
		
		rect = CGRectMake(RIGHT_COLUMN_OFFSET, (cell.bounds.size.height - TEXTFIELD_HEIGHT) / 2.0, RIGHT_COLUMN_WIDTH, TEXTFIELD_HEIGHT);
		UITextField *textField = [identifier isEqualToString:kUsernameCellIdentifier] ? _usernameTextField : _passwordTextField;
		[textField setFrame:rect];
		[cell.contentView addSubview:textField];
	}
	else if ([identifier isEqualToString:kShakeCellIdentifier])
	{
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		
		NSInteger shakeSwitchOrigin = (cell.bounds.size.width - _shakeSwitch.frame.size.width - 35);
		
		CGRect rect = CGRectMake(LEFT_COLUMN_OFFSET, (cell.bounds.size.height - LABEL_HEIGHT) / 2.0,
						  shakeSwitchOrigin - 10, LABEL_HEIGHT);
		
		UILabel *label = [[UILabel alloc] initWithFrame:rect];
		label.tag = LABEL_TAG;
		label.font = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE];
		label.adjustsFontSizeToFitWidth = YES;
		[cell.contentView addSubview:label];
        label.backgroundColor = [UIColor clearColor];
		[label release];
		
		rect = _shakeSwitch.frame;
		rect.origin.x = shakeSwitchOrigin;
		rect.origin.y = (cell.bounds.size.height - 28.0) / 2.0;
		
		[_shakeSwitch setFrame:rect];
		[cell.contentView addSubview:_shakeSwitch];		
	}
	
	return cell;
}

- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath {
	
	switch(indexPath.section)
	{			
		case kCredentialsSection:
		{
			switch(indexPath.row)
			{
				case kCredentialsUsernameRow:
				{				
					UILabel *labelView = (UILabel*)[cell viewWithTag:LABEL_TAG];
					labelView.text = NSLocalizedString(@"Username", nil);
					
					UITextField *textField = (UITextField*)[cell viewWithTag:TEXTFIELD_TAG];
					textField.placeholder = NSLocalizedString(@"Username", nil);
					textField.text = [[DXDeliciousDatabase defaultDatabase] username];
					textField.clearButtonMode = UITextFieldViewModeWhileEditing;
					
					break;
				}
					
				case kCredentialsPasswordRow:
				{					
					UILabel *labelView = (UILabel*)[cell viewWithTag:LABEL_TAG];
					labelView.text = NSLocalizedString(@"Password", nil);
					
					UITextField *textField = (UITextField*)[cell viewWithTag:TEXTFIELD_TAG];
					textField.placeholder = NSLocalizedString(@"Password", nil);
					textField.text = [[NSUserDefaults standardUserDefaults] stringForKey:kUserDefault_Password];
					textField.clearButtonMode = UITextFieldViewModeWhileEditing;
					break;
				}
					
				case kCredentialsLoginLogoutRow:
				{
					cell.textLabel.textAlignment = UITextAlignmentCenter;
					[self updateLoginLogoutCellWithCell:cell];					
					break;
				}					
			}
			
			break;
		}
			
		case kFetchSection:
		{
			switch(indexPath.row)
			{
				case kFetchOnLaunch:
					cell.textLabel.text = NSLocalizedString(@"At Launch", @"Fetch at launch cell text");
					cell.accessoryType = [[DXDeliciousDatabase defaultDatabase] shouldFetchBookmarksManually] ? UITableViewCellAccessoryNone : UITableViewCellAccessoryCheckmark;
					break;
					
				case kFetchManually:
					cell.textLabel.text = NSLocalizedString(@"Manually", @"Fetch manually cell text");
					cell.accessoryType = [[DXDeliciousDatabase defaultDatabase] shouldFetchBookmarksManually] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
					break;					
			}
			
			break;
		}
			
		case kOpenBookmarksInSection:
		{
			switch(indexPath.row)
			{
				case kOpenInBuiltInWebView:
					cell.textLabel.text = NSLocalizedString(@"This Application", "Open bookmarks in this application");
					cell.accessoryType = [[NSUserDefaults standardUserDefaults] boolForKey:@"OpenInSafari"] ? UITableViewCellAccessoryNone : UITableViewCellAccessoryCheckmark;
					break;
					
				case kOpenInSafari:
					cell.textLabel.text = NSLocalizedString(@"Safari", @"Open bookmarks in Safari");
					cell.accessoryType = [[NSUserDefaults standardUserDefaults] boolForKey:@"OpenInSafari"] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
					break;
			}
		}
			
		case kEnhancementsSection:
		{
			switch(indexPath.row)
			{
				case kShakeToRefresh:
				{
					UILabel *labelView = (UILabel*)[cell viewWithTag:LABEL_TAG];
					labelView.text = NSLocalizedString(@"Shake to Refresh", nil);
					_shakeSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"shakeToRefresh"];
					break;
				}
			}
			
			break;
		}
			
		case kExtrasSection:
		{			
			switch(indexPath.row)
			{
				case kAddBookmarkletRow:
				{
					cell.textLabel.text = NSLocalizedString(@"Add Bookmarklet to Safari", @"Add bookmarklet to Safari text in the top level view.");
					cell.accessoryType = UITableViewCellAccessoryNone;
					break;
				}					
				case kRegisterForDeliciousAccountRow:
				{
					cell.textLabel.text = NSLocalizedString(@"Create Delicious Account", @"Create account text in the top level view.");
					cell.accessoryType = UITableViewCellAccessoryNone;
					break;
				}
			}
			
			break;
		}
			
		case kCreditsSection:
		{			
			switch(indexPath.row)
			{
				case kCreditsRow:
					cell.textLabel.text = NSLocalizedString(@"About Bookmarks", @"About Bookmarks including credits.");
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					break;
			}
			
			break;
		}			
			
		default:
			break;
	}
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	switch(indexPath.section)
	{			
		case kCredentialsSection:
		{
			switch(indexPath.row)
			{
				case kCredentialsUsernameRow:
					[_usernameTextField becomeFirstResponder];
					break;
					
				case kCredentialsPasswordRow:
					[_passwordTextField becomeFirstResponder];
					break;
					
				case kCredentialsLoginLogoutRow:
				{
					if([[BookmarksDeliciousAPIManager sharedManager] isUserLoggedIn])
					{
						// logout
						[[BookmarksDeliciousAPIManager sharedManager] logout];
						_usernameTextField.text = nil;
						_passwordTextField.text = nil;
					}
					else
					{
						[self refreshPressed:self]; // login						
					}
					
					break;
				}
			}
			
			break;
		}
			
		case kFetchSection:
		{
			UITableViewCell *fetchAtLaunchCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:kFetchOnLaunch inSection:kFetchSection]];
			UITableViewCell *fetchManuallyCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:kFetchManually inSection:kFetchSection]];
			
			switch(indexPath.row)
			{
				case kFetchOnLaunch:
					fetchAtLaunchCell.accessoryType = UITableViewCellAccessoryCheckmark;
					fetchManuallyCell.accessoryType = UITableViewCellAccessoryNone;
					[[DXDeliciousDatabase defaultDatabase] setShouldFetchBookmarksManually:NO];
					break;
					
				case kFetchManually:
					fetchAtLaunchCell.accessoryType = UITableViewCellAccessoryNone;
					fetchManuallyCell.accessoryType = UITableViewCellAccessoryCheckmark;
					[[DXDeliciousDatabase defaultDatabase] setShouldFetchBookmarksManually:YES];
					break;
			}
			
			break;
		}
			
		case kOpenBookmarksInSection:
		{
			UITableViewCell *openInWebViewCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:kOpenInBuiltInWebView inSection:kOpenBookmarksInSection]];
			UITableViewCell *openInSafariCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:kOpenInSafari inSection:kOpenBookmarksInSection]];
			
			switch(indexPath.row)
			{
				case kOpenInBuiltInWebView:
					openInWebViewCell.accessoryType = UITableViewCellAccessoryCheckmark;
					openInSafariCell.accessoryType = UITableViewCellAccessoryNone;
					[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"OpenInSafari"];
					break;
					
				case kOpenInSafari:
					openInWebViewCell.accessoryType = UITableViewCellAccessoryNone;
					openInSafariCell.accessoryType = UITableViewCellAccessoryCheckmark;
					[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"OpenInSafari"];
					break;
			}
			
			break;
		}

		case kExtrasSection:
		{
			switch(indexPath.row)
			{
				case kRegisterForDeliciousAccountRow:
				{
					NSString *createAccountURL = @"https://secure.delicious.com/register";
					[self openURLInBrowser:createAccountURL];
					break;
				}
					
				case kAddBookmarkletRow:
				{
					[(DeliciousSafariAppDelegate *)[[UIApplication sharedApplication] delegate] createBookmarklet];
					break;
				}
			}
			
			break;
		}
			
		case kCreditsSection:
		{
			switch(indexPath.row)
			{					
				case kCreditsRow:
				{
					CreditsViewController *creditsController = [[[CreditsViewController alloc] initWithNibName:@"CreditsView" bundle:nil] autorelease];
					creditsController.navigationItem.title = NSLocalizedString(@"About", @"Title for navigation section.");
					[self.navigationController pushViewController:creditsController animated:YES];
					
					break;
				}
			}
			
			break;
		}			
	}
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	NSString *result = nil;
	
	switch(section)
	{			
		case kCredentialsSection:
			result = NSLocalizedString(@"Delicious Account", @"Delicious Account section header");
			break;
			
		case kFetchSection:
			result = NSLocalizedString(@"Fetch Bookmarks", @"Fetch bookmarks section header");
			break;
			
		case kOpenBookmarksInSection:
			result = NSLocalizedString(@"Open Bookmarks In", @"Open Bookmarks In section header");
			break;
			
		case kEnhancementsSection:
			result = NSLocalizedString(@"Extras", @"Extras section header");
			break;
	}
	
	return result;
}

- (void)dealloc {
	[[BookmarksDeliciousAPIManager sharedManager] removeObserver:self forKeyPath:@"isUserLoggedIn"];
	
	[_usernameTextField release];
	[_passwordTextField release];
	[_shakeSwitch release];

    [super dealloc];
}

-(void)refreshPressed:(id)sender
{
	[_usernameTextField resignFirstResponder];
	[_passwordTextField resignFirstResponder];
	
	// Call refreshPressed after resigning the text field to make sure the latest values in the text fields are written to DXDeliciousDatabase.
	
	[super refreshPressed:self];
}

- (void)updateLoginLogoutCell
{
	UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:kCredentialsLoginLogoutRow inSection:kCredentialsSection]];
	[self updateLoginLogoutCellWithCell:cell];
}

- (void)updateLoginLogoutCellWithCell:(UITableViewCell*)cell
{
	if([[BookmarksDeliciousAPIManager sharedManager] isUserLoggedIn])
		cell.textLabel.text = NSLocalizedString(@"Logout",  nil);
	else
		cell.textLabel.text = NSLocalizedString(@"Login",  nil);
}

#pragma mark UITextField Delegate Methods
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if(textField == _usernameTextField)
	{
		[_passwordTextField becomeFirstResponder];
		return NO;
	}
	else if(textField == _passwordTextField)
	{
		[_passwordTextField resignFirstResponder];
		return NO;
	}
	
	return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	if(textField == _usernameTextField)
	{
		DXDeliciousDatabase *db = [DXDeliciousDatabase defaultDatabase];
		
		if(![_usernameTextField.text isEqual:[db username]])
		{
			[[BookmarksDeliciousAPIManager sharedManager] logout];
			[db setUsername:_usernameTextField.text];
		}
	}
	else if(textField == _passwordTextField)
	{
		[[NSUserDefaults standardUserDefaults] setObject:_passwordTextField.text forKey:kUserDefault_Password];
		[[BookmarksDeliciousAPIManager sharedManager] clearSavedCredentials];
	}
}

#pragma mark KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	
	if(object == [BookmarksDeliciousAPIManager sharedManager])
	{
		if([keyPath isEqualToString:@"isUserLoggedIn"])
		{
			[self updateLoginLogoutCell];
		}
	}
}

@end
