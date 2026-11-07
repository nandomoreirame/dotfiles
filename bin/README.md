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
| `video-to-gif` | Convert a screen recording to GIF and copy its path | `video-to-gif [input.mp4] [output.gif]`; with no args, uses the newest `recording_*.mp4` under `$XDG_VIDEOS/Recordings` (or `~/Videos/Recordings`) | `ffmpeg`, `notify-send`, `wl-copy` | none |
| `espanso-hotplug` | Restart espanso after a keyboard is plugged in | `espanso-hotplug` (via udev + user unit) | `espanso`, `systemctl` | none (user systemd). Install the udev rule under `/etc/udev/rules.d/` and the unit under `~/.config/systemd/user/`. |
| `droidcam-ctl` | Connect or disconnect a DroidCam phone camera headless | `droidcam-ctl start` / `stop` | `droidcam-cli`, `notify-send` | none (talks to the phone on the local network) |
| `localsend-clip` | Send clipboard text to a LocalSend favorite on the LAN | `localsend-clip <favorite-alias>` | `curl`, `jq`, `openssl`, `wl-paste`, `notify-send` | none (sends clipboard text to a device on the local network) |
| `clean-claude-sessions` | Remove old Claude Code session files under the user home | `clean-claude-sessions [--help]` | `python3` | none (deletes session files under the user home) |
| `sys-clean-cache` | Interactive cache cleanup across pacman, docker, npm and more | `sys-clean-cache` (`--help` / `--list` / `--dry-run` / `--only <step>`) | `sudo`/`paccache`, `docker`, `npm`, `pnpm`, `cargo`, `uv`, `journalctl` (optional) | root for some steps |
| `sys-btrfs-backup` | Incremental OS backup to a remote host via btrfs send/receive | `sys-btrfs-backup` (`--dry-run` / `--help`); requires `BTRFS_BACKUP_HOST` and `BTRFS_BACKUP_DIR` | `btrfs`, `ssh` | **root**; contacts a remote host over SSH; deletes old snapshots on both sides (designed for a systemd timer) |

## Adding a helper

1. Put the script under `bin/sys/` or `bin/utils/` with a shebang and `chmod +x`.
2. Add `tests/unit/bin/<name>.bats` with English test names.
3. Add a row to the table above.
4. Run `bash tests/run-tests` and `bash scripts/public-check .`.

## Security

Every helper here is optional. The repository never invokes them; you run them yourself (or from a unit you install).

- `sys-btrfs-backup` runs as **root**, opens an **SSH** session to a remote host and **deletes** old btrfs snapshots on both sides. Set `BTRFS_BACKUP_HOST` and `BTRFS_BACKUP_DIR` yourself; there are no baked-in defaults. Use a dedicated SSH key and a restricted remote user.
- `sys-clean-cache` can call `sudo`/`paccache`, `docker`, package managers and `journalctl`. Some steps need root; review the printed command before confirming.
- `clean-claude-sessions` **deletes** Claude Code session files and each matching subagent directory under the user home. Prefer `--dry-run` first.
- `localsend-clip` sends **clipboard text** (often secrets) to a LocalSend favorite on the LAN over HTTPS. It pins the favorite's TLS certificate (`--cacert` of the verified peer PEM) and does not disable verification with `-k`. It opens no inbound ports.
- `droidcam-ctl` talks to a phone camera on the local network; it opens no inbound ports.
