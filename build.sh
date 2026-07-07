#!/bin/bash
set -e

APP="continueSession"
BUILD_DIR="build/$APP.app/Contents"

rm -rf "build/$APP.app"
mkdir -p "$BUILD_DIR/MacOS"
mkdir -p "$BUILD_DIR/Resources"

cp Info.plist "$BUILD_DIR/Info.plist"

echo "Compiling Swift..."
swiftc \
    -target arm64-apple-macos13.0 \
    -import-objc-header BridgingHeader.h \
    main.swift AppDelegate.swift SessionFinder.swift PopoverViewModel.swift PopoverView.swift \
    -framework Cocoa \
    -framework SwiftUI \
    -Xlinker -lproc \
    -o "$BUILD_DIR/MacOS/$APP"

# launcher.c is compiled as a build artifact but is not the CFBundleExecutable.
# Swift is compiled directly to the CFBundleExecutable name to avoid the window
# server parking status items when a bundle executable exec()'s a different binary.
echo "Compiling launcher (reference build)..."
cc -target arm64-apple-macos13.0 launcher.c -o "$BUILD_DIR/MacOS/launcher"

echo "Built: build/$APP.app"
echo "Run with: open build/$APP.app"
