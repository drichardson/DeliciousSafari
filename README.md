Warning: Project no longer maintained.
======================================
As of OS X 10.11 (El Capitan) and Safari 9, the DeliciousSafari plug-in will no
longer load due to a privilege violation. 

    12/18/15 10:12:53.966 DeliciousSafariAgent[36169]: Error loading DeliciousSafari into Safari. Error Info: {
        NSAppleScriptErrorAppName = Safari;
        NSAppleScriptErrorBriefMessage = "A privilege violation occurred.";
        NSAppleScriptErrorMessage = "Safari got an error: A privilege violation occurred.";
        NSAppleScriptErrorNumber = "-10004";
        NSAppleScriptErrorRange = "NSRange: {24, 25}";
    }

DeliciousSafari was developed when input manager plug-ins were the only way to add extensions
to Safari. Since then, Safari has release an official extension developer SDK. Since it was
first written, DeliciousSafari had to adapt to security changes made by Apple, moving from
an input manager plug-in to an Apple script extension.

Also, about a year ago, delicious.com broke backwards compatibility by requiring OAuth, vs
Basic HTTP Authentication over HTTPS that DeliciousSafari relied on.

Both the Apple security changes and Delicious.com changes make sense for improving end user
security, but in the process have obsoleted the approach taken by DeliciousSafari. Thus, this
project will no longer be maintained.

Doug

2015-12-18


DeliciousSafari
======================================
This repository contains the DeliciousSafari plug-in for Safari and the Bookmarks iPhone app.

Building
---------

<pre>
./build.sh <short_version>
</pre>
Increments the bundle version and builds a DeliciousSafari distribution.

<pre>
./dxGenStrings.sh
</pre>
Uses the genstrings tool to creates an English language string table. It looks for calls to DXLocalizedString and overwrites the string table English.lproj/Localizable.strings.

DeliciousSafari.xcodeproj
---------------------------

DeliciousSafari Target
Builds the DeliciousSafari bundle.

Install DS InputManager Target
Builds the DeliciousSafari bundle and copies the bundle executable in Contents/MacOS to /Library/InputManagers/... Before running this target, you must install DeliciousSafari using the normal installer. Also, if you change resources like images, string tables, or nibs, you must manually copy them over.

DeliciousAPI Tester
Probably out of date test tool for excercising the DXDeliciousAPI class.

ExecuteWithPrivileges
Builds a tool that can run shell commands as root. Used by the Install DS InputManager target to copy the bundle executable to /Library/InputManagers/...


String Resources
-------------------------
dxGenStrings.sh is a genstrings wrapper that looks for DXLocalizedString calls. It should be used to update the strings file when new strings are added that should be localized (NOTE: Merging has not been tested yet).

One thing to note is that Xcode opens .strings files as property lists and saves them that way. This is not desired because the comment for the translator is lost. So make sure you open .strings file with TextEdit.
