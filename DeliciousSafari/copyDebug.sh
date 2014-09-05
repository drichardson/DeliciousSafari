#!/bin/bash

set -e

DS_BUILT_BUNDLE_CONTENTS=DerivedData/DeliciousSafari/Build/Products/Debug/DeliciousSafari.bundle/Contents
DS_DST_CONTENTS=/Library/InputManagers/DeliciousSafari/DeliciousSafari.bundle/Contents

sudo cp $DS_BUILT_BUNDLE_CONTENTS/MacOS/DeliciousSafari $DS_DST_CONTENTS/MacOS/DeliciousSafari
sudo cp -R $DS_BUILT_BUNDLE_CONTENTS/Resources/*.nib $DS_DST_CONTENTS/Resources

echo OK
