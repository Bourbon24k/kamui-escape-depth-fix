#!/usr/bin/env bash
set -eo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
if [ -z "${SDK:-}" ]; then
    if [ -d /opt/theos/sdks/iPhoneOS14.5.sdk ]; then
        SDK="/opt/theos/sdks/iPhoneOS14.5.sdk"
    elif command -v xcrun >/dev/null 2>&1; then
        SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
    else
        SDK="/opt/theos/sdks/iPhoneOS14.5.sdk"
    fi
fi
APP_NAME="BQTool"
VERSION="2.5.0-depthfix"
BID="${BID:-com.kamui.escape}"
BUILD="$ROOT/build"
APP="$BUILD/Payload/$APP_NAME.app"

echo "[*] SDK: $SDK"
[ -d "$SDK" ] || { echo "[!] SDK missing"; exit 1; }

rm -rf "$BUILD"
mkdir -p "$APP"

echo "[*] compiling..."
LINKER_FLAGS=()
if [ "$(uname -s)" = "Linux" ]; then
    LINKER_FLAGS=(-fuse-ld=lld)
fi
clang \
    -target arm64-apple-ios14.0 \
    -isysroot "$SDK" \
    "${LINKER_FLAGS[@]}" \
    -fobjc-arc -fblocks -O2 \
    -Wall -Wno-unused-parameter -Wno-deprecated-declarations \
    -framework UIKit \
    -framework Foundation \
    -framework CoreFoundation \
    -framework CoreGraphics \
    -framework WebKit \
    -L"$SDK/usr/lib" -lz \
    "$ROOT/src/main.m" \
    "$ROOT/src/AppDelegate.m" \
    "$ROOT/src/SceneDelegate.m" \
    "$ROOT/src/RootTabBarController.m" \
    "$ROOT/src/GestaltVC.m" \
    "$ROOT/src/CacheExtraEditVC.m" \
    "$ROOT/src/PosterBoardVC.m" \
    "$ROOT/src/TendiesExploreVC.m" \
    "$ROOT/src/SettingsVC.m" \
    "$ROOT/src/LogVC.m" \
    "$ROOT/src/FilesVC.m" \
    "$ROOT/src/BQUI.m" \
    "$ROOT/src/BQCore.m" \
    "$ROOT/src/BQDepthFix.m" \
    -o "$APP/$APP_NAME"

cp "$ROOT/src/Info.plist" "$APP/Info.plist"
python3 - "$APP/Info.plist" "$BID" <<'PY'
import plistlib
import sys

path, bundle_id = sys.argv[1:]
with open(path, "rb") as source:
    info = plistlib.load(source)
info["CFBundleIdentifier"] = bundle_id
with open(path, "wb") as target:
    plistlib.dump(info, target, fmt=plistlib.FMT_XML, sort_keys=False)
PY
cp "$ROOT/src/respring.html" "$APP/respring.html"
for localization in "$ROOT"/src/*.lproj; do
    [ -d "$localization" ] || continue
    cp -R "$localization" "$APP/"
done

echo "[*] packing..."
(cd "$BUILD" && zip -qry "KAMUI-$VERSION.ipa" Payload)
echo "[*] done: $BUILD/KAMUI-$VERSION.ipa"
