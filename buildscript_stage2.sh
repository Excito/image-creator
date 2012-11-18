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

set -x

mount /proc;

sed -i 's/unstable/testing/g;s/vincent/hugo/g' /etc/apt/preferences
cat <<EOF > /etc/apt/sources.list
deb http://b3.update.excito.org/ hugo main
deb http://b3.update.excito.org/ upstream_squeeze_forhugo main
EOF

apt-get update

DEBIAN_FRONTEND=noninteractive apt-get install -y postfix mysql-server

cat <<EOF > /usr/sbin/policy-rc.d
#!/bin/sh
exit 101
EOF
chmod 755 /usr/sbin/policy-rc.d

DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true apt-get install -y bubba3-kernel bubba-buttond bubba logitechmediaserver less

wget http://dorkmeister:fisk@xyz.update.excito.org/pool/main/t/tele2/tele2_1_all.deb
DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true dpkg -i tele2_1_all.deb
rm -f tele2_1_all.deb
:>/etc/apt/preferences

apt-get update

DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true apt-get dist-upgrade -y

rm -f /usr/sbin/policy-rc.d

invoke-rc.d mysql stop

usermod -p '$1$AzIyDBlb$x09YPfzWv11Bvvl9SzZA/1' root

shadowconfig on

apt-get clean

rm -f /var/lib/apt/lists/*excito.org_dists_*

cp /usr/share/bubba-configs/apt/* /etc/apt/

## TODO fixed?
chown root:users /home/storage
#chmod 1777 /home/storage


umount /proc

exit


