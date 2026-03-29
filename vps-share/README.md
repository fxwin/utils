## What does this do?
In short: uploads a video (or any file) and immediately get a shareable URL:

```bash
share video.mp4
```

It uploads to a VPS directory served by nginx, copies the URL to your clipboard, and prints it to stdout so you can keep piping if you want.

Together with [llmpeg](../llmpeg/):

```bash
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
This requires a bit of setting up, but it's not too difficult. Note that the share script itself is powershell and hence only works on Windows due to the success/error popup created.
### Prerequisites:
- A VPS + registered domain pointing at said VPS (Should work with just IP, but it looks nicer with a proper domain)
- A ssh profile that connects to your VPS
- Local Linux machine with `ssh`/`scp`
- Clipboard helper: `wl-copy` recommended (Wayland), fallback supported for `xclip`/`xsel`
- Notification helper: `kdialog` preferred on KDE, fallback to `notify-send`

Fedora install:

```bash
sudo dnf install openssh-clients wl-clipboard kdialog libnotify
```

### VPS Setup:
1. Choose a directory to put the files in - in my case that's `/srv/videos/public`
2. Choose a base URL to serve these under - in my case that's `https://videos.fxwin.net/raw`
3. Set up nginx to expose the directory from step 1 under the URL in step 2. In my case, this looks something like this (With some extra stuff to support https and to enable live playback in the browser, e.g. without ``add_header Content-Disposition "inline" always;`` opening a link simply downloads the video instead. Consult your favorite LLM on how to set up certificate, i used certbot + letsencrypt):
    ```nginx
    server {

        listen 443 ssl http2;
        listen [::]:443 ssl http2;
        server_name videos.fxwin.net;
        client_max_body_size 2G;

        ssl_certificate     /etc/letsencrypt/live/videos.fxwin.net/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/videos.fxwin.net/privkey.pem;


        location ^~ /raw/ {
            alias /srv/videos/public/;
            autoindex off;

            # prefer inline display; browser decides
            add_header Content-Disposition "inline" always;

            # seeking/streaming
            add_header Accept-Ranges bytes always;
        }
    }
    ```
4. I recommend setting up a file browser that lets you access/delete/rename files after uploading without having to `ssh` into your VPS, I use [File Browser](https://github.com/filebrowser/filebrowser) which is super easy to self host on the same VPS.

### Local Linux setup (zsh)
1. Install scripts to user-local bin:

   ```bash
   mkdir -p ~/.local/bin
   cp video-share ~/.local/bin/video-share
   cp share ~/.local/bin/share
   chmod +x ~/.local/bin/video-share
   chmod +x ~/.local/bin/share
   ```

2. Add config to `~/.zshrc`:

   ```bash
   export PATH="$HOME/.local/bin:$PATH"

   export SHARE_SSH_HOST_ALIAS="fxwin-vps"
   export SHARE_REMOTE_DIR="/srv/videos/public"
   export SHARE_BASE_URL="https://videos.fxwin.net/raw"
   ```

3. Reload shell:

   ```bash
   source ~/.zshrc
   ```

### Right-click menu in Dolphin (Plasma 6.6.3)
You can install the service menu template included in this folder:

```bash
chmod +x install-dolphin-service-menu
./install-dolphin-service-menu
```

This installs to both paths:
- `~/.local/share/kio/servicemenus` (Plasma 6)
- `~/.local/share/kservices5/ServiceMenus` (Plasma 5 fallback)

If it does not show up immediately:

```bash
kbuildsycoca6
killall dolphin
dolphin &
```

## Notes
- The script checks SSH connectivity + remote directory writability before upload.
- URL is always printed to stdout so piping stays clean.
- On success it tries to copy to clipboard (`wl-copy` -> `xclip` -> `xsel`) and shows a desktop notification.

## Troubleshooting
If Dolphin shows "you are not authorized to execute this file" when clicking the menu entry:

```bash
chmod +x ~/.local/bin/video-share
chmod +x ~/.local/share/kio/servicemenus/video-share.desktop
chmod +x ~/.local/share/kservices5/ServiceMenus/video-share.desktop
kbuildsycoca6
killall dolphin
dolphin &
```