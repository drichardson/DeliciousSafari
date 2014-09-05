//
//  DXUtilities.m
//  Safari Delicious Extension
//
//  Created by Douglas Richardson on 9/25/07.
//  Copyright 2007 Douglas Richardson. All rights reserved.
//

#import "DXUtilities.h"

const int kDXMaxMenuTitleLength = 60; // Safari history seems to use 60.

static NSBundle *gDXBundle = nil;
static NSString* HTMLEntityDecode(NSString *str);

#if 0
// Need to dynamically load these functions because they are only available on Leopard and later.
static int (*backtrace_funcptr)(void**,int);
static char** (*backtrace_symbols_funcptr)(void* const*,int);
#endif

@implementation DXUtilities

#if 0
+(void)initialize
{
	static BOOL initialized = NO;
	
	if(!initialized)
	{
		initialized = YES;
		
		// Dynamically load the backtrace methods because they are only available on Leopard.
		void *handle = dlopen("/usr/lib/libSystem.dylib", RTLD_LAZY);
		
		if(handle != NULL)
		{
			backtrace_funcptr = dlsym(handle, "backtrace");
			backtrace_symbols_funcptr = dlsym(handle, "backtrace_symbols");
		}
	}
}
#endif

+(DXUtilities*)defaultUtilities
{
	static DXUtilities *utils = nil;
	
	if(utils == nil)
	{
		utils = [[DXUtilities alloc] init];
	}
	
	return utils;
}

#ifdef DELICIOUSSAFARI_PLUGIN_TARGET
- (NSString*)applicationName
{
	return [[[NSWorkspace sharedWorkspace] activeApplication] objectForKey:@"NSApplicationName"];
}

- (void) goToURL:(NSString*)url
{
	if(url)
	{
		if([NSURL URLWithString:url] != nil)
		{
			NSString *script = [NSString stringWithFormat:
								@"tell application \"%@\"\n \
									try \n \
										set theURL to URL of front document \n \
									on error\n \
										open location \"%@\" \n \
									end try\n \
									set URL of document 1 to \"%@\" \n \
								end tell",
								[self applicationName],
								url,
								url];
			
			NSAppleScript *as = [[NSAppleScript alloc] initWithSource:script];
			[as executeAndReturnError:nil];
			[as release];
		}
		else
		{
			NSLog(@"Cannot go to URL. URL is malformed. URL: %@", url);
		}
	}
}

#endif

- (NSString*)decodeHTMLEntities:(NSString*)string
{
	return HTMLEntityDecode(string);
}

// RFB 1738 - URL Encoding. All characters are encoded, including special schema
// specific characters (i.e. & and ?).
- (NSString*)urlEncode:(NSString*)url
{
	NSString *result = nil;
	//NSLog(@"URL Start: %@", url);
	NSString *utf8Escaped = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	const char* urlStr = [utf8Escaped cStringUsingEncoding:NSUTF8StringEncoding];
	//NSLog(@"URL After: %s", urlStr);
	
	if(urlStr == NULL)
		goto bail;
	
	int len = strlen(urlStr);
	char* resultStr = malloc(len * 3 + 1); // Worst case is len * 3 as you may have to encode every character.
	
	int i, result_i;
	for(i = result_i = 0; i < len; ++i)
	{
		// --------------------------------------------------------------------
		// Per RFC 1738:
		// Thus, only alphanumerics, the special characters "$-_.+!*'(),", and
		// reserved characters used for their reserved purposes may be used
		// unencoded within a URL.
		//
		// HOWEVER, this is going to encode the reserved characters as well.
		// NOTE: According to the spec, double quote (") is supposed to be okay, but
		// I've found if I don't encode it I get an error with the URLConnection object.
		// Specifically, it says: bad URL.
		// Also, don't process % as it was already processed above in stringByAddingPercentEscapesUsingEncoding.
		//
		// See http://www.eskimo.com/~bloo/indexdot/html/topics/urlencoding.htm for more info as well.
		// All "reserved characters" should be encoded.
		// --------------------------------------------------------------------
		char c = urlStr[i];
		if(isalnum(c) ||  c == '-' || c == '_' || c == '.' || c == '!' || c == '*' ||
		   c == '\'' || c == '(' || c == ')' || c == ',' || c == '%')
		{
			// Do NOT need to encode.
			resultStr[result_i] = c;
			result_i++;
		}
		else
		{
			// DO need to encode.
			sprintf(resultStr + result_i, "%%%X02", c);
			result_i += 3;
		}
	}
	
	resultStr[result_i] = 0;
	result = [NSString stringWithUTF8String:resultStr];
	free(resultStr);
	resultStr = NULL;
bail:
	if(result == nil)
		result = url;
	
	//NSLog(@"urlEncode(%@) = %@", url, result);
	
	return result;
}


#if 0
- (BOOL)isFunctionInCallstack:(const char*)function
{
	BOOL result = NO;
	void *backtraceFrames[128];
	
	if(backtrace_funcptr == NULL || backtrace_symbols_funcptr == NULL)
		goto bail;
	
	int frameCount = backtrace_funcptr(&backtraceFrames[0], 128);
	char **frameStrings = backtrace_symbols_funcptr(&backtraceFrames[0], frameCount);
	
	if(frameStrings != NULL) {
		int x = 0;
		for(x = 0; x < frameCount; x++)
		{
			if(frameStrings[x] == NULL)
				break;
			
			if(strstr(frameStrings[x], function) != 0)
			{
				result = YES;
				break;
			}
		}
		free(frameStrings);
	}
	
bail:
	return result;
}
#endif

-(NSString*)applicationSupportPath
{
	NSString *path = [@"~/Library/Application Support/DeliciousSafari" stringByExpandingTildeInPath];
	BOOL isDirectory;
	
	if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory])
	{
		if(!isDirectory)
			NSLog(@"ERROR: DeliciousSafari application support path is not a directory.");
	}
	else
	{
        NSError* error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
        if ( error )
        {
            NSLog(@"Error trying to create path %@. %@", path, error);
        }
	}
	
	return path;
}

@end

// Decodes HTML entities from http://www.w3schools.com/tags/ref_entities.asp into a
// string suitable for displaying in a Cocoa GUI.
static NSString*
HTMLEntityDecode(NSString *str)
{
	struct EntityMap
	{
		NSString *from;
		NSString *to;
	};
	
	static struct EntityMap entityMap[] = {
		
		// ASCII Entities with Entity Names
		{@"&quot;", @"\""}, {@"&#34;", @"\""}, {@"&#034;", @"\""},
		{@"&apos;", @"'"}, {@"&#39;", @"'"}, {@"&#039;", @"'"},
		{@"&amp;", @"&"}, {@"&#38;", @"&"}, {@"&#038;", @"&"}, {@"&#x26;", @"&"},
		{@"&lt;", @"<"}, {@"&#60;", @"<"}, {@"&#060;", @"<"},
		{@"&gt;", @">"}, {@"&#62;", @">"}, {@"&#062;", @">"},
		
		// ISO 8859-1 Symbol Entities
		{@"&nbsp;", @" " },	{@"&#160;", @" "},
		{@"&iexcl;", @"¡"},	{@"&#161;", @"¡"},
		{@"&cent;", @"¢"},	{@"&#162;", @"¢"},
		{@"&pound;", @"£"}, {@"&#163;", @"£"},
		{@"&curren;", @"¤"},{@"&#164;", @"¤"},
		{@"&yen;", @"¥"},	{@"&#165;", @"¥"},
		{@"&brvbar;", @"¦"},{@"&#166;", @"¦"},
		{@"&sect;", @"§"},	{@"&#167;", @"§"},
		{@"&uml;", @"¨"},	{@"&#168;", @"¨"},
		{@"&copy;", @"©"},	{@"&#169;", @"©"},
		{@"&ordf;", @"ª"},	{@"&#170;", @"ª"},
		{@"&laquo;", @"«"},	{@"&#171;", @"«"},
		{@"&not;", @"¬"},	{@"&#172;", @"¬"},
		{@"&shy;", @"-"},	{@"&#173;", @"-"},
		{@"&reg;", @"®"},	{@"&#174;", @"®"},
		{@"&macr;", @"¯"},	{@"&#175;", @"¯"},
		{@"&deg;", @"°"},	{@"&#176;", @"°"},
		{@"&plusmn;", @"±"},{@"&#177;", @"±"},
		{@"&sup2;", @"²"},	{@"&#178;", @"²"},
		{@"&sup3;", @"³"},	{@"&#179;", @"³"},
		{@"&acute;", @"´"},	{@"&#180;", @"´"},
		{@"&micro;", @"µ"},	{@"&#181;", @"µ"},
		{@"&para;", @"¶"},	{@"&#182;", @"¶"},
		{@"&middot;", @"·"},{@"&#183;", @"·"},
		{@"&cedil;", @"¸"},	{@"&#184;", @"¸"},
		{@"&sup1;", @"¹"},	{@"&#185;", @"¹"},
		{@"&ordm;", @"º"},	{@"&#186;", @"º"},
		{@"&raquo;", @"»"},	{@"&#187;", @"»"},
		{@"&frac14;", @"¼"},{@"&#188;", @"¼"},
		{@"&frac12;", @"½"},{@"&#189;", @"½"},
		{@"&frac34;", @"¾"},{@"&#190;", @"¾"},
		{@"&iquest;", @"¿"},{@"&#191;", @"¿"},
		{@"&times;", @"×"}, {@"&#215;", @"×"},
		{@"&divide;", @"÷"},{@"&#247;", @"÷"},
		
		// ISO 8859-1 Character Entities
		{@"&Agrave;", @"À"}, {@"&#192;", @"À"},
		{@"&Aacute;", @"Á"}, {@"&#193;", @"Á"},
		{@"&Acirc;", @"Â"}, {@"&#194;", @"Â"},
		{@"&Atilde;", @"Ã"}, {@"&#195;", @"Ã"},
		{@"&Auml;", @"Ä"}, {@"&#196;", @"Ä"},
		{@"&Aring;", @"Å"}, {@"&#197;", @"Å"},
		{@"&AElig;", @"Æ"}, {@"&#198;", @"Æ"},
		{@"&Ccedil;", @"Ç"}, {@"&#199;", @"Ç"},
		{@"&Egrave;", @"È"}, {@"&#200;", @"È"},
		{@"&Eacute;", @"É"}, {@"&#201;", @"É"},
		{@"&Ecirc;", @"Ê"}, {@"&#202;", @"Ê"},
		{@"&Euml;", @"Ë"}, {@"&#203;", @"Ë"},
		{@"&Igrave;", @"Ì"}, {@"&#204;", @"Ì"},
		{@"&Iacute;", @"Í"}, {@"&#205;", @"Í"},
		{@"&Icirc;", @"Î"}, {@"&#206;", @"Î"},
		{@"&Iuml;", @"Ï"}, {@"&#207;", @"Ï"},
		{@"&ETH;", @"Ð"}, {@"&#208;", @"Ð"},
		{@"&Ntilde;", @"Ñ"}, {@"&#209;", @"Ñ"},
		{@"&Ograve;", @"Ò"}, {@"&#210;", @"Ò"},
		{@"&Oacute;", @"Ó"}, {@"&#211;", @"Ó"},
		{@"&Ocirc;", @"Ô"}, {@"&#212;", @"Ô"},
		{@"&Otilde;", @"Õ"}, {@"&#213;", @"Õ"},
		{@"&Ouml;", @"Ö"}, {@"&#214;", @"Ö"},
		{@"&Oslash;", @"Ø"}, {@"&#216;", @"Ø"},
		{@"&Ugrave;", @"Ù"}, {@"&#217;", @"Ù"},
		{@"&Uacute;", @"Ú"}, {@"&#218;", @"Ú"},
		{@"&Ucirc;", @"Û"}, {@"&#219;", @"Û"},
		{@"&Uuml;", @"Ü"}, {@"&#220;", @"Ü"},
		{@"&Yacute;", @"Ý"}, {@"&#221;", @"Ý"},
		{@"&THORN;", @"Þ"}, {@"&#222;", @"Þ"},
		{@"&szlig;", @"ß"}, {@"&#223;", @"ß"},
		{@"&agrave;", @"à"}, {@"&#224;", @"à"},
		{@"&aacute;", @"á"}, {@"&#225;", @"á"},
		{@"&acirc;", @"â"}, {@"&#226;", @"â"},
		{@"&atilde;", @"ã"}, {@"&#227;", @"ã"},
		{@"&auml;", @"ä"}, {@"&#228;", @"ä"},
		{@"&aring;", @"å"}, {@"&#229;", @"å"},
		{@"&aelig;", @"æ"}, {@"&#230;", @"æ"},
		{@"&ccedil;", @"ç"}, {@"&#231;", @"ç"},
		{@"&egrave;", @"è"}, {@"&#232;", @"è"},
		{@"&eacute;", @"é"}, {@"&#233;", @"é"},
		{@"&ecirc;", @"ê"}, {@"&#234;", @"ê"},
		{@"&euml;", @"ë"}, {@"&#235;", @"ë"},
		{@"&igrave;", @"ì"}, {@"&#236;", @"ì"},
		{@"&iacute;", @"í"}, {@"&#237;", @"í"},
		{@"&icirc;", @"î"}, {@"&#238;", @"î"},
		{@"&iuml;", @"ï"}, {@"&#239;", @"ï"},
		{@"&eth;", @"ð"}, {@"&#240;", @"ð"},
		{@"&ntilde;", @"ñ"}, {@"&#241;", @"ñ"},
		{@"&ograve;", @"ò"}, {@"&#242;", @"ò"},
		{@"&oacute;", @"ó"}, {@"&#243;", @"ó"},
		{@"&ocirc;", @"ô"}, {@"&#244;", @"ô"},
		{@"&otilde;", @"õ"}, {@"&#245;", @"õ"},
		{@"&ouml;", @"ö"}, {@"&#246;", @"ö"},
		{@"&oslash;", @"ø"}, {@"&#248;", @"ø"},
		{@"&ugrave;", @"ù"}, {@"&#249;", @"ù"},
		{@"&uacute;", @"ú"}, {@"&#250;", @"ú"},
		{@"&ucirc;", @"û"}, {@"&#251;", @"û"},
		{@"&uuml;", @"ü"}, {@"&#252;", @"ü"},
		{@"&yacute;", @"ý"}, {@"&#253;", @"ý"},
		{@"&thorn;", @"þ"}, {@"&#254;", @"þ"},
		{@"&yuml;", @"ÿ"}, {@"&#255;", @"ÿ"},
		
		// Math Symbols Supported by HTML
		{@"&forall;", @"∀"}, {@"&#8704;", @"∀"},
		{@"&part;", @"∂"}, {@"&#8706;", @"∂"},
		{@"&exists;", @"∃"}, {@"&#8707;", @"∃"},
		{@"&empty;", @"∅"}, {@"&#8709;", @"∅"},
		{@"&nabla;", @"∇"}, {@"&#8711;", @"∇"},
		{@"&isin;", @"∈"}, {@"&#8712;", @"∈"},
		{@"&notin;", @"∉"}, {@"&#8713;", @"∉"},
		{@"&ni;", @"∋"}, {@"&#8715;", @"∋"},
		{@"&prod;", @"∏"}, {@"&#8719;", @"∏"},
		{@"&sum;", @"∑"}, {@"&#8721;", @"∑"},
		{@"&minus;", @"−"}, {@"&#8722;", @"−"},
		{@"&lowast;", @"∗"}, {@"&#8727;", @"∗"},
		{@"&radic;", @"√"}, {@"&#8730;", @"√"},
		{@"&prop;", @"∝"}, {@"&#8733;", @"∝"},
		{@"&infin;", @"∞"}, {@"&#8734;", @"∞"},
		{@"&ang;", @"∠"}, {@"&#8736;", @"∠"},
		{@"&and;", @"∧"}, {@"&#8743;", @"∧"},
		{@"&or;", @"∨"}, {@"&#8744;", @"∨"},
		{@"&cap;", @"∩"}, {@"&#8745;", @"∩"},
		{@"&cup;", @"∪"}, {@"&#8746;", @"∪"},
		{@"&int;", @"∫"}, {@"&#8747;", @"∫"},
		{@"&there4;", @"∴"}, {@"&#8756;", @"∴"},
		{@"&sim;", @"∼"}, {@"&#8764;", @"∼"},
		{@"&cong;", @"≅"}, {@"&#8773;", @"≅"},
		{@"&asymp;", @"≈"}, {@"&#8776;", @"≈"},
		{@"&ne;", @"≠"}, {@"&#8800;", @"≠"},
		{@"&equiv;", @"≡"}, {@"&#8801;", @"≡"},
		{@"&le;", @"≤"}, {@"&#8804;", @"≤"},
		{@"&ge;", @"≥"}, {@"&#8805;", @"≥"},
		{@"&sub;", @"⊂"}, {@"&#8834;", @"⊂"},
		{@"&sup;", @"⊃"}, {@"&#8835;", @"⊃"},
		{@"&nsub;", @"⊄"}, {@"&#8836;", @"⊄"},
		{@"&sube;", @"⊆"}, {@"&#8838;", @"⊆"},
		{@"&supe;", @"⊇"}, {@"&#8839;", @"⊇"},
		{@"&oplus;", @"⊕"}, {@"&#8853;", @"⊕"},
		{@"&otimes;", @"⊗"}, {@"&#8855;", @"⊗"},
		{@"&perp;", @"⊥"}, {@"&#8869;", @"⊥"},
		{@"&sdot;", @"⋅"}, {@"&#8901;", @"⋅"},
		
		// Greek Letters Supported by HTML
		{@"&Aplha;", @"Α"}, {@"&#913;", @"Α"},
		{@"&Beta;", @"Β"}, {@"&#914;", @"Β"},
		{@"&Gamma;", @"Γ"}, {@"&#915;", @"Γ"},
		{@"&Delta;", @"Δ"}, {@"&#916;", @"Δ"},
		{@"&Epsilon;", @"Ε"}, {@"&#917;", @"Ε"},
		{@"&Zeta;", @"Ζ"}, {@"&#918;", @"Ζ"},
		{@"&Eta;", @"Η"}, {@"&#919;", @"Η"},
		{@"&Theta;", @"Θ"}, {@"&#920;", @"Θ"},
		{@"&Iota;", @"Ι"}, {@"&#921;", @"Ι"},
		{@"&Kappa;", @"Κ"}, {@"&#922;", @"Κ"},
		{@"&Lambda;", @"Λ"}, {@"&#923;", @"Λ"},
		{@"&Mu;", @"Μ"}, {@"&#924;", @"Μ"},
		{@"&Nu;", @"Ν"}, {@"&#925;", @"Ν"},
		{@"&Xi;", @"Ξ"}, {@"&#926;", @"Ξ"},
		{@"&Omicron;", @"Ο"}, {@"&#927;", @"Ο"},
		{@"&Pi;", @"Π"}, {@"&#928;", @"Π"},
		{@"&Rho;", @"Ρ"}, {@"&#929;", @"Ρ"},
		{@"&Sigma;", @"Σ"}, {@"&#931;", @"Σ"},
		{@"&Tau;", @"Τ"}, {@"&#932;", @"Τ"},
		{@"&Upsilon;", @"Υ"}, {@"&#933;", @"Υ"},
		{@"&Phi;", @"Φ"}, {@"&#934;", @"Φ"},
		{@"&Chi;", @"Χ"}, {@"&#935;", @"Χ"},
		{@"&Psi;", @"Ψ"}, {@"&#936;", @"Ψ"},
		{@"&Omega;", @"Ω"}, {@"&#937;", @"Ω"}, 	 
		{@"&aplha;", @"α"}, {@"&#945;", @"α"},
		{@"&beta;", @"β"}, {@"&#946;", @"β"},
		{@"&gamma;", @"γ"}, {@"&#947;", @"γ"},
		{@"&delta;", @"δ"}, {@"&#948;", @"δ"},
		{@"&epsilon;", @"ε"}, {@"&#949;", @"ε"},
		{@"&zeta;", @"ζ"}, {@"&#950;", @"ζ"},
		{@"&eta;", @"η"}, {@"&#951;", @"η"},
		{@"&theta;", @"θ"}, {@"&#952;", @"θ"},
		{@"&iota;", @"ι"}, {@"&#953;", @"ι"},
		{@"&kappa;", @"κ"}, {@"&#954;", @"κ"},
		{@"&lambda;", @"λ"}, {@"&#923;", @"λ"},
		{@"&mu;", @"μ"}, {@"&#956;", @"μ"},
		{@"&nu;", @"ν"}, {@"&#925;", @"ν"},
		{@"&xi;", @"ξ"}, {@"&#958;", @"ξ"},
		{@"&omicron;", @"ο"}, {@"&#959;", @"ο"},
		{@"&pi;", @"π"}, {@"&#960;", @"π"},
		{@"&rho;", @"ρ"}, {@"&#961;", @"ρ"},
		{@"&sigmaf;", @"ς"}, {@"&#962;", @"ς"},
		{@"&sigma;", @"σ"}, {@"&#963;", @"σ"},
		{@"&tau;", @"τ"}, {@"&#964;", @"τ"},
		{@"&upsilon;", @"υ"}, {@"&#965;", @"υ"},
		{@"&phi;", @"φ"}, {@"&#966;", @"φ"},
		{@"&chi;", @"χ"}, {@"&#967;", @"χ"},
		{@"&psi;", @"ψ"}, {@"&#968;", @"ψ"},
		{@"&omega;", @"ω"}, {@"&#969;", @"ω"},
		{@"&thetasym;", @"ϑ"}, {@"&#977;", @"ϑ"},
		{@"&upsih;", @"ϒ"}, {@"&#978;", @"ϒ"},
		{@"&piv;", @"ϖ"}, {@"&#982;", @"ϖ"},
		
		// Some Other Entities Supported by HTML
		{@"&OElig;", @"Œ"}, {@"&#338;", @"Œ"},
		{@"&oelig;", @"œ"}, {@"&#339;", @"œ"},
		{@"&Scaron;", @"Š"}, {@"&#352;", @"Š"},
		{@"&scaron;", @"š"}, {@"&#353;", @"š"},
		{@"&Yuml;", @"Ÿ"}, {@"&#376;", @"Ÿ"},
		{@"&fnof;", @"ƒ"}, {@"&#402;", @"ƒ"},
		{@"&circ;", @"ˆ"}, {@"&#710;", @"ˆ"},
		{@"&tilde;", @"˜"}, {@"&#732;", @"˜"},
		{@"&ensp;", @" "}, {@"&#8194;", @" "},
		{@"&emsp;", @" "}, {@"&#8195;", @" "},
		{@"&thinsp;", @" "}, {@"&#8201;", @" "},
		{@"&zwnj;", @"‌"}, {@"&#8204;", @"‌"}, // zwnj is not blank - it is an Arabic character joining command
		{@"&zwj;", @"‍"}, {@"&#8205;", @"‍"}, // zwj is not blank - it is an Arabic character joining command
		{@"&lrm;", @""}, {@"&#8206;", @""}, // lrm is a real blank, because it is never displayed
		{@"&rlm;", @""}, {@"&#8207;", @""}, // rlm is a real blank, because it is never displayed
		{@"&ndash;", @"–"}, {@"&#8211;", @"–"},
		{@"&mdash;", @"—"}, {@"&#8212;", @"—"},
		{@"&lsquo;", @"‘"}, {@"&#8216;", @"‘"},
		{@"&rsquo;", @"’"}, {@"&#8217;", @"’"},
		{@"&sbquo;", @"‚"}, {@"&#8218;", @"‚"},
		{@"&ldquo;", @"“"}, {@"&#8220;", @"“"},
		{@"&rdquo;", @"”"}, {@"&#8221;", @"”"},
		{@"&bdquo;", @"„"}, {@"&#8222;", @"„"},
		{@"&dagger;", @"†"}, {@"&#8224;", @"†"},
		{@"&Dagger;", @"‡"}, {@"&#8225;", @"‡"},
		{@"&bull;", @"•"}, {@"&#8226;", @"•"},
		{@"&hellip;", @"…"}, {@"&#8230;", @"…"},
		{@"&permil;", @"‰"}, {@"&#8240;", @"‰"},
		{@"&prime;", @"′"}, {@"&#8242;", @"′"},
		{@"&Prime;", @"″"}, {@"&#8243;", @"″"},
		{@"&lsaquo;", @"‹"}, {@"&#8249;", @"‹"},
		{@"&rsaquo;", @"›"}, {@"&#8250;", @"›"},
		{@"&oline;", @"‾"}, {@"&#8254;", @"‾"},
		{@"&euro;", @"€"}, {@"&#8364;", @"€"},
		{@"&trade;", @"™"}, {@"&#8482;", @"™"},
		{@"&larr;", @"←"}, {@"&#8592;", @"←"},
		{@"&uarr;", @"↑"}, {@"&#8593;", @"↑"},
		{@"&rarr;", @"→"}, {@"&#8594;", @"→"},
		{@"&darr;", @"↓"}, {@"&#8595;", @"↓"},
		{@"&harr;", @"↔"}, {@"&#8596;", @"↔"},
		{@"&crarr;", @"↵"}, {@"&#8629;", @"↵"},
		{@"&lceil;", @"⌈"}, {@"&#8968;", @"⌈"},
		{@"&rceil;", @"⌉"}, {@"&#8969;", @"⌉"},
		{@"&lfloor;", @"⌊"}, {@"&#8970;", @"⌊"},
		{@"&rfloor;", @"⌋"}, {@"&#8971;", @"⌋"},
		{@"&loz;", @"◊"}, {@"&#9674;", @"◊"},
		{@"&spades;", @"♠"}, {@"&#9824;", @"♠"},
		{@"&clubs;", @"♣"}, {@"&#9827;", @"♣"},
		{@"&hearts;", @"♥"}, {@"&#9829;", @"♥"},
		{@"&diams;", @"♦"}, {@"&#9830;", @"♦"}
	};
	
	NSMutableString *result = [[str mutableCopy] autorelease];
	
	const size_t entityMapCount = sizeof(entityMap)/sizeof(entityMap[0]);
	size_t i;
	for(i = 0; i < entityMapCount; ++i)
	{
		// Entity names are case sensitive.
		[result replaceOccurrencesOfString:entityMap[i].from
								withString:entityMap[i].to
								   options:0
									 range:NSMakeRange(0, [result length])];
	}
	
	return result;
}

static NSString *DXLocalizedStringFromTable(NSString *key, NSString *tableName, NSString *comment)
{
	if(gDXBundle == nil)
		gDXBundle = [[NSBundle bundleForClass:[DXUtilities class]] retain];
	
	NSString *result;
	
	if(gDXBundle == nil)
		result = key;
	else
		result = NSLocalizedStringFromTableInBundle(key, tableName, gDXBundle, comment);
	
	return result;
}

NSString *DXLocalizedString(NSString *key, NSString *comment)
{	
	return DXLocalizedStringFromTable(key, nil, comment);
}
