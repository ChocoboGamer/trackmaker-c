#!/usr/bin/env bash

set -euo pipefail

# this script assumes you have nfd.dll and nfd.so in your root dir, as well as
# love-release (https://github.com/MisterDA/love-release) installed
# mac also uses nfd.so, so it assumes you either also have nfd_mac.so or
# nfd_linux.so

nfd_windows=nfd.dll
nfd_mac=nfd.dylib
nfd_linux=nfd.so

ver=$(lua -e 'love = {}; require "conf"; local t = { window = {}, modules = {}, releases = {} }; love.conf(t); print(t.releases.version)')
echo "releasing ver ${ver}"

love-release -W 64 -M

# windows

rm -f releases/trackmaker-c-win64-*.zip

mkdir -p releases/trackmaker-c-win64
unzip releases/trackmaker-c-win64.zip -d releases/
rm releases/trackmaker-c-win64.zip

cp "$nfd_windows" releases/trackmaker-c-win64/nfd.dll
cp LICENSE.txt releases/trackmaker-c-win64/license.txt
cp platform/universal/love-license.txt releases/trackmaker-c-win64/love-license.txt

rm releases/trackmaker-c-win64/game.ico
rm releases/trackmaker-c-win64/love.ico
wine "platform/windows/rcedit.exe" "releases/trackmaker-c-win64/trackmaker-c.exe" --set-icon "platform/windows/trackmaker-c.ico"
#lua5.3 platform/windows/love-pe-wrapper.lua releases/trackmaker-c-win64/trackmaker-c.exe platform/windows/trackmaker-c.ico releases/trackmaker-c-win64/trackmaker-c-patched.exe
#mv releases/trackmaker-c-win64/trackmaker-c-patched.exe releases/trackmaker-c-win64/trackmaker-c.exe

cd releases/trackmaker-c-win64/ || exit 1
zip -9 "../trackmaker-c-win64-${ver}.zip" ./*
cd ../../
rm -r releases/trackmaker-c-win64

# mac

rm -f releases/trackmaker-c-macos-*.zip

unzip releases/trackmaker-c-macos.zip -d releases/
rm releases/trackmaker-c-macos.zip

cp "$nfd_mac" releases/trackmaker-c.app/Contents/Resources/nfd.dylib
cp platform/universal/love-license.txt releases/trackmaker-c.app/Contents/Resources/
cp LICENSE.txt releases/trackmaker-c.app/Contents/Resources/license.txt
cp platform/macos/Info.plist releases/trackmaker-c.app/Contents/
sed -i "s~{VERSION}~$ver~" releases/trackmaker-c.app/Contents/Info.plist
cp "platform/macos/OS X AppIcon.icns" releases/trackmaker-c.app/Contents/Resources/
rm releases/trackmaker-c.app/Contents/Resources/GameIcon.icns
rm releases/trackmaker-c.app/Contents/Resources/Assets.car
cp platform/macos/trackmaker-c releases/trackmaker-c.app/Contents/MacOS/

cd releases/ || exit 1
zip -r9 "trackmaker-c-macos-${ver}.zip" trackmaker-c.app
cd ../
rm -r releases/trackmaker-c.app/

# linux

rm -f releases/trackmaker-c-linux-*.zip

mkdir -p releases/trackmaker-c-linux

cp "$nfd_linux" releases/trackmaker-c-linux/nfd.so
cp releases/trackmaker-c.love releases/trackmaker-c-linux/
cp -r platform/linux/* releases/trackmaker-c-linux/
cp LICENSE.txt releases/trackmaker-c-linux/license.txt
cp platform/universal/love-license.txt releases/trackmaker-c-linux/love-license.txt

cd "releases/trackmaker-c-linux/" || exit 1
zip -r9 "../trackmaker-c-linux-${ver}.zip" ./*
cd ../../
rm -r releases/trackmaker-c-linux

# love

rm -f releases/trackmaker-c-*.love
cp releases/trackmaker-c.love "releases/trackmaker-c-${ver}.love"