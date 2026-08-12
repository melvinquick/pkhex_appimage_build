#!/bin/bash
set -euo pipefail

app_dir="pkhex_appdir"
publish_dir="$(cd "$(dirname "$0")" && pwd)/pkhex_publish_output"

echo -n "Cleaning previous build... "
rm -rf "$app_dir" *.AppImage 2>/dev/null || true
echo "✓"

echo -n "Verifying publish output... "
if [ ! -f "$publish_dir/PKHeX.exe" ]; then
    echo "✗"
    echo "ERROR: $publish_dir/PKHeX.exe not found! Run ./prepare_pkhex_source.sh first."
    exit 1
fi
echo "✓"

echo -n "Creating AppDir structure... "
mkdir -p "$app_dir"/{opt/pkhex,usr/bin,usr/share/applications,usr/share/icons/hicolor/256x256/apps}
echo "✓"

echo -n "Copying PKHeX build... "
cp -r "$publish_dir/"* "$app_dir/opt/pkhex/"
echo "✓"

echo -n "Copying metadata... "
cp pkhex.desktop "$app_dir/usr/share/applications/"
cp pkhex.desktop "$app_dir/pkhex.desktop"
cp icon.png "$app_dir/usr/share/icons/hicolor/256x256/apps/pkhex.png"
cp icon.png "$app_dir/pkhex.png"
cp AppRun "$app_dir/AppRun"
chmod +x "$app_dir/AppRun"
echo "✓"

echo -n "Bundling Wine... "
wine_bin="$(readlink -f "$(which wine)")"
wine_prefix="$(dirname "$wine_bin")/.."

wine_lib="$wine_prefix/lib/wine"
[ -L "$wine_lib" ] && wine_lib="$(readlink -f "$wine_lib")"

wine_share="$wine_prefix/share/wine"
[ -L "$wine_share" ] && wine_share="$(readlink -f "$wine_share")"

if [ ! -d "$wine_lib" ] || [ ! -d "$wine_share" ]; then
    echo "✗"
    echo "ERROR: Wine installation incomplete. lib=$wine_lib share=$wine_share"
    exit 1
fi

cp "$wine_bin" "$app_dir/usr/bin/wine"
mkdir -p "$app_dir/usr/lib/wine"
cp -a "$wine_lib/"* "$app_dir/usr/lib/wine/"
mkdir -p "$app_dir/usr/share/wine"
cp -a "$wine_share/"* "$app_dir/usr/share/wine/"
command -v wine64 &>/dev/null && cp "$(readlink -f "$(which wine64)")" "$app_dir/usr/bin/wine64" 2>/dev/null || true

lib_size="$(du -sh "$app_dir/usr/lib/wine" | cut -f1)"
data_size="$(du -sh "$app_dir/usr/share/wine" | cut -f1)"
echo "✓ ($lib_size libs + $data_size data)"

echo -n "Generating AppImage... "
ARCH=x86_64 appimagetool "$app_dir" PKHeX.AppImage >/dev/null 2>&1
echo "✓"

echo "AppImage generated successfully... ✓"
