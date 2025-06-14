#!/bin/bash
set -euo pipefail

echo "📦 安裝 Ubuntu 官方 ZFS..."
apt update
apt install -y zfsutils-linux zfs-initramfs zfs-zed libzfs4linux

echo "🔍 匯入 rpool 和 bpool，不掛載 data..."
zpool import -N rpool
zpool import -N bpool || true

echo "📂 掛載根檔案系統..."
zfs mount rpool/ROOT/ubuntu_hgiwnm
zfs mount bpool/BOOT/ubuntu_hgiwnm || true

echo "🛠 掛載系統目錄..."
for dir in /dev /proc /sys /run /dev/pts; do
  mount --bind $dir /mnt$dir
done

echo "💻 進入 chroot 修復..."
chroot /mnt /bin/bash -c '
  echo "🧹 移除手動編譯的 ZFS..."
  rm -f /usr/local/sbin/zfs /usr/local/sbin/zpool
  rm -f /usr/local/lib/libzfs*.so*
  ldconfig

  echo "📦 重新安裝 Ubuntu 官方 ZFS..."
  apt update
  apt install -y --reinstall zfsutils-linux zfs-zed zfs-initramfs libzfs4linux

  echo "📂 設定 cachefile 並重建 initramfs..."
  zpool set cachefile=/etc/zfs/zpool.cache rpool
  zpool set cachefile=/etc/zfs/zpool.cache bpool || true
  update-initramfs -c -k all
  update-grub
'

echo "✅ 修復完成！你可以 now: sudo reboot"
