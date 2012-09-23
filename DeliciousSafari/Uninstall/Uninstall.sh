#!/bin/bash

OLD_BUNDLE="$HOME/Library/Application Support/SIMBL/Plugins/DeliciousSafari.bundle"
PLIST="$HOME/Library/Preferences/com.delicioussafari.DeliciousSafari.plist"
DSINPUTMANAGER="/Library/InputManagers/DeliciousSafari"

whoami
echo "EUID is $EUID"

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

echo -n "Looking for DeliciousSafari..."
if [ -d "$DSINPUTMANAGER" ]; then
	echo " FOUND. Removing.";
	rm -rf "$DSINPUTMANAGER" 2>&1 || exit 1
else
	echo "not found";
fi

echo -n "Looking for old DeliciousSafari.bundle..."
if [ -d "$OLD_BUNDLE" ]; then
	echo " FOUND. Removing.";
	rm -rf "$OLD_BUNDLE" 2>&1 || exit 1
else
	echo "not found";
fi

if [ "$1" == "DeletePreferences" ]; then
	echo -n "Looking for DeliciousSafari preferences..."
	if [ -f "$PLIST" ]; then
		echo " FOUND. Removing.";
		rm -f "$PLIST" 2>&1 || exit 1
	else
		echo " not found";
	fi
fi

echo "Successfully uninstalled DeliciousSafari."
