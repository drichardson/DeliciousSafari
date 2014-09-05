//
//  HyperlinkedTextField.m
//  
//  This subclass is a supplement for Apple Developer Connection's 
//  Technical Q&A QA1487
//  URL: http://developer.apple.com/qa/qa2006/qa1487.html
//  
//  Purpose: provide a method for setting a URL for a text field
//			 added via subclass

#import "DXHyperlinkedTextField.h"
#import "DXUtilities.h"

static NSAttributedString* hyperlinkFromString(NSString* inString);

@implementation DXHyperlinkedTextField

-(void)dealloc
{
	[targetURL release];
	[super dealloc];
}

-(void)setURL:(NSURL *)newTargetURL
{
	if(newTargetURL != targetURL)
	{
		[targetURL release];
		targetURL = [newTargetURL retain];
	}
	
	// both are needed, otherwise hyperlink won't accept mousedown
    [self setAllowsEditingTextAttributes:NO];
	[self setEditable:NO];
    [self setSelectable:YES];
	
    NSAttributedString* createdString = hyperlinkFromString([self stringValue]);
		
    // set the attributed string to the NSTextField
    [self setAttributedStringValue:createdString];
}

- (void)resetCursorRects
{
	NSCursor *cursor = [NSCursor pointingHandCursor];
	[cursor setOnMouseEntered:YES];
	[self addCursorRect:[self bounds] cursor:cursor];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	if(targetURL != nil)
	{
		if(delegate && [delegate respondsToSelector:@selector(willGoToURL:)])
			[delegate performSelector:@selector(willGoToURL:) withObject:self];
			
		[[DXUtilities defaultUtilities] goToURL:[targetURL absoluteString]];
	}
}

-(void)setDelegate:(id)newDelegate
{
	delegate = newDelegate;
}

@end

static NSAttributedString*
hyperlinkFromString(NSString* inString)
{
    NSMutableAttributedString* attrString = [[[NSMutableAttributedString alloc] initWithString:inString] autorelease];
    NSRange range = NSMakeRange(0, [attrString length]);
	
    [attrString beginEditing];
	
    // make the text appear in blue
    [attrString addAttribute:NSForegroundColorAttributeName
					   value:[NSColor blueColor]
					   range:range];
	
    // next make the text appear with an underline
    [attrString addAttribute:NSUnderlineStyleAttributeName
					   value:[NSNumber numberWithInt:NSUnderlineStyleSingle]
					   range:range];
	
	[attrString addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]] range:range];
	
    [attrString endEditing];
	
    return attrString;
}
