## What does this do?
This generates + executes an `ffmpeg` command from plain English via OpenAI:

```bash
llmpeg "Cut off the first and last 5 seconds of this video" "./video.mp4"
```

It also works nicely with [share](../vps-share/) for one-liners like:

```bash
llmpeg "crop this to 30 seconds starting at 12s" "./clip.mp4" | share
```

Flags:
- `-s` / `--smart` (also accepts `-Smart`) uses `gpt-5-mini` instead of `gpt-4.1`. Significantly slower but worth for more complex commands.
- `-d` / `--dry-run` (also accepts `-DryRun`) prints only the output filename and skips ffmpeg execution

## Why?
Since ~GPT 4, one of my recurring use cases (next to generating + understanding regex) for ChatGPT was to write one-off ffmpeg commands to crop short video clips. This script streamlines this + integrates nicely with the [share](../vps-share/)-command to process + upload a given video to get a shareable link within seconds.

## Setup (Fedora)
### Prerequisites
- `ffmpeg`, `curl`, `jq`
- OpenAI API key in `OPENAI_API_KEY`

Fedora install:

```bash
sudo dnf install ffmpeg curl jq
```

### Install
1. Copy [llmpeg](llmpeg) into your user-local bin and make it executable:

    ```bash
    mkdir -p ~/.local/bin
    cp llmpeg ~/.local/bin/llmpeg
    chmod +x ~/.local/bin/llmpeg
    ```

2. Add this to `~/.zshrc` (your default shell):

    ```bash
    export PATH="$HOME/.local/bin:$PATH"
    export OPENAI_API_KEY="your_api_key_here"
    ```

3. Reload shell:

    ```bash
    source ~/.zshrc
    ```

### Usage
```bash
llmpeg "cut first and last 5 seconds" "./video.mp4"
llmpeg --dry-run "remove audio" "./video.mp4"
llmpeg --smart "burn subtitles from subs.srt" "./video.mp4"
```
