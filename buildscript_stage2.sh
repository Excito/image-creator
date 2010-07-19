#!/bin/bash
#===============================================================================
#
#          FILE:  buildscript_chroot.sh
# 
#         USAGE:  ./buildscript_chroot.sh 
# 
#   DESCRIPTION:  
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:   (), 
#       COMPANY:  
#       VERSION:  1.0
#       CREATED:  09/01/2009 11:08:29 AM CEST
#      REVISION:  ---
#===============================================================================
set -e
. /lib/lsb/init-functions

log_action_msg "mouting proc"
mount /proc;

log_action_msg "setting up repositories"
sed -i 's/unstable/testing/g;s/vincent/hugo/g' /etc/apt/preferences
cat <<EOF > /etc/apt/sources.list
deb http://b3.update.excito.org/ hugo main
deb http://b3.update.excito.org/ upstream_squeeze_forhugo main
EOF

log_action_begin_msg "updating repositories"
apt-get update >/dev/null
log_action_end_msg

log_action_begin_msg "installing postifx and mysql"
DEBIAN_FRONTEND=noninteractive apt-get install -y postfix mysql-server >/dev/null
log_action_end_msg

log_action_msg "enabling policy-rc.d"
cat <<EOF > /usr/sbin/policy-rc.d
#!/bin/sh
exit 101
EOF
chmod 755 /usr/sbin/policy-rc.d

log_action_begin_msg "installing bubba packages"
DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true apt-get install -y bubba3-kernel bubba3-modules bubba squeezecenter less >/dev/null
log_action_end_msg

log_action_msg "disabling policy-rc.d"
rm -f /usr/sbin/policy-rc.d

log_action_msg "shutting down mysql"
invoke-rc.d mysql stop

log_action_msg "stting root password"
usermod -p '$1$AzIyDBlb$x09YPfzWv11Bvvl9SzZA/1' root

log_action_msg "enabling shadow"
shadowconfig on

log_action_msg "clean apt"
apt-get clean

rm -f /var/lib/apt/lists/*excito.org_dists_*

log_action_msg "installing bubba apt config"
cp /usr/share/bubba-configs/apt/* /etc/apt/

## TODO fixed?
chown root:users /home/storage
chmod 1777 /home/storage


log_action_msg "unmount proc"
umount /proc

exit


