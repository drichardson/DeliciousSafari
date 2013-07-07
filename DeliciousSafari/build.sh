#!/bin/bash
# DeliciousSafari build script
# Copyright Doug Richardson 2008
# Usage: build.sh <version>
#
# EXAMPLE:
# ./build.sh 1.5
#
# The result is a disk image that contains the DeliciousSafari installer
# and the DeliciousSafari Uninstaller. The disk image is formatted using
# a pre-built .DS_Store.
#
# The pre-built .DS_Store was created manually by creating
# a disk image, positioning the elements, setting the background image,
# adjusting the icon size, and then copying the resulting .DS_Store.
# For the pre-built .DS_Store to work, the names of the files must
# not change between builds.

PACKAGEMAKER="`pwd`/BuildTools/PackageMaker-AuxToolsLateJuly2012.app/Contents/MacOS/PackageMaker"

#
# Get the short version number from the command line.
#
VERSION=$1

if [ -z $VERSION ]; then
    echo "Usage: build.sh <version>"
    exit 1;
fi

if [ ! -d DeliciousSafari.xcodeproj ]; then
    echo "Usage: build.sh <version>"
    exit 1
fi

#
# Make sure the Info.plist has the right short version number in it.
#
INFO_PLIST_VERSION=`defaults read \`pwd\`/Info CFBundleShortVersionString`

if [ "$INFO_PLIST_VERSION" != "$VERSION" ]; then
    echo "Info.plist has a version of $INFO_PLIST_VERSION. Expected version of $VERSION"
    exit 1;
fi

#
# Increment the bundle version
#

# Make sure Xcode isn't running before incrementing the version.
ps -Ao comm|grep Xcode.app/Contents/MacOS/Xcode > /dev/null
if [ "$?" == 0 ]; then
    echo Xcode is running. Quit Xcode before running build.sh as this script will modify the DeliciousSafari Xcode project.
    exit 1
fi

xcrun agvtool next-version -all 
if [ "$?" != 0 ]; then
    echo "Couldn't find agvtool. Perhaps you need to install the Command Line Tools in Xcode."
    exit 1
fi


DSTROOT=/tmp/DeliciousSafari.dst
SRCROOT=/tmp/DeliciousSafari.src

INSTALLER_PATH=/tmp/DeliciousSafari.installer
INSTALLER_PKG="DeliciousSafari.pkg"
INSTALLER="$INSTALLER_PATH/$INSTALLER_PKG"

IMGROOT=/tmp/DeliciousSafari.imgroot

DMG_PATH=/tmp/DeliciousSafari.distribution
DMG="$DMG_PATH/DeliciousSafari $VERSION.dmg"
DMG_TITLE="DeliciousSafari"
MOUNTED_DMG_PATH="/Volumes/$DMG_TITLE"

#
# Clean out anything that doesn't belong.
#
echo Going to clean out build directories
sudo rm -rf build $DSTROOT $SRCROOT $IMGROOT $INSTALLER_PATH $DMG_PATH /tmp/FoundationDataObjects.dst FoundationDataObjects/build
echo Build directories cleaned out


#
# Build
#
sudo xcodebuild -project DeliciousSafari.xcodeproj installsrc SRCROOT=$SRCROOT || exit 1
pushd $SRCROOT
sudo xcodebuild -project DeliciousSafari.xcodeproj -target all -configuration Release install || exit 1
popd

#
# Make installer
#
echo ------------------
echo Building Installer
echo ------------------
sudo mkdir -p "$INSTALLER_PATH" || exit 1
pushd installer
sudo $PACKAGEMAKER -i com.delicioussafari --doc DeliciousSafari.pmdoc --no-recommend --out "$INSTALLER_PATH/DeliciousSafari.pkg" --verbose || exit 1
popd

#
# Make the Disk Image Root
#
echo
echo Building Disk Image Root...
sudo mkdir -p "$IMGROOT" || exit 1
sudo ditto "$INSTALLER" "$IMGROOT/$INSTALLER_PKG" || exit 1
sudo SetFile -a E "$IMGROOT/$INSTALLER_PKG" || exit 1
sudo ditto "$DSTROOT/Applications/Uninstall DeliciousSafari.app" "$IMGROOT/Uninstall DeliciousSafari.app" || exit 1
sudo cp installer/DMG-Background.png "$IMGROOT" || exit 1
sudo SetFile -a V "$IMGROOT/DMG-Background.png" || exit 1
sudo cp installer/DMG_DS_Store "$IMGROOT/.DS_Store" || exit 1

#
# Make Disk Image
#
echo
echo Building Disk Image...
sudo mkdir -p "$DMG_PATH" || exit 1
sudo hdiutil create -srcfolder "$IMGROOT" -fs HFS+ -volname "DeliciousSafari"  "$DMG" || exit 1


echo Successfully built DeliciousSafari
open "$DMG_PATH"
exit 0
