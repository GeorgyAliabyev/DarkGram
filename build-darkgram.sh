#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

DEST="/Applications/Darkgram.app"
ALIAS="$HOME/Desktop/Darkgram"

xcodebuild -workspace Telegram-Mac.xcworkspace -scheme Telegram -configuration Debug -destination 'generic/platform=macOS' CODE_SIGNING_ALLOWED=NO MACOSX_DEPLOYMENT_TARGET=12.0 build "$@"

PRODUCT_DIR=$(xcodebuild -workspace Telegram-Mac.xcworkspace -scheme Telegram -configuration Debug -showBuildSettings 2>/dev/null | awk -F' = ' '/^ *BUILT_PRODUCTS_DIR = /{print $2; exit}')

if [ -z "${PRODUCT_DIR}" ] || [ ! -d "${PRODUCT_DIR}/Telegram.app" ]; then
    echo "Darkgram: built app not found in ${PRODUCT_DIR}" >&2
    exit 1
fi

rm -rf "/Applications/.Darkgram.app.new"
ditto "${PRODUCT_DIR}/Telegram.app" "/Applications/.Darkgram.app.new"
rm -rf "${DEST}"
mv "/Applications/.Darkgram.app.new" "${DEST}"

if [ -L "$HOME/Desktop/Darkgram.app" ]; then
    rm -f "$HOME/Desktop/Darkgram.app"
fi

if [ ! -e "${ALIAS}" ]; then
    osascript -e 'tell application "Finder" to make alias file to POSIX file "/Applications/Darkgram.app" at desktop with properties {name:"Darkgram"}'
fi

echo "Darkgram: ${DEST}"
