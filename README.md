# Obscura Installer for Termux

[Obscura](https://github.com/h4ckf0r0day/obscura) — a headless browser for AI agents and web scraping — packaged for Termux on Android.

This installer uses the **upstream glibc binary directly** from the official Obscura repository, with a lightweight glibc wrapper to ensure compatibility with Termux's Bionic environment.

## Quick Install

```bash
bash -c "$(curl -L https://raw.githubusercontent.com/zexjpg/obscura-termux-install/main/install-obscura.sh)"
```

## Uninstall

```bash
bash -c "$(curl -L https://raw.githubusercontent.com/zexjpg/obscura-termux-install/main/install-obscura.sh)" remove
```

## How It Works

Termux uses Android's Bionic C library, but Obscura's prebuilt binaries are compiled against glibc. This script solves the incompatibility by:

1. Downloading the official `obscura-aarch64-linux.tar.gz` from GitHub Releases
2. Installing the binaries to `$PREFIX/opt/obscura/`
3. Creating glibc wrapper scripts that use `ld-linux-aarch64.so.1` as the dynamic linker
4. Symlinking `obscura` and `obscura-worker` into `$PREFIX/bin/`

## Requirements

- **Termux** on Android (aarch64 / ARM64)
- **glibc** package installed:

```bash
pkg install glibc-repo
pkg install glibc
```

## Features

- **Auto-update**: detects installed vs latest version, skips if already up to date
- **One-command install**: single script, no extra dependencies beyond `curl` and `tar`
- **Clean uninstall**: `remove` argument cleans up everything

## Usage

```bash
# Check version
obscura -V

# Fetch a page and dump as markdown
obscura fetch https://example.com --dump text

# Start CDP server (Puppeteer / Playwright compatible)
obscura serve --port 9222

# Stealth mode
obscura --stealth fetch https://example.com
```

## Alternative

If you prefer a `.deb` package approach with bionic build support, see [zexjpg/obscura-termux](https://github.com/zexjpg/obscura-termux).

## License

This installer script is provided as-is. Obscura itself is developed by [h4ckf0r0day](https://github.com/h4ckf0r0day/obscura).
