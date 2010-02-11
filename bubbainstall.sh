#! /bin/sh

# default config
DO_INSTALL=1
USE_EXTERNAL_SCRIPT=0
ROOT_SIZE=10
SWAP_SIZE=1
FORMAT=1
PARTITION=1
SETDATETIME=1
USELVM=1

# Indicate mount-phase
echo 4096 > /sys/devices/platform/bubbatwo/ledfreq
echo blink > /sys/devices/platform/bubbatwo/ledmode

getusb () {
	for arg in /sys/block/sd?
	do 
		DISK=`readlink -f $arg|grep usb | xargs -r basename`
		if [ -b /dev/${DISK}1 ]
		then
			RET="/dev/${DISK}1"
		fi	
	done
}

waitforusb () {
	i=1
	while [ $i -eq 1 ]
	do
		sleep 1
		echo "Waiting for usb device to show up"
		getusb
		if [ -n "$RET" ]
		then
			i=0
		fi
	done
}

waitforusb


# Mount usb-stick
echo "Mount usb"
while ! mount -t vfat $RET /mnt/usb
do
	sleep 1
done

# Indicate install-phase
echo 8192 > /sys/devices/platform/bubbatwo/ledfreq
echo blink > /sys/devices/platform/bubbatwo/ledmode

if [ -e /mnt/usb/install/bubba.cfg ]; then
		echo "Reading external config"
		. /mnt/usb/install/bubba.cfg
fi

# Look if we should install at all.
if [ $DO_INSTALL -eq 0 ]; then
	echo "Not doing install by your command"
	# Blink slowly to indicate that we wont install.
	echo 32768 > /sys/devices/platform/bubbatwo/ledfreq
	echo blink > /sys/devices/platform/bubbatwo/ledmode
	exit 0
fi

if [ $USE_EXTERNAL_SCRIPT -eq 1 ]; then
	echo "Looking for external install script"
	if [ -e /mnt/usb/install/einstall.sh ]; then
		echo "Transfering control to external installer"
		/mnt/usb/install/einstall.sh
	fi
	# blink real slow to tell were done executing external script 
	echo 49152 > /sys/devices/platform/bubbatwo/ledfreq
	echo blink > /sys/devices/platform/bubbatwo/ledmode
	exit 0
fi

IFILES=`ls -1 /mnt/usb/install/payload/*.tar.gz | wc  -l`
if [ $IFILES -le 0 ]; then
	echo "No payload to install, bailing out"
	echo 2048 > /sys/devices/platform/bubbatwo/ledfreq
	echo blink > /sys/devices/platform/bubbatwo/ledmode
	exit 1
fi

# Use lvm or linux native type
if [ $USELVM -eq 1 ]; then
DPARTTYPE="8e"
else
DPARTTYPE="83"
fi

echo "Fixing umask"
umask 0

if [ $SETDATETIME -eq 1 ]; then
	echo "Setting date/time"
	/usr/bin/wget -O - http://www.excito.com/install/date.php | /usr/bin/xargs /bin/date
	/sbin/hwclock -f /dev/rtc0 --systohc
else
	echo "Not setting date/time"
fi

if [ $PARTITION -eq 1 ]; then
	echo "Partition disk"
	# Get size in GB
	DISK=`cat /proc/partitions | grep sda$| cut -b 11-21`
	GB_DATA=$(( ($DISK*1024)/1000000000 ))
 
	#Calculate "home" partition size
	HOME_SIZE=$(( $GB_DATA-($ROOT_SIZE+$SWAP_SIZE) ))

	fdisk /dev/sda <<HERE
o
n
p
1
1
+${ROOT_SIZE}000M
n
p
2

+${HOME_SIZE}000M
n
p
3


t
1
83
t
2
$DPARTTYPE
t
3
82
w

HERE
else
	echo "Not partitioning disk"
fi

if [ $USELVM -eq 1 ]; then
	echo "Create volume"
	export LVM_SYSTEM_DIR=/tmp/lvm
	pvcreate /dev/sda2
	vgcreate bubba /dev/sda2
	lvcreate -l 100%FREE --name storage bubba
else
	echo "Not creating volume"
fi

echo "Format system disk"
mkfs.ext3 -q -L "Bubba root" /dev/sda1
tune2fs -c0 -i0 /dev/sda1

if [ $FORMAT -eq 1 ]; then
	if [ $USELVM -eq 1 ]; then
		echo "Formatting lvm data partition"
		mkfs.ext3 -q -L "Bubba home" /dev/mapper/bubba-storage
		tune2fs -c0 -i0 /dev/mapper/bubba-storage
	else
		echo "Formatting native data partition"
		mkfs.ext3 -q -L "Bubba home" /dev/sda2
		tune2fs -c0 -i0 /dev/sda2
	fi
else
	echo "Not formatting data partition"
fi

echo "Create swapspace"
mkswap /dev/sda3
 
echo "Install root filesystem"
mount -text3 /dev/sda1 /mnt/disk
mkdir /mnt/disk/home
if [ $USELVM -eq 1 ]; then
	mount -text3 /dev/mapper/bubba-storage /mnt/disk/home
else
	mount -text3 /dev/sda2 /mnt/disk/home
fi

cd /mnt/disk
tar zxf /mnt/usb/install/payload/*.tar.gz
echo "Creating missing devicenodes"
mknod dev/sda b 8 0
mknod dev/sda1 b 8 1
mknod dev/sda2 b 8 2
mknod dev/sda3 b 8 3
mknod dev/sda4 b 8 4
mknod dev/sdb b 8 16
mknod dev/sdb1 b 8 17
mknod dev/sdb2 b 8 18
mknod dev/sdb3 b 8 19
mknod dev/sdb4 b 8 20
mknod dev/ttyS0 c 4 64
mknod dev/rtc c 254 0

# Indicate install done.
echo 16384 > /sys/devices/platform/bubbatwo/ledfreq
echo blink > /sys/devices/platform/bubbatwo/ledmode


echo "Reboot into new system"
reboot
