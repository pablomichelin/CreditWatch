#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
xcrun safari-web-extension-packager "$project_dir/BrowserExtension" --app-name CreditWatchSafari --bundle-identifier com.pablomichelin.creditwatch.safari --swift
