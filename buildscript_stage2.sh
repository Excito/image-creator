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

mount /proc;

sed -i 's/unstable/testing/g;s/claire/estelle/g' /etc/apt/preferences
sed -i '/marielle\|upstream_etch\s\|ftp.se.debian.org/ { s/^\(deb\)/#\1/g }; /claire/ { /deb-src/ !{ s/#\(deb\)/\1/ } ; s/claire/estelle/ }' /etc/apt/sources.list

apt-get update

DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server

cat <<EOF > /usr/sbin/policy-rc.d
#!/bin/sh
exit 101
EOF
chmod 755 /usr/sbin/policy-rc.d

DEBIAN_FRONTEND=noninteractive apt-get install -y bubba-frontend squeezecenter less

rm -f /usr/sbin/policy-rc.d

invoke-rc.d mysql stop

usermod -p '$1$AzIyDBlb$x09YPfzWv11Bvvl9SzZA/1' root

shadowconfig on

apt-get clean

rm -f /var/lib/apt/lists/update.excito.org_dists_*

cp /usr/share/bubba-configs/apt/* /etc/apt/

## TODO fixed?
chown root:users /home/storage
chmod 1777 /home/storage


umount /proc

exit


