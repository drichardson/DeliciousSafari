**********************************
* DeliciousSafari Developer ReadMe
**********************************

./build.sh <short_version>
Increments the bundle version and builds a DeliciousSafari distribution.

./dxGenStrings.sh
Uses the genstrings tool to creates an English language string table. It looks for calls to DXLocalizedString and overwrites the string table English.lproj/Localizable.strings.

***************************
* DeliciousSafari.xcodeproj
***************************

DeliciousSafari Target
Builds the DeliciousSafari bundle.

Install DS InputManager Target
Builds the DeliciousSafari bundle and copies the bundle executable in Contents/MacOS to /Library/InputManagers/... Before running this target, you must install DeliciousSafari using the normal installer. Also, if you change resources like images, string tables, or nibs, you must manually copy them over.

DeliciousAPI Tester
Probably out of date test tool for excercising the DXDeliciousAPI class.

ExecuteWithPrivileges
Builds a tool that can run shell commands as root. Used by the Install DS InputManager target to copy the bundle executable to /Library/InputManagers/...


******************
* String Resources
******************
dxGenStrings.sh is a genstrings wrapper that looks for DXLocalizedString calls. It should be used to update the strings file when new strings are added that should be localized (NOTE: Merging has not been tested yet).

One thing to note is that Xcode opens .strings files as property lists and saves them that way. This is not desired because the comment for the translator is lost. So make sure you open .strings file with TextEdit.