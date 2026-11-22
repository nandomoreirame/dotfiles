#!/usr/bin/env bash
# Prepare QEMU/KVM through libvirt for virt-manager: enable the daemon, let the
# user manage system VMs and keep the default NAT network up. Each step runs
# only when it is not done yet.
set -eo pipefail

if ! command -v virsh >/dev/null 2>&1 || ! command -v libvirtd >/dev/null 2>&1; then
  printf '%s\n' "libvirt not installed; skipping (dotfiles packages install --manager pacman --group vm)"
  exit 0
fi

user="${USER:-$(id -un)}"
virsh_system=(virsh --connect qemu:///system)

if systemctl is-enabled --quiet libvirtd.service; then
  printf '%s\n' "libvirtd already enabled"
else
  sudo systemctl enable --now libvirtd.service
  printf '%s\n' "Enabled libvirtd"
fi

if id -nG "$user" | tr ' ' '\n' | grep -qx libvirt; then
  printf '%s\n' "$user is already in the libvirt group"
else
  sudo usermod -aG libvirt "$user"
  printf '%s\n' "Added $user to the libvirt group. Log out and back in to use it."
fi

net_info="$(LC_ALL=C sudo "${virsh_system[@]}" net-info default 2>/dev/null || true)"
if [ -z "$net_info" ]; then
  printf '%s\n' "No libvirt network named default; create one in virt-manager"
  exit 0
fi
if ! grep -Eq '^Autostart:[[:space:]]+yes' <<<"$net_info"; then
  sudo "${virsh_system[@]}" net-autostart default
fi
if ! grep -Eq '^Active:[[:space:]]+yes' <<<"$net_info"; then
  sudo "${virsh_system[@]}" net-start default
fi
printf '%s\n' "Default NAT network is active and starts on boot"
