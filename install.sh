#!/usr/bin/env bash
set -e

REPO="TVMD/y2"
INSTALL_DIR="/usr/local/bin"

echo "=== y2 - YouTube MP3 Clipboard Downloader ==="
echo ""

OS="$(uname -s)"
ARCH="$(uname -m)"

# --- Step 1: Install runtime deps (yt-dlp, ffmpeg) ---

install_deps_mac() {
    if ! command -v brew &>/dev/null; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    echo "Installing yt-dlp and ffmpeg via Homebrew..."
    brew install yt-dlp ffmpeg 2>/dev/null || brew upgrade yt-dlp ffmpeg 2>/dev/null || true
}

install_deps_linux() {
    if command -v apt-get &>/dev/null; then
        sudo apt-get update -qq
        sudo apt-get install -y ffmpeg
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y ffmpeg
    elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm ffmpeg yt-dlp
    else
        echo "Error: Could not detect package manager. Install ffmpeg and yt-dlp manually."
        exit 1
    fi

    # Install/update yt-dlp binary (pacman handles its own)
    if ! command -v pacman &>/dev/null; then
        echo "Installing yt-dlp..."
        sudo curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
        sudo chmod a+rx /usr/local/bin/yt-dlp
    fi
}

echo "[1/2] Installing dependencies (yt-dlp, ffmpeg)..."
case "$OS" in
    Darwin) install_deps_mac ;;
    Linux)  install_deps_linux ;;
    *)
        echo "Error: Unsupported OS: $OS"
        exit 1
        ;;
esac

# --- Step 2: Download prebuilt y2 binary ---

echo ""
echo "[2/2] Installing y2..."

# Determine binary name
case "$OS" in
    Darwin)
        case "$ARCH" in
            arm64)  BINARY="y2-macos-arm64" ;;
            x86_64) BINARY="y2-macos-x86_64" ;;
            *) echo "Error: Unsupported architecture: $ARCH"; exit 1 ;;
        esac
        ;;
    Linux)
        case "$ARCH" in
            x86_64)  BINARY="y2-linux-x86_64" ;;
            aarch64) BINARY="y2-linux-arm64" ;;
            *) echo "Error: Unsupported architecture: $ARCH"; exit 1 ;;
        esac
        ;;
esac

# Get latest release tag
LATEST=$(curl -sI "https://github.com/$REPO/releases/latest" | grep -i "^location:" | sed 's/.*tag\///' | tr -d '\r\n')

if [ -z "$LATEST" ]; then
    echo "Could not find prebuilt release. Falling back to building from source..."
    if ! command -v cargo &>/dev/null; then
        echo "Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    cargo install --path "$SCRIPT_DIR"
else
    URL="https://github.com/$REPO/releases/download/$LATEST/$BINARY.tar.gz"
    echo "Downloading $BINARY ($LATEST)..."

    TMP=$(mktemp -d)
    curl -sL "$URL" -o "$TMP/y2.tar.gz"
    tar xzf "$TMP/y2.tar.gz" -C "$TMP"

    if [ -w "$INSTALL_DIR" ]; then
        mv "$TMP/y2" "$INSTALL_DIR/y2"
    else
        sudo mv "$TMP/y2" "$INSTALL_DIR/y2"
    fi
    chmod +x "$INSTALL_DIR/y2"
    rm -rf "$TMP"

    echo "Installed y2 to $INSTALL_DIR/y2"
fi

echo ""
echo "=== Installation complete! ==="
echo ""
echo "Usage:"
echo "  y2 -d ~/Downloads"
echo ""
echo "Copy any YouTube link and it downloads as MP3 automatically."
echo "Press Ctrl+C to stop."
