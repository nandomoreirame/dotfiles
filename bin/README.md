# Helper scripts

Optional helpers under `bin/sys/` and `bin/utils/`. Nothing here is required by the rest of the repository; each script is standalone and covered by its own BATS file.

## PATH

Add the helper directories to your PATH (replace the clone path as needed):

```bash
export PATH="$PATH:/path/to/dotfiles/bin/sys:/path/to/dotfiles/bin/utils"
# or, when DOTFILES points at the clone:
export PATH="$PATH:$DOTFILES/bin/sys:$DOTFILES/bin/utils"
```

## Helpers

| Helper | Purpose | Usage | Needs | Privileges |
|---|---|---|---|---|
| `notify-open` | Notify about a file and open, reveal or trash it on click | `notify-open [-a app] <summary> <file> [body]` | `notify-send`, `xdg-open`, `gio` (optional `nautilus`) | none |
| `video-to-gif` | Convert a screen recording to GIF and copy its path | `video-to-gif [input.mp4] [output.gif]` | `ffmpeg`, `notify-send`, `wl-copy` | none |
| `espanso-hotplug` | Restart espanso after a keyboard is plugged in | `espanso-hotplug` (via udev + user unit) | `espanso`, `systemctl` | none (user systemd). Install the udev rule under `/etc/udev/rules.d/` and the unit under `~/.config/systemd/user/`. |
| `droidcam-ctl` | Connect or disconnect a DroidCam phone camera headless | `droidcam-ctl start` / `stop` | `droidcam-cli`, `notify-send` | none (talks to the phone on the local network) |
| `localsend-clip` | Send clipboard text to a LocalSend favorite on the LAN | `localsend-clip <favorite-alias>` | `curl`, `jq`, `openssl`, `wl-paste`, `notify-send` | none (sends clipboard text to a device on the local network) |
