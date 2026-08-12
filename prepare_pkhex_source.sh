#!/bin/bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_url="https://github.com/kwsch/PKHeX.git"
publish_output="$script_dir/pkhex_publish_output"
version_file="$publish_output/.pkhex_version"

normalize_version() {
    echo "$1" | awk -F. '{printf "%d.%02d.%02d", $1, $2, $3}'
}

echo -n "Fetching latest PKHeX version... "
latest_version="$(git ls-remote --tags "$repo_url" 2>/dev/null \
    | grep -oP 'refs/tags/\K[0-9]+\.[0-9]+\.[0-9]+$' \
    | sort -V | tail -1)"

if [ -z "$latest_version" ]; then
    echo "✗"
    echo "ERROR: Could not determine latest version from $repo_url"
    exit 2
fi
latest_version="$(normalize_version "$latest_version")"
echo "✓ ($latest_version)"

# * Create baseline version file if it doesn't exist and PKHeX.exe is present
if [ ! -f "$version_file" ] && [ -f "$publish_output/PKHeX.exe" ]; then
    echo -n "Creating baseline from existing build... "
    existing_ver="$(strings "$publish_output/PKHeX.dll" 2>/dev/null \
        | grep -oP '^\d+\.\d+\.\d+\.\d+$' | head -1 | cut -d. -f1-3)"
    if [ -n "$existing_ver" ]; then
        normalize_version "$existing_ver" > "$version_file"
        echo "✓ ($(cat "$version_file"))"
    else
        echo "✗ (could not infer)"
    fi
fi

# * Check if already current AND AppImage exists
if [ -f "$version_file" ] && [ "$(cat "$version_file")" = "$latest_version" ]; then
    if [ -f "$script_dir/PKHeX.AppImage" ]; then
        echo "Already up-to-date, no rebuild needed... ✓"
        exit 1
    fi
    echo "Version matches but AppImage missing, rebuild needed... ✓"
else
    echo "New version detected ($(cat "$version_file" 2>/dev/null || echo 'none') → $latest_version)... ✓"
fi

# * Clean old publish output
echo -n "Cleaning old artifacts... "
rm -rf "$publish_output" 2>/dev/null || true
echo "✓"

# * Clone first so we can detect the required .NET version
echo -n "Cloning PKHeX $latest_version... "
rm -rf "$script_dir/PKHeX"
git clone --depth 1 --branch "$latest_version" "$repo_url" "$script_dir/PKHeX" >/dev/null 2>&1
echo "✓"

# * Detect required .NET version from PKHeX source
echo -n "Detecting target framework... "
csproj="$script_dir/PKHeX/PKHeX.WinForms/PKHeX.WinForms.csproj"
target_tfm="$(grep -oP '<TargetFramework>\K[^<]+' "$csproj" | head -1)"

if [ -z "$target_tfm" ]; then
    echo "✗"
    echo "ERROR: Could not detect TargetFramework from $csproj"
    exit 2
fi

required_major="$(echo "$target_tfm" | grep -oP 'net\K[0-9]+')"
echo "✓ ($target_tfm)"

# * Ensure the exact required .NET SDK is installed
echo -n "Checking .NET SDK... "
if [ -x "$HOME/.dotnet/dotnet" ]; then
    export PATH="$HOME/.dotnet:$PATH"
fi

installed_major="$(dotnet --version 2>/dev/null | cut -d. -f1 || echo 0)"

if [ "$required_major" != "$installed_major" ]; then
    echo "↻ (installing .NET $required_major.0)"
    wget -q https://dot.net/v1/dotnet-install.sh -O /tmp/dotnet-install.sh
    chmod +x /tmp/dotnet-install.sh
    /tmp/dotnet-install.sh --channel "$required_major.0" --install-dir "$HOME/.dotnet" >/dev/null 2>&1
    export PATH="$HOME/.dotnet:$PATH"
    rm -f /tmp/dotnet-install.sh
    installed_major="$(dotnet --version 2>/dev/null | cut -d. -f1 || echo 0)"
    if [ "$required_major" != "$installed_major" ]; then
        echo "✗"
        echo "ERROR: Failed to install .NET $required_major.0"
        exit 2
    fi
    echo "  .NET SDK ready ($(dotnet --version))"
else
fi

echo -n "Publishing self-contained build... "
dotnet publish "$script_dir/PKHeX/PKHeX.WinForms/PKHeX.WinForms.csproj" \
    -c Release -r win-x64 --self-contained true \
    /p:PublishSingleFile=false -o "$publish_output/" >/dev/null 2>&1
echo "$latest_version" > "$version_file"
echo "✓"

echo -n "Cleaning source tree... "
rm -rf "$script_dir/PKHeX"
echo "✓"

echo "PKHeX $latest_version ready for build... ✓"
exit 0
