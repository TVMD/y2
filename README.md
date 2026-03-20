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

### Prerequisites

- [yt-dlp](https://github.com/yt-dlp/yt-dlp)
- [ffmpeg](https://ffmpeg.org/)
- [Rust](https://rustup.rs/) (for building)

### One-liner

```sh
git clone https://github.com/TVMD/y2.git && cd y2 && ./install.sh
```

The install script handles everything — installs yt-dlp, ffmpeg, Rust (if needed), and builds `y2`.

### Manual

```sh
# macOS
brew install yt-dlp ffmpeg

# Ubuntu/Debian
sudo apt install ffmpeg
sudo curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
sudo chmod a+rx /usr/local/bin/yt-dlp

# Arch
sudo pacman -S ffmpeg yt-dlp
```

Then build:

```sh
cargo install --path .
```

## Supported URLs

- `https://www.youtube.com/watch?v=...`
- `https://youtu.be/...`
- `https://www.youtube.com/shorts/...`

## License

MIT
