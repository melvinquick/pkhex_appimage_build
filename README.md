# PKHeX Linux AppImage

Unofficial Linux AppImage packaging of [PKHeX](https://github.com/kwsch/PKHeX), the Pokémon core series save editor.

## Copyright & License Notices

PKHeX: Copyright (C) kwsch and contributors — https://github.com/kwsch/PKHeX  
Build Scripts: Copyright (C) 2026 Melvin Quick — AppImage packaging, Wine bundling, and build automation

- PKHeX is licensed under **GPL-3.0**. See [LICENSE-PKHeX](./LICENSE-PKHeX).
- Build scripts (`AppRun`, `build.sh`, `prepare_pkhex_source.sh`, `upgrade.sh`) are licensed under **MIT**. See [LICENSE](./LICENSE).
- Wine is bundled under its **LGPL** license. See https://winehq.org/about/lgpl

> **Unofficial community packaging.** This project is not affiliated with or endorsed by kwsch or the PKHeX development team. "PKHeX", "Pokémon", and related marks are trademarks of their respective owners. Please report PKHeX bugs to the [upstream repository](https://github.com/kwsch/PKHeX/issues), not here.

## Purpose

To provide a ready-to-run Linux AppImage of PKHeX that works out-of-the-box on modern distributions without requiring manual Wine setup, .NET installation, or path configuration.

## Problem

PKHeX officially ships only as a Windows `.exe` requiring .NET 10. Running it on Linux traditionally requires:

1. Installing Wine manually
2. Installing the correct .NET runtime version inside the Wine prefix

## Resolution

This project automates the entire process:

- Publishes PKHeX as a **self-contained .NET 10 win-x64** build (no external .NET dependency)
- Bundles a full Wine runtime (libraries + data files) inside the AppImage
- Extracts to a writable cache at runtime to bypass read-only AppImage mounts
- Patches PKHeX's `cfg.json` on every launch to redirect all resource paths (backups, plugins, databases, sounds, templates, trainers) to persistent user directories under `~/.config/pkhex_appimage/data/`
- Auto-detects the latest PKHeX release and rebuilds only when a new version is available

## Process

The build pipeline consists of three scripts:

1. **`prepare_pkhex_source.sh`** — Fetches the latest PKHeX tag from GitHub, clones the source, publishes a self-contained .NET 10 build, and records the version. Skips if already up-to-date.
2. **`build.sh`** — Creates the AppDir structure, copies the published build, bundles Wine libraries and data files, copies metadata, and generates the final AppImage using `appimagetool`.
3. **`upgrade.sh`** — Single entry point that runs prepare → conditionally builds. Handles version checking, old artifact cleanup, and reports status.

At runtime, **`AppRun`** handles:

- Wine prefix initialization (first run only)
- Extraction to `~/.cache/pkhex_appimage/extracted/` (writable copy)
- Patching `cfg.json` with absolute paths to `~/.config/pkhex_appimage/data/`
- Symlinking the backup directory for write access
- Launching PKHeX via bundled Wine

## User Data Locations

All persistent data lives outside the AppImage and survives updates:

| Path                                      | Contents                                   |
| :---------------------------------------- | :----------------------------------------- |
| `~/.config/pkhex_appimage/data/bak/`      | Save file backups                          |
| `~/.config/pkhex_appimage/data/plugins/`  | Plugin DLLs                                |
| `~/.config/pkhex_appimage/data/pkmdb/`    | PKM database                               |
| `~/.config/pkhex_appimage/data/mgdb/`     | Mystery Gift database                      |
| `~/.config/pkhex_appimage/data/sounds/`   | Sound effects                              |
| `~/.config/pkhex_appimage/data/template/` | Battle templates                           |
| `~/.config/pkhex_appimage/data/trainers/` | Trainer data                               |
| `~/.config/pkhex_appimage/wineprefix/`    | Wine prefix (reset to reinitialize)        |
| `~/.cache/pkhex_appimage/extracted/`      | Writable extraction cache (safe to delete) |

## Building From Source

### Prerequisites

- `wine` (system package)
- `appimagetool` (from AUR or GitHub releases)
- `git`, `wget`, `python3` (usually pre-installed)
- .NET 10 SDK (auto-installed by `prepare_pkhex_source.sh` if missing)

### Build Steps

```bash
git clone <this-repo-url>
cd pkhex_appimage_build
chmod +x *.sh
./upgrade.sh
```
