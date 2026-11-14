#!/usr/bin/env bash
# Configure rootless Podman storage with fuse-overlayfs on btrfs/zfs.
set -eo pipefail

if ! command -v podman >/dev/null 2>&1; then
  printf '%s\n' "podman not installed; skipping storage config"
  exit 0
fi

storage_conf="${XDG_CONFIG_HOME:-$HOME/.config}/containers/storage.conf"
graph_parent="${XDG_DATA_HOME:-$HOME/.local/share}/containers"

probe="$graph_parent"
while [ ! -e "$probe" ] && [ "$probe" != "/" ]; do
  probe="$(dirname "$probe")"
done

fstype="$(findmnt -no FSTYPE -T "$probe" 2>/dev/null || echo "")"

case "$fstype" in
  btrfs|zfs) ;;
  *)
    printf '%s\n' "Backing fs '${fstype:-unknown}' supports native overlay; skipping"
    exit 0
    ;;
esac

if [ -f "$storage_conf" ]; then
  if grep -q "mount_program" "$storage_conf"; then
    printf '%s\n' "Podman storage already configured ($storage_conf)"
    exit 0
  fi
  printf '%s\n' "$storage_conf exists without mount_program; leaving it alone"
  exit 0
fi

if [ ! -x /usr/bin/fuse-overlayfs ]; then
  printf '%s\n' "fuse-overlayfs missing; install it and re-run"
  exit 0
fi

mkdir -p "$(dirname "$storage_conf")"
cat > "$storage_conf" <<'EOF'
# Rootless Podman storage on btrfs/zfs.
# Managed by scripts/setup/podman-storage.sh.
[storage]
driver = "overlay"

[storage.options.overlay]
mount_program = "/usr/bin/fuse-overlayfs"
EOF

printf '%s\n' "Podman storage configured for fuse-overlayfs ($fstype) -> $storage_conf"
