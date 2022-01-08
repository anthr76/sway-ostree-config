#!/usr/bin/env bash
set -xeuo pipefail

# Enable SysRQ
echo 'kernel.sysrq = 1' > /usr/lib/sysctl.d/90-sysrq.conf

ln -sfn /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# enable other units
mkdir -p /usr/lib/systemd/system/getty.target.wants
ln -s ../getty@.service /usr/lib/systemd/system/getty.target.wants/getty@tty1.service
ln -s ../systemd-timesyncd.service /usr/lib/systemd/system/sysinit.target.wants/systemd-timesyncd.service
ln -s ../systemd-resolved.service /usr/lib/systemd/system/multi-user.target.wants/systemd-resolved.service
ln -s ../sshd.socket /usr/lib/systemd/system/sockets.target.wants/sshd.socket

# move OS systemd unit defaults to /usr
cp -a --verbose /etc/systemd/system /etc/systemd/user /usr/lib/systemd/
rm -r /etc/systemd/system /etc/systemd/user

# avoid LVM spew in /etc
sed -i 's/backup = 1/backup = 0/; s/archive = 1/archive = 0/' /etc/lvm/lvm.conf

