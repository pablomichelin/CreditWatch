#!/bin/bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$project_dir/Resources/Info.plist" 2>/dev/null || echo "0.15.2")

echo "Compilando CreditWatch v${version}..."
bash "$project_dir/Scripts/build-app.sh"

dmg_staging="$project_dir/dist/dmg_staging"
dmg_out="$project_dir/dist/CreditWatch-v${version}.dmg"
zip_out="$project_dir/dist/CreditWatch-v${version}-macOS.zip"

echo "Preparando estrutura do DMG com atalho para /Applications..."
rm -rf "$dmg_staging" "$dmg_out"
mkdir -p "$dmg_staging"
cp -R "$project_dir/dist/CreditWatch.app" "$dmg_staging/"
ln -s /Applications "$dmg_staging/Applications"

echo "Gerando imagem DMG (CreditWatch-v${version}.dmg)..."
hdiutil create -volname "CreditWatch" -srcfolder "$dmg_staging" -ov -format UDZO "$dmg_out"
rm -rf "$dmg_staging"

echo "Gerando pacote ZIP (CreditWatch-v${version}-macOS.zip)..."
rm -f "$zip_out"
(cd "$project_dir/dist" && zip -r -q "$zip_out" "CreditWatch.app")

echo "================================================================"
echo "Build e empacotamento concluidos com sucesso!"
echo "DMG: $dmg_out"
echo "ZIP: $zip_out"
echo "================================================================"
