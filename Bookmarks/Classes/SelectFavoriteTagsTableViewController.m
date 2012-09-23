//
//  SelectFavoriteTagsTableViewController.m
//  Bookmarks
//
//  Created by Doug on 10/9/08.
//  Copyright 2008 Douglas Richardson. All rights reserved.
//

#import "SelectFavoriteTagsTableViewController.h"


@implementation SelectFavoriteTagsTableViewController

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

- (void)dealloc {
    [super dealloc];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(![self isTagListEmpty])
	{
		NSArray *tagArrayForSection = [tagsBySection objectAtIndex:indexPath.section];
		NSString *tag = [tagArrayForSection objectAtIndex:indexPath.row];
		
		[_delegate selectFavoriteTagsTableViewControllerTagSelected:tag];
	}
	
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void)setDelegate:(id <SelectFavoriteTagsTableViewControllerDelegate>)delegate
{
	_delegate = delegate;
}

@end
