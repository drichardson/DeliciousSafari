//
//  DXSearchResultCell.m
//  ChildWindow
//
//  Created by Doug on 9/16/09.
//  Copyright 2009 Douglas Richardson. All rights reserved.
//

#import "DXSearchResultCell.h"

@implementation DXSearchResultCell

// The cell is made of two areas: the image box and the info box.
// The image box contains the favicon image and nothing else; it is a fixed width.
// The info box contains the title, URL, and notes; it can be resized.

//#define SHOW_NOTES 1

#define IMAGEBOX_PADDING_TOP	6.0
#define IMAGEBOX_PADDING_LEFT	4.0
#define IMAGEBOX_PADDING_RIGHT	4.0
#define IMAGEBOX_IMAGE_SIZE		16.0
#define IMAGEBOX_WIDTH			(IMAGEBOX_PADDING_LEFT + IMAGEBOX_IMAGE_SIZE + IMAGEBOX_PADDING_RIGHT)

#define INFOBOX_ORIGIN_LEFT		IMAGEBOX_WIDTH 
#define INFOBOX_PADDING			2.0
#define INFOBOX_TITLE_HEIGHT	16.0
#define INFOBOX_URL_HEIGHT		16.0

#ifdef SHOW_NOTES
#define INFOBOX_NOTES_HEIGHT	30.0
#else
#define INFOBOX_NOTES_HEIGHT	0.0
#endif

#define INFOBOX_HEIGHT			(INFOBOX_PADDING + INFOBOX_TITLE_HEIGHT + INFOBOX_PADDING + INFOBOX_URL_HEIGHT + INFOBOX_PADDING + INFOBOX_NOTES_HEIGHT + INFOBOX_PADDING)

+ (NSUInteger)defaultCellHeight
{
	return	INFOBOX_HEIGHT;
}

- (id)init {
    self = [super init];
    if (self != nil) {
        [self setLineBreakMode:NSLineBreakByTruncatingTail];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    return self;
}

// NSTableView likes to copy a cell before tracking -- therefore we need to properly implement copyWithZone.
- (id)copyWithZone:(NSZone *)zone {
    DXSearchResultCell *result = [super copyWithZone:zone];
    if (result != nil) {
        // We must clear out the image beforehand; otherwise, it would contain the previous image (which wouldn't be retained), and doing the setImage: would be a nop since it is the same image. This would eventually lead to a crash after you click on the cell in a tableview, since it copies the cell at that time, and later releases it.
        result->_favicon = nil;
		result->_title = nil;
        result->_urlString = nil;
		result->_notes = nil;
        [result setFavicon:[self favicon]];
		[result setTitle:[self title]];
        [result setURLString:[self urlString]];
		[result setNotes:[self notes]];
    }
    return result;
}

- (void)dealloc {
    [_favicon release];
	[_title release];
    [_urlString release];
	[_notes release];
    [super dealloc];
}

- (NSImage *)favicon {
    return _favicon;
}

- (void)setFavicon:(NSImage *)image {
    if (image != _favicon) {
        [_favicon release];
        _favicon = [image retain];
    }
}

- (NSString *)urlString {
    return _urlString;
}

- (void)setTitle:(NSString *)newTitle {
    if (_title != newTitle) {
        [_title release];
        _title = [newTitle retain];
    }
}

- (NSString *)title {
    return _title;
}

- (void)setURLString:(NSString *)newURLString {
    if (_urlString != newURLString) {
        [_urlString release];
        _urlString = [newURLString retain];
    }
}

- (NSString *)notes {
    return _notes;
}

- (void)setNotes:(NSString *)newNotes {
    if (_notes != newNotes) {
        [_notes release];
        _notes = [newNotes retain];
    }
}

- (NSAttributedString *)attributedTitle {
    NSAttributedString *result = nil;
    if (_title) {
        // Create a set of attributes to use
		
		NSMutableParagraphStyle *style = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
        [style setLineBreakMode:NSLineBreakByTruncatingTail];
		
        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
							   [NSFont boldSystemFontOfSize:14.0], NSFontAttributeName,
							   style, NSParagraphStyleAttributeName,
							   nil];
		
        result = [[[NSAttributedString alloc] initWithString:_title attributes:attrs] autorelease];
    }
    return result;
}

- (NSAttributedString *)attributedURLString {
    NSAttributedString *result = nil;
    if (_urlString) {
        // Create a set of attributes to use
		
		NSMutableParagraphStyle *style = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
        [style setLineBreakMode:NSLineBreakByTruncatingTail];
		
        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
							   [NSColor darkGrayColor], NSForegroundColorAttributeName,
							   style, NSParagraphStyleAttributeName,
							   nil];
        result = [[[NSAttributedString alloc] initWithString:_urlString attributes:attrs] autorelease];
    }
    return result;
}

#ifdef SHOW_NOTES
- (NSAttributedString *)attributedNotes {
    NSAttributedString *result = nil;
    if (_notes) {
        // Make the text color gray, or light gray, depending on if we are highlighted (selected) or not
        //NSColor *textColor = [self isHighlighted] ? [NSColor lightGrayColor] : [NSColor grayColor];
        // Create a set of attributes to use
		
		NSFont *font = [NSFont systemFontOfSize:[NSFont smallSystemFontSize]];
		
        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
							   font, NSFontAttributeName,
							   //[NSColor redColor], NSBackgroundColorAttributeName,
							   nil];
        result = [[[NSAttributedString alloc] initWithString:_notes attributes:attrs] autorelease];
    }
    return result;
}
#endif

- (NSRect)rectForString:(NSAttributedString*)string basedOnRect:(NSRect)rect inBounds:(NSRect)bounds forHeight:(CGFloat)height forPadding:(CGFloat)padding
{
    if (string != nil)
	{
        rect.origin.y += rect.size.height + padding;
        rect.size.width = [string size].width;
		rect.size.height = height;
        
		// Make sure it doesn't go past the bounds
        CGFloat amountPast = NSMaxX(rect) - NSMaxX(bounds);
        
		if (amountPast > 0) {
            rect.size.width -= amountPast;
        }
        
		return rect;
    }
	
	return NSZeroRect;
}

- (NSRect)rectForURLStringBasedOnTitleRect:(NSRect)titleRect inBounds:(NSRect)bounds
{
	return [self rectForString:[self attributedURLString] basedOnRect:titleRect inBounds:bounds forHeight:INFOBOX_URL_HEIGHT forPadding:INFOBOX_PADDING];
}

- (NSRect)imageRectForBounds:(NSRect)bounds {
    NSRect result = bounds;
    result.origin.y += IMAGEBOX_PADDING_TOP;
    result.origin.x += IMAGEBOX_PADDING_LEFT;
    if (_favicon != nil) { 
        // Take the actual image and center it in the result
        result.size = [_favicon size];
        CGFloat widthCenter = IMAGEBOX_IMAGE_SIZE - NSWidth(result);
        if (widthCenter > 0) {
            result.origin.x += round(widthCenter / 2.0);
        }
        CGFloat heightCenter = IMAGEBOX_IMAGE_SIZE - NSHeight(result);
        if (heightCenter > 0) {
            result.origin.y += round(heightCenter / 2.0);
        }
    } else {
        result.size.width = result.size.height = IMAGEBOX_IMAGE_SIZE;
    }
    return result;
}

- (NSRect)titleRectForBounds:(NSRect)bounds {
    NSAttributedString *title = [self attributedTitle];
    NSRect result = bounds;
    // The x origin is easy
    result.origin.x += INFOBOX_ORIGIN_LEFT;
    // The y origin should be inline with the image
    result.origin.y += INFOBOX_PADDING;
    // Set the width and the height based on the texts real size. Notice the nil check! Otherwise, the resulting NSSize could be undefined if we messaged a nil object.
    if (title != nil) {
        result.size = [title size];
    } else {
        result.size = NSZeroSize;
    }
    // Now, we have to constrain us to the bounds. The max x we can go to has to be the same as the bounds, but minus the info image location
    CGFloat maxX = NSMaxX(bounds);
    CGFloat maxWidth = maxX - NSMinX(result);
    if (maxWidth < 0) maxWidth = 0;
    // Constrain us to these bounds
    result.size.width = MIN(NSWidth(result), maxWidth);
    return result;
}

- (void)drawInteriorWithFrame:(NSRect)bounds inView:(NSView *)controlView {
	
    NSRect imageRect = [self imageRectForBounds:bounds];
    if (_favicon != nil) {
        [_favicon setFlipped:[controlView isFlipped]];
        [_favicon drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    }
	
    NSRect titleRect = [self titleRectForBounds:bounds];
    NSAttributedString *title = [self attributedTitle];
    if ([title length] > 0) {
        [title drawInRect:titleRect];
    }
	
    NSAttributedString *attributedURLString = [self attributedURLString];
	NSRect attributedURLStringRect;
    if ([attributedURLString length] > 0) {
        attributedURLStringRect = [self rectForURLStringBasedOnTitleRect:titleRect inBounds:bounds];
        [attributedURLString drawInRect:attributedURLStringRect];
    }
	else {
		attributedURLStringRect = NSZeroRect;
	}
	
#ifdef SHOW_NOTES
	NSAttributedString *attributedNotes = [self attributedNotes];
    if ([attributedNotes length] > 0)
	{
		NSRect attributedNotesRect = [self rectForString:attributedNotes
											 basedOnRect:attributedURLStringRect
												inBounds:bounds
											   forHeight:INFOBOX_NOTES_HEIGHT
											  forPadding:INFOBOX_PADDING];
        [attributedNotes drawInRect:attributedNotesRect];
    }
#endif
}

@end
