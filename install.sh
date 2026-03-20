#!/usr/bin/env bash
set -e

echo "=== y2 - YouTube MP3 Clipboard Downloader ==="
echo ""

# Detect OS
OS="$(uname -s)"
ARCH="$(uname -m)"

install_mac() {
    # Check for Homebrew
    if ! command -v brew &>/dev/null; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    echo "Installing dependencies via Homebrew..."
    brew install yt-dlp ffmpeg 2>/dev/null || brew upgrade yt-dlp ffmpeg 2>/dev/null || true
}

install_linux() {
    if command -v apt-get &>/dev/null; then
        echo "Installing dependencies via apt..."
        sudo apt-get update -qq
        sudo apt-get install -y ffmpeg
        sudo curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
        sudo chmod a+rx /usr/local/bin/yt-dlp
    elif command -v dnf &>/dev/null; then
        echo "Installing dependencies via dnf..."
        sudo dnf install -y ffmpeg
        sudo curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
        sudo chmod a+rx /usr/local/bin/yt-dlp
    elif command -v pacman &>/dev/null; then
        echo "Installing dependencies via pacman..."
        sudo pacman -S --noconfirm ffmpeg yt-dlp
    else
        echo "Error: Could not detect package manager (apt/dnf/pacman)."
        echo "Please install ffmpeg and yt-dlp manually."
        exit 1
    fi
}

# Install system dependencies
echo "[1/3] Installing system dependencies (yt-dlp, ffmpeg)..."
case "$OS" in
    Darwin) install_mac ;;
    Linux)  install_linux ;;
    *)
        echo "Error: Unsupported OS: $OS"
        exit 1
        ;;
esac

# Install Rust if needed
echo ""
echo "[2/3] Checking Rust toolchain..."
if ! command -v cargo &>/dev/null; then
    echo "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
else
    echo "Rust already installed."
fi

# Build and install y2
echo ""
echo "[3/3] Building and installing y2..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cargo install --path "$SCRIPT_DIR"

echo ""
echo "=== Installation complete! ==="
echo ""
echo "Usage:"
echo "  y2 -d ~/Downloads"
echo ""
echo "Copy any YouTube link and it downloads as MP3 automatically."
echo "Press Ctrl+C to stop."
