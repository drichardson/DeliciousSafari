#!/bin/bash

set -e

SRC=DerivedData/DeliciousSafari/Build/Products/Debug/DeliciousSafari.bundle
DST_FOLDER=/Library/InputManagers/DeliciousSafari

sudo rm -rf "$DST_FOLDER/DeliciousSafari.bundle"
sudo cp -R "$SRC" "$DST_FOLDER"

echo OK
