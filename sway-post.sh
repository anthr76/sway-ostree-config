#!/usr/bin/env bash
set -xeuo pipefail

# Enable SysRQ
echo 'kernel.sysrq = 1' > /usr/lib/sysctl.d/90-sysrq.conf


# set up PAM for systemd-homed (https://bugzilla.redhat.com/show_bug.cgi?id=1806949)
patch /etc/pam.d/system-auth <<EOF
--- /usr/etc/pam.d/system-auth
+++ /etc/pam.d/system-auth
@@ -1,16 +1,20 @@
 #%PAM-1.0
 auth        required      pam_env.so
 auth        sufficient    pam_unix.so try_first_pass nullok
+-auth       sufficient    pam_systemd_home.so  # added
 auth        required      pam_deny.so
-account     required      pam_unix.so
+account     sufficient    pam_unix.so
+-account    sufficient    pam_systemd_home.so  # added
 password    requisite     pam_pwquality.so try_first_pass local_users_only retry=3 authtok_type=
 password    sufficient    pam_unix.so try_first_pass use_authtok nullok yescrypt shadow
+-password   sufficient    pam_systemd_home.so  # added
 password    required      pam_deny.so
 session     optional      pam_keyinit.so revoke
 session     required      pam_limits.so
+-session    optional      pam_systemd_home.so  # added
 -session     optional      pam_systemd.so
 session     [success=1 default=ignore] pam_succeed_if.so service in crond quiet use_uid
 session     required      pam_unix.so
EOF
patch /etc/pam.d/password-auth <<EOF
--- password-auth
+++ password-auth
@@ -1,16 +1,20 @@
 #%PAM-1.0
 auth        required      pam_env.so
 auth        sufficient    pam_unix.so try_first_pass nullok
+-auth       sufficient    pam_systemd_home.so  # added
 auth        required      pam_deny.so
-account     required      pam_unix.so
+account     sufficient    pam_unix.so
+-account    sufficient    pam_systemd_home.so  # added
 password    requisite     pam_pwquality.so try_first_pass local_users_only retry=3 authtok_type=
 password    sufficient    pam_unix.so try_first_pass use_authtok nullok yescrypt shadow
+-password   sufficient    pam_systemd_home.so  # added
 password    required      pam_deny.so
 session     optional      pam_keyinit.so revoke
 session     required      pam_limits.so
+-session    optional      pam_systemd_home.so  # added
 -session     optional      pam_systemd.so
 session     [success=1 default=ignore] pam_succeed_if.so service in crond quiet use_uid
 session     required      pam_unix.so
EOF

# homed is missing a lot of SELinux policy (https://bugzilla.redhat.com/show_bug.cgi?id=1809878)
# "disabled" breaks rpm-ostree (https://bugzilla.redhat.com/show_bug.cgi?id=1882933), so just use permissive
sed -i 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config

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

