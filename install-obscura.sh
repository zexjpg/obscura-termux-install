#!/data/data/com.termux/files/usr/bin/bash
#
# Obscura Installer/Updater for Termux
# https://github.com/h4ckf0r0day/obscura
#
# Usage:
#   bash install-obscura.sh          # install or update
#   bash install-obscura.sh remove   # uninstall
#

set -euo pipefail

REPO="h4ckf0r0day/obscura"
INSTALL_DIR="$PREFIX/opt/obscura"
BIN_DIR="$PREFIX/bin"
CURRENT_VERSION_FILE="$INSTALL_DIR/.version"
ARCH="aarch64"
GLIBC_DIR="$PREFIX/glibc/lib"
GLIBC_LOADER="$GLIBC_DIR/ld-linux-aarch64.so.1"
WRAPPER_BIN="$INSTALL_DIR/obscura-wrapper"
WRAPPER_WORKER="$INSTALL_DIR/obscura-worker-wrapper"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()   { echo -e "${RED}[ERROR]${NC} $*"; }

check_deps() {
    local missing=0
    for cmd in curl tar; do
        if ! command -v "$cmd" &>/dev/null; then
            err "Missing dependency: $cmd"
            missing=1
        fi
    done
    if [ "$missing" -eq 1 ]; then
        info "Installing missing dependencies..."
        pkg install -y curl tar 2>/dev/null || {
            err "Failed to install dependencies. Run: pkg install -y curl tar"
            exit 1
        }
    fi
}

check_arch() {
    local machine
    machine=$(uname -m)
    if [ "$machine" != "aarch64" ]; then
        err "Unsupported architecture: $machine (obscura only supports aarch64 on Linux)"
        exit 1
    fi
}

check_glibc() {
    if [ ! -f "$GLIBC_LOADER" ]; then
        err "glibc not found at $GLIBC_DIR"
        info "Install glibc first:"
        info "  pkg install glibc-repo && pkg install glibc"
        exit 1
    fi
}

get_latest_version() {
    curl -sL "https://api.github.com/repos/$REPO/releases/latest" \
        | grep '"tag_name"' | sed 's/.*"tag_name": *"//;s/".*//'
}

get_installed_version() {
    if [ -f "$CURRENT_VERSION_FILE" ]; then
        cat "$CURRENT_VERSION_FILE"
    else
        echo ""
    fi
}

download_release() {
    local version="$1"
    local filename="obscura-${ARCH}-linux.tar.gz"
    local url="https://github.com/$REPO/releases/download/${version}/${filename}"
    local tmp_dir
    tmp_dir=$(mktemp -d)

    info "Downloading obscura ${version}..." >&2
    if ! curl -sL --progress-bar -o "$tmp_dir/$filename" "$url"; then
        err "Download failed. Check your network connection." >&2
        rm -rf "$tmp_dir"
        exit 1
    fi

    info "Extracting..." >&2
    if ! tar xzf "$tmp_dir/$filename" -C "$tmp_dir"; then
        err "Extraction failed." >&2
        rm -rf "$tmp_dir"
        exit 1
    fi

    if [ ! -f "$tmp_dir/obscura" ] || [ ! -f "$tmp_dir/obscura-worker" ]; then
        err "Invalid archive: missing obscura or obscura-worker binary" >&2
        rm -rf "$tmp_dir"
        exit 1
    fi

    echo "$tmp_dir"
}

create_wrappers() {
    cat > "$WRAPPER_BIN" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
GLIBC=__GLIBC_DIR__
unset LD_PRELOAD
export LD_LIBRARY_PATH="$GLIBC"
export LD_BIND_NOW=1
exec "$GLIBC/ld-linux-aarch64.so.1" --library-path "$GLIBC" __INSTALL_DIR__/obscura "$@"
EOF
    sed -i "s|__GLIBC_DIR__|$GLIBC_DIR|g; s|__INSTALL_DIR__|$INSTALL_DIR|g" "$WRAPPER_BIN"
    chmod +x "$WRAPPER_BIN"

    cat > "$WRAPPER_WORKER" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
GLIBC=__GLIBC_DIR__
unset LD_PRELOAD
export LD_LIBRARY_PATH="$GLIBC"
export LD_BIND_NOW=1
exec "$GLIBC/ld-linux-aarch64.so.1" --library-path "$GLIBC" __INSTALL_DIR__/obscura-worker "$@"
EOF
    sed -i "s|__GLIBC_DIR__|$GLIBC_DIR|g; s|__INSTALL_DIR__|$INSTALL_DIR|g" "$WRAPPER_WORKER"
    chmod +x "$WRAPPER_WORKER"
}

create_symlinks() {
    ln -sf "$WRAPPER_BIN" "$BIN_DIR/obscura"
    ln -sf "$WRAPPER_WORKER" "$BIN_DIR/obscura-worker"
}

verify_install() {
    local output
    output=$("$BIN_DIR/obscura" -V 2>&1) || {
        err "Verification failed: $output"
        return 1
    }
    ok "obscura $output is ready"
}

do_install() {
    local version="$1"
    local tmp_dir="$2"

    mkdir -p "$INSTALL_DIR"
    cp "$tmp_dir/obscura" "$INSTALL_DIR/obscura"
    cp "$tmp_dir/obscura-worker" "$INSTALL_DIR/obscura-worker"
    chmod +x "$INSTALL_DIR/obscura" "$INSTALL_DIR/obscura-worker"

    create_wrappers
    create_symlinks
    echo "$version" > "$CURRENT_VERSION_FILE"
}

do_remove() {
    info "Removing obscura..."
    rm -f "$BIN_DIR/obscura" "$BIN_DIR/obscura-worker"
    rm -rf "$INSTALL_DIR"
    ok "Obscura removed"
}

main() {
    if [ "${1:-}" = "remove" ]; then
        do_remove
        exit 0
    fi

    echo -e "${CYAN}╔══════════════════════════════════╗${NC}"
    echo -e "${CYAN}║   Obscura Installer (Termux)     ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════╝${NC}"
    echo

    check_deps
    check_arch
    check_glibc

    local latest installed
    latest=$(get_latest_version)
    if [ -z "$latest" ]; then
        err "Failed to fetch latest version from GitHub"
        exit 1
    fi
    ok "Latest version: $latest"

    installed=$(get_installed_version)

    if [ "$installed" = "$latest" ]; then
        ok "Already up to date ($installed)"
        verify_install
        exit 0
    fi

    if [ -n "$installed" ]; then
        info "Updating: $installed -> $latest"
    else
        info "Installing: $latest"
    fi

    local tmp_dir
    tmp_dir=$(download_release "$latest")

    do_install "$latest" "$tmp_dir"
    rm -rf "$tmp_dir"

    verify_install

    echo
    ok "Done! Usage:"
    echo "  obscura -V                                    # check version"
    echo "  obscura fetch https://example.com --dump text # fetch a page"
    echo "  obscura serve --port 9222                     # start CDP server"
    echo "  obscura --stealth fetch <url>                 # anti-detection mode"
}

main "$@"
