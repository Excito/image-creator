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
set -x

ROOT="./root";
INSTALL="./install"
SUITE="testing_full"
URI=" http://b3.update.excito.org/"
FILENAME="b3-install"

if [ ! -d installer ]; then
	if [ `basename $PWD` = 'installer' ]; then
		cd ..
	else
		echo "need to be executed in topdir above installer dir";
		exit 1;
	fi;
fi
if [ `id -u` != 0 ]; then
	sudo installer/`basename $0` $@;
	exit;
fi 
# cleanup

rm -rf $INSTALL $ROOT
# make the skeleton
( cd installer && make skel )
if [ ! -d /usr/share/cdebootstrap/excito ]; then
	DEBIAN_FRONTEND=noninteractive apt-get update
	DEBIAN_FRONTEND=noninteractive apt-get install -y cdebootstrap-excito
fi

# the debootstrap
cdebootstrap $SUITE $ROOT $URI

# install the skeleton (XXX make obsolete?)
tar -zxvf installer/skeleton.tar.gz -C $ROOT/

# change hostname to bubba
_old_hostname=`cat /proc/sys/kernel/hostname`;
echo bubba > /proc/sys/kernel/hostname;

#stop running mysql
if [ -e /etc/init.d/mysql ]; then
	/etc/init.d/mysql stop || true
fi

# setup answers to debconf
cat installer/debconf | chroot $ROOT debconf-set-selections

# stage two build script
cp installer/buildscript_stage2.sh $ROOT/runme.sh
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
perl -pi -e 's/NO_START=1/NO_START=0/' $ROOT/etc/default/apache2
perl -pi -e 's/FSCKFIX=no/FSCKFIX=yes/' $ROOT/etc/default/rcS # (bug #1484)

# build the payload
export _date=`date +%y%m%d-%H%M`
( cd $ROOT && tar --create --verbose --file ../bubbaroot-$_date.tar * )
gzip --fast bubbaroot-$_date.tar

# extract the envelope
tar -zxvf installer/envelope.tar.gz

# move payload into envelope
mv bubbaroot-$_date.tar.gz $INSTALL/payload

# zip and checksum the install
ver=${1:-0.0.1}
zip -0 -r $FILENAME-$ver.zip $INSTALL
sha1sum $FILENAME-$ver.zip > $FILENAME-$ver.zip.sha1
sha256sum $FILENAME-$ver.zip > $FILENAME-$ver.zip.sha256

#(re)start mysql
if [ -e /etc/init.d/mysql ]; then
	/etc/init.d/mysql start || true
fi

# restore hostname
echo $_old_hostname > /proc/sys/kernel/hostname;

( cd installer && make clean )
