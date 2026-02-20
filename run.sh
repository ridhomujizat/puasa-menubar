#!/bin/bash
set -e

APP_NAME="PuasaMenubar"
APP_BUNDLE="${APP_NAME}.app"
ENTITLEMENTS="PuasaMenubar/PuasaMenubar.entitlements"
INFO_PLIST="PuasaMenubar/Info.plist"

echo "Building..."
swift build 2>&1

echo "Packaging .app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp ".build/debug/${APP_NAME}" "$APP_BUNDLE/Contents/MacOS/"
cp "$INFO_PLIST" "$APP_BUNDLE/Contents/Info.plist"

echo "Signing with entitlements..."
codesign --force --sign - --entitlements "$ENTITLEMENTS" "$APP_BUNDLE"

echo "Launching..."
open "$APP_BUNDLE"
