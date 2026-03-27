use std::collections::VecDeque;
use std::path::PathBuf;
use std::process::Stdio;
use std::sync::Arc;
use std::time::Duration;

use arboard::Clipboard;
use clap::Parser;
use regex::Regex;
use tokio::sync::Mutex;

#[derive(Parser)]
#[command(name = "y2", about = "YouTube to MP3 clipboard watcher")]
struct Cli {
    /// Destination directory for downloaded MP3 files
    #[arg(short = 'd')]
    dest: PathBuf,

    /// Use cookies from browser to avoid bot detection (e.g. chrome, firefox, safari, edge)
    #[arg(short = 'c', long = "cookies", default_value = "chrome")]
    browser: String,

    /// Disable browser cookies
    #[arg(long = "no-cookies", default_value_t = false)]
    no_cookies: bool,

    /// Max number of songs to download per playlist URL
    #[arg(long = "max")]
    max: Option<u32>,
}

fn is_youtube_url(text: &str) -> bool {
    let re = Regex::new(
        r"(?:https?://)?(?:www\.)?(?:youtube\.com/watch\?v=|youtu\.be/|youtube\.com/shorts/)[\w\-]+"
    ).unwrap();
    re.is_match(text.trim())
}

async fn download_mp3(url: &str, dest: &PathBuf, browser: &str, use_cookies: bool, max: Option<u32>) -> Result<(), String> {
    let output_template = dest.join("%(title)s.%(ext)s").to_string_lossy().to_string();

    let mut args = vec![
        "--no-check-certificates".to_string(),
        "-x".to_string(),
        "--audio-format".to_string(), "mp3".to_string(),
        "-o".to_string(), output_template,
    ];

    if use_cookies {
        args.push("--cookies-from-browser".to_string());
        args.push(browser.to_string());
    }

    if let Some(max) = max {
        args.push("--playlist-end".to_string());
        args.push(max.to_string());
    }

    args.push(url.to_string());

    let mut child = tokio::process::Command::new("yt-dlp")
        .args(&args)
        .stdout(Stdio::inherit())
        .stderr(Stdio::inherit())
        .spawn()
        .map_err(|e| format!("Failed to run yt-dlp: {}. Is yt-dlp installed?", e))?;

    let status = child.wait().await.map_err(|e| format!("yt-dlp process error: {}", e))?;

    if status.success() {
        Ok(())
    } else {
        Err(format!("yt-dlp exited with status: {}", status))
    }
}

#[tokio::main]
async fn main() {
    let cli = Cli::parse();
    let dest = cli.dest;
    let browser = cli.browser;
    let use_cookies = !cli.no_cookies;
    let max = cli.max;

    if !dest.exists() {
        std::fs::create_dir_all(&dest).expect("Failed to create destination directory");
    }

    println!("y2 - YouTube MP3 Downloader");
    if use_cookies {
        println!("Using cookies from: {}", browser);
    }
    if let Some(max) = max {
        println!("Max songs per playlist: {}", max);
    }
    println!("Watching clipboard... (Ctrl+C to stop)");
    println!("Download directory: {}", dest.display());

    let queue: Arc<Mutex<VecDeque<String>>> = Arc::new(Mutex::new(VecDeque::new()));
    let queue_watcher = Arc::clone(&queue);

    // Clipboard watcher task — always running
    tokio::spawn(async move {
        let mut clipboard = Clipboard::new().expect("Failed to access clipboard");
        let mut last_url = String::new();

        loop {
            if let Ok(text) = clipboard.get_text() {
                let text = text.trim().to_string();
                if is_youtube_url(&text) && text != last_url {
                    last_url = text.clone();
                    let mut q = queue_watcher.lock().await;
                    if !q.contains(&text) {
                        println!("\nQueued: {}", text);
                        q.push_back(text);
                        // Clear clipboard immediately
                        let _ = clipboard.set_text("");
                    }
                }
            }
            tokio::time::sleep(Duration::from_secs(1)).await;
        }
    });

    // Download loop — processes queue one at a time
    loop {
        let url = {
            let mut q = queue.lock().await;
            q.pop_front()
        };

        if let Some(url) = url {
            let remaining = queue.lock().await.len();
            if remaining > 0 {
                println!("Downloading: {} ({} more in queue)", url, remaining);
            } else {
                println!("Downloading: {}", url);
            }

            match download_mp3(&url, &dest, &browser, use_cookies, max).await {
                Ok(()) => {
                    println!("Download complete!");
                }
                Err(e) => {
                    eprintln!("Download failed: {}", e);
                }
            }
        } else {
            tokio::time::sleep(Duration::from_millis(500)).await;
        }
    }
}
