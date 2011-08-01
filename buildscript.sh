#!/bin/bash
#===============================================================================
#
#          FILE:  buildscript.sh
# 
#         USAGE:  ./buildscript.sh 
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
#       CREATED:  06/17/2009 03:20:29 PM CEST
#      REVISION:  ---
#===============================================================================

# die die
set -e 

ROOT="./root";
INSTALL="./install"
SUITE="testing_full"
URI=" http://b3.update.excito.org/"
FILENAME="b2-minimal-install"

if [ `id -u` != 0 ]; then
	sudo $0 $@;
	exit;
fi 
# cleanup

rm -rf $INSTALL $ROOT

if [ ! -d /usr/share/cdebootstrap/excito ]; then
	DEBIAN_FRONTEND=noninteractive apt-get update
	DEBIAN_FRONTEND=noninteractive apt-get install -y cdebootstrap-excito
fi

# the debootstrap
cdebootstrap $SUITE $ROOT $URI

# install the skeleton (should become obsolete in the future)
cp -a skeleton/* $ROOT/

# change hostname to b3
_old_hostname=`cat /proc/sys/kernel/hostname`;
echo b2 > /proc/sys/kernel/hostname;

#stop running mysql
if [ -e /etc/init.d/mysql ]; then
	/etc/init.d/mysql stop || true
fi

# setup answers to debconf
cat debconf | chroot $ROOT debconf-set-selections

# stage two build script
cp buildscript_stage2.sh $ROOT/runme.sh
chmod 755 $ROOT/runme.sh

# run it
chroot $ROOT /runme.sh

#remove it
rm -f $ROOT/runme.sh

# truncate all logs
for i in $(find $ROOT/var/log -type f); do :> $i; done

# remove eventual pids
find $ROOT/var/run/ -name "*.pid" -exec rm {} \;

# truncate bash history
:> $ROOT/root/.bash_history

# conf fixes
perl -pi -e 's/sysfs_scan = 1/sysfs_scan = 0/' $ROOT/etc/lvm/lvm.conf
#perl -pi -e 's/NO_START=1/NO_START=0/' $ROOT/etc/default/apache2
perl -pi -e 's/FSCKFIX=no/FSCKFIX=yes/' $ROOT/etc/default/rcS # (bug #1484)
perl -pi -e 's/INTERFACES=""/INTERFACES="all"/g' $ROOT/etc/default/ifplugd

# build the payload
export _date=`date +%y%m%d-%H%M`
( cd $ROOT && tar --create --verbose --file ../bubbaroot-$_date.tar * )
gzip --fast bubbaroot-$_date.tar

# extract the envelope
mkdir -p $INSTALL/payload
cp -a envelope/* $INSTALL

# move payload into envelope
mv bubbaroot-$_date.tar.gz $INSTALL/payload


# zip and checksum the install
ver=${1:-0.0.1}
echo $ver > $INSTALL/version
zip -0 -r $FILENAME-$ver.zip $INSTALL
sha1sum $FILENAME-$ver.zip > $FILENAME-$ver.zip.sha1
sha256sum $FILENAME-$ver.zip > $FILENAME-$ver.zip.sha256

#(re)start mysql
if [ -e /etc/init.d/mysql ]; then
	/etc/init.d/mysql start || true
fi

# restore hostname
echo $_old_hostname > /proc/sys/kernel/hostname;
