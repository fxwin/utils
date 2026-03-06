## What does this do?
In short: it uploads videos and provides me with a shareable link via 
``` bash
share video.mp4
```
by copying the video into a directory on my VPS that is exposed by nginx, and copying an URL to said video into my clipboard. Also available as an entry in the "Send to" context menu.

Together with the [llmpeg](../llmpeg/) script, i can even do:
```
llmpeg "Crop this video to 30 seconds starting at 12 seconds" video.mp4 | share
``` 
## Why?
I play videogames, and sometimes record gameplay clips using e.g. NVIDIA Shadowplay that i want to share with my friends. The usual "workflow" for this goes something like this: 
1. Crop video (e.g. using `ffmpeg` or a video editor of your choice)
2. Find filehoster, ideally with an embedded video player, e.g. streamable
3. Upload file
4. Share link with friends

That's nice, but: videos usually get deleted after a while unless you pay, and the linked video page might still contain ads if (god beware) the person you send it to doesn't use an ad blocker. That's also still too many clicks for me.

## Setup
This requires a bit of setting up, but it's not too difficult. Note that the share script itself is powershell and hence only works on Windows due to the BalloonTip API used for popup notification once upload finishes.
### Prerequisites:
- A VPS + registered domain pointing at said VPS (Should work with just IP, but it looks nicer with a proper domain)
- A ssh profile that connects to your VPS
- A Windows machine to upload from (sorry)
### VPS Setup:
1. Choose a directory to put the files in - in my case that's `/srv/videos/public`
2. Choose a base URL to serve these under - in my case that's `https://videos.fxwin.net/raw`
3. Set up nginx to expose the directory from step 1 under the URL in step 2. In my case, this looks something like this (With some extra stuff to support https and to enable live playback in the browser, e.g. without ``add_header Content-Disposition "inline" always;`` opening a link simply downloads the video instead. Consult your favorite LLM on how to set up certificate, i used certbot + letsencrypt). If you want, you can add additional file types to serve them here, my main use case is videos so `.mp4` it is):
    ```nginx
    server {

        listen 443 ssl http2;
        listen [::]:443 ssl http2;
        server_name videos.fxwin.net;
        client_max_body_size 2G;

        ssl_certificate     /etc/letsencrypt/live/videos.fxwin.net/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/videos.fxwin.net/privkey.pem;

        types { mp4 video/mp4; }

    location ^~ /raw/ {
        alias /srv/videos/public/;
        autoindex off;

        # make sure mp4 is served/seekable
        mp4;

        types { mp4 video/mp4; }
        default_type video/mp4;

        add_header Content-Disposition "inline" always;
        add_header Accept-Ranges bytes always;
    }
    ```
4. I recommend setting up a file browser that lets you access/delete/rename files after uploading without having to `ssh` into your VPS, I use [File Browser](https://github.com/filebrowser/filebrowser) which is super easy to self host on the same VPS.

### Local/Windows Setup:
1. Copy [video-share.ps1](video-share.ps1) and [video-share.vbs](video-share.vbs) to `C:\Tools`
2. In [video-share.ps1](video-share.ps1), replace the value of the variable `$HostAlias` with the name of the ssh profile connecting to your VPS, and `$RemoteDir, $BaseUrl` with the corresponding values from VPS setup steps 1 and 2
3. Add the following snippet to your shell profile (e.g. via `notepad $PROFILE`):
    ```ps
    function share {
        param(
            [Parameter(ValueFromPipeline=$true)]
            [string]$Path
        )
        process {
            if ([string]::IsNullOrWhiteSpace($Path)) { return }
            $Path = $Path.Trim()

            if (-not (Test-Path -LiteralPath $Path)) { return }

            & "C:\Tools\share-video.ps1" $Path
        }
    }
    ```
4. If you also want this added to the right click menu, press `Win+R`, type `shell:sendto` and create a shortcut there named `Share via VPS` with the target: 
    ```ps
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Tools\share-video.ps1"
    ```