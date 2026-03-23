# y2

A clipboard-watching CLI tool that automatically downloads YouTube videos as MP3 files.

## How It Works

1. Run `y2` with a destination directory
2. Copy any YouTube link to your clipboard
3. The MP3 downloads automatically and the clipboard is cleared
4. Repeat — copy another link, it downloads again
5. Press `Ctrl+C` to stop

## Usage

```
y2 -d ~/Music
```

## Installation

### Option 1: Install script (recommended)

Downloads a prebuilt binary — no Rust required. The script also installs the runtime dependencies (yt-dlp and ffmpeg) for you.

```sh
curl -fsSL https://raw.githubusercontent.com/TVMD/y2/main/install.sh | bash
```

Or clone and run locally:

```sh
git clone https://github.com/TVMD/y2.git && cd y2 && ./install.sh
```

### Option 2: Build from source

Requires [Rust](https://rustup.rs/) toolchain. You still need yt-dlp and ffmpeg installed.

```sh
# Install dependencies
# macOS
brew install yt-dlp ffmpeg
# Ubuntu/Debian
sudo apt install ffmpeg && sudo curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp && sudo chmod a+rx /usr/local/bin/yt-dlp
# Arch
sudo pacman -S ffmpeg yt-dlp

# Build and install
git clone https://github.com/TVMD/y2.git && cd y2
cargo install --path .
```

## Supported URLs

- `https://www.youtube.com/watch?v=...`
- `https://youtu.be/...`
- `https://www.youtube.com/shorts/...`

## Behavior

### Queueing

Downloads run one at a time. If you copy a new link while a download is in progress, it will be picked up automatically once the current download finishes. You don't need to wait — just keep copying links and they will be processed in order.

### Playlist links

If you copy a link that contains a playlist parameter (e.g. `watch?v=xxx&list=yyy`), only the single video in the URL is downloaded, not the entire playlist.

## License

MIT
