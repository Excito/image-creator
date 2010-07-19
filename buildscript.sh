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
. /lib/lsb/init-functions

ROOT="./root";
INSTALL="./install"
SUITE="testing_full"
URI=" http://b3.update.excito.org/"
FILENAME="b3-install"

if [ ! -d installer ]; then
	if [ `basename $PWD` = 'installer' ]; then
		cd ..
	else
		log_failure_msg "need to be executed in topdir above installer dir";
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
	log_action_begin_msg "installing cdebootstrap"
	DEBIAN_FRONTEND=noninteractive apt-get update >/dev/null
	DEBIAN_FRONTEND=noninteractive apt-get install -y cdebootstrap-excito >/dev/null
	log_action_end_msg
fi

# the debootstrap
cdebootstrap $SUITE $ROOT $URI

# install the skeleton (XXX make obsolete?)
log_action_begin_msg "installing skeleton"
tar -zxf installer/skeleton.tar.gz -C $ROOT/
log_action_end_msg

# change hostname to bubba
_old_hostname=`cat /proc/sys/kernel/hostname`;
log_action_msg "setting hostname to \"bubba\""
echo bubba > /proc/sys/kernel/hostname;

#stop running mysql
if [ -e /etc/init.d/mysql ]; then
	log_action_begin_msg "terminating mysql"
	/etc/init.d/mysql stop || true
	log_action_end_msg
fi

# setup answers to debconf
log_action_begin_msg "preseeding debconf"
cat installer/debconf | chroot $ROOT debconf-set-selections
log_action_end_msg

# stage two build script
log_action_msg "Entering stage 2 builder"
cp installer/buildscript_stage2.sh $ROOT/runme.sh
chmod 755 $ROOT/runme.sh

# run it
chroot $ROOT /runme.sh

#remove it
rm -f $ROOT/runme.sh

# truncate all logs
log_action_msg "truncating logs"
for i in $(find $ROOT/var/log -type f); do :> $i; done

# remove eventual pids
log_action_msg "removing old pid files"
find $ROOT/var/run/ -name "*.pid" -exec rm {} \;

# truncate bash history
log_action_msg "truncating root bash history"
:> $ROOT/root/.bash_history

# conf fixes
perl -pi -e 's/sysfs_scan = 1/sysfs_scan = 0/' $ROOT/etc/lvm/lvm.conf
perl -pi -e 's/NO_START=1/NO_START=0/' $ROOT/etc/default/apache2

# build the payload
log_action_begin_msg "building payload"
export _date=`date +%y%m%d-%H%M`
( cd $ROOT && tar --create --verbose --file ../bubbaroot-$_date.tar * )
log_action_end_msg
log_action_begin_msg "compressing payload"
gzip --fast bubbaroot-$_date.tar
log_action_end_msg

# extract the envelope
log_action_begin_msg "extracting envelope"
tar -zxvf installer/envelope.tar.gz
log_action_end_msg

# move payload into envelope
log_action_msg "moving payload into envelope"
mv bubbaroot-$_date.tar.gz $INSTALL/payload

# zip and checksum the install
ver=${1:-0.0.1}
log_action_begin_msg "generating checksums"
zip -0 -r $FILENAME-$ver.zip $INSTALL
sha1sum $FILENAME-$ver.zip > $FILENAME-$ver.zip.sha1
sha256sum $FILENAME-$ver.zip > $FILENAME-$ver.zip.sha256
log_action_end_msg

#(re)start mysql
if [ -e /etc/init.d/mysql ]; then
	log_action_begin_msg "restarting mysql"
	/etc/init.d/mysql start || true
	log_action_end_msg
fi

# restore hostname
log_action_msg "restoring hostname \"$_old_hostname\""
echo $_old_hostname > /proc/sys/kernel/hostname;

log_action_begin_msg "cleaning installer build dir"
( cd installer && make clean )
log_action_end_msg
