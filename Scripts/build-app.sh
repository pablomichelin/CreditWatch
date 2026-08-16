#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
bundle_dir="$project_dir/dist/CreditWatch.app"

swift build -c release --package-path "$project_dir"
rm -rf "$bundle_dir"
mkdir -p "$bundle_dir/Contents/MacOS" "$bundle_dir/Contents/Resources"
cp "$project_dir/.build/release/CreditWatch" "$bundle_dir/Contents/MacOS/CreditWatch"
cp "$project_dir/Resources/Info.plist" "$bundle_dir/Contents/Info.plist"
cp "$project_dir/Resources/CreditWatch.icns" "$bundle_dir/Contents/Resources/CreditWatch.icns"
xattr -cr "$bundle_dir"
codesign --force --deep --sign - "$bundle_dir"
echo "App criado em: $bundle_dir"
