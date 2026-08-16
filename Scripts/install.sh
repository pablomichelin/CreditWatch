#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
destination="$HOME/Applications/CreditWatch.app"

bash "$project_dir/Scripts/build-app.sh"
mkdir -p "$HOME/Applications"
rm -rf "$destination"
ditto "$project_dir/dist/CreditWatch.app" "$destination"
open "$destination"
echo "Instalado em: $destination"
