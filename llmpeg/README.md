## What does this do?
This generates + executes a ``ffmpeg`` command to process a video file based on natural language description using a LLM:
```bash
llmpeg "Cut off the first and last 5 seconds of this video" "./video.mp4"
```
Flags:
- `-Smart` uses `gpt-5-mini` instead of `gpt-4.1`. Significantly slower but more reliably with complex queries.
- `-DryRun` just provides the command, but doesn't execute it.
## Why?
Since ~GPT 4, one of my recurring use cases (next to generating + understanding regex) for ChatGPT was to write one-off ``ffmpeg`` commands to crop short video clips. This script streamlines this + integrates nicely with the [share](../vps-share/README.md)-command to process + upload a given video to get a shareable link within seconds.

## Setup
Note that this is a powershell script so it is Windows only, but any frontier LLM should be able to 1 shot a port to the scripting language of your choice. I just used powershell because I made this at the same time as [share](../vps-share/README.md), where i use Windows specific features.
### Prerequisites:
- An [Openai](https://developers.openai.com/) API key stored in `OPENAI_API_KEY`
- A working [ffmpeg](https://www.ffmpeg.org/download.html) installation
### Setup
1. Copy [llmpeg.ps1](llmpeg.ps1) to `C:\Tools`
2. Add the following to your shell profile, e.g. via `notepad $PROFILE`:
    ```ps
    function llmpeg {
        param(
            [Parameter(Mandatory=$true)]
            [string]$Instruction,

            [Parameter(Mandatory=$true)]
            [string]$Path,

            [switch]$DryRun,

            [switch]$Smart
        )

        & "C:\Tools\llmpeg.ps1" `
            -Instruction $Instruction `
            -Path $Path `
            -DryRun:$DryRun `
            -Smart:$Smart
    }
    ```