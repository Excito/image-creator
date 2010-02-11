#! /bin/sh

has_eth0=0;
has_eth1=0;
if ip address show eth0 | grep -oE 'link/ether [0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}' | grep -qv 'link/ether 00:00:00:00:00:00'; then
	has_eth0=1;
	echo "got eth0";
fi
if ip address show eth1 | grep -oE 'link/ether [0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}' | grep -qv 'link/ether 00:00:00:00:00:00'; then
	has_eth1=1;
	echo "got eth1";
fi

if test $(($has_eth0 + $has_eth1)) != 2; then
	echo "lacks something";
	echo 2048 > /sys/devices/platform/bubbatwo/ledfreq;
	echo blink > /sys/devices/platform/bubbatwo/ledmode;
else
	echo "ok";
	echo lit > /sys/devices/platform/bubbatwo/ledmode;
fi
# STOP!!!!
while :; do sleep 1; done
