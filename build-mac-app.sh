#!/bin/bash
# Build the native Mac app on the user's own Mac. No prebuilt executable downloaded.
set -euo pipefail
cd "$(dirname "$0")"
if [ "$(uname -s)" != "Darwin" ]; then
  echo "This installer must run on macOS." >&2; exit 1
fi
if ! command -v xcrun >/dev/null 2>&1 || ! xcrun --find swiftc >/dev/null 2>&1; then
  echo "Apple Command Line Tools required. Run: xcode-select --install" >&2; exit 1
fi
if [ ! -f google-unlimited.sh ]; then
  echo "Missing google-unlimited.sh" >&2; exit 1
fi
bash -n google-unlimited.sh
APP="$PWD/GoogleUnlimited.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>GoogleUnlimited</string>
  <key>CFBundleDisplayName</key><string>GoogleUnlimited</string>
  <key>CFBundleIdentifier</key><string>dev.appbuilderlee2.googleunlimited.mac</string>
  <key>CFBundleExecutable</key><string>GoogleUnlimitedMac</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>12.0</string>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST
echo "Compiling locally with Apple's Swift compiler..."
xcrun swiftc -O -framework Cocoa -o "$APP/Contents/MacOS/GoogleUnlimitedMac" mac-app/GoogleUnlimitedMac.swift
chmod 700 "$APP/Contents/MacOS/GoogleUnlimitedMac"
echo "Built: $APP"
echo "Run: open '$APP'"
echo "Keep GoogleUnlimited.app inside this repo folder beside google-unlimited.sh."
echo "This compiles the GUI only; the existing unsigned gotohp helper remains a separate trust decision."
