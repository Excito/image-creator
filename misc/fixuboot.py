#
# A short script that replaces u-boot with a
# fresh version from a tftpserver
#
#
#
import serial
import fdpexpect
import sys

SPORT   = '/dev/ttyS1'
SSPEED  = 115200

serport = serial.Serial(SPORT, SSPEED)
serport.open()
#ser=fdpexpect.fdspawn(serport,logfile=sys.stderr)
ser=fdpexpect.fdspawn(serport)
ser.setecho(False)

def d(str):
	#print str
	pass

while True:
	try:
		ser.expect(["U-Boot 2010.06"])
		d("0")
		ser.expect(["B3>"])
		d("1")
		print "\nBoard booting"
		ser.sendline("echo $ethaddr")
		ser.readline()
		eth0=ser.readline().strip()
		d("2: ["+eth0+"]")
		ser.expect(["B3>"])

		ser.sendline("echo $eth1addr")
		ser.readline()
		eth1=ser.readline().strip()
		d("4: ["+eth1+"]")
		ser.expect(["B3>"])

		ser.sendline("echo $key")
		ser.readline()
		key=ser.readline().strip()
		d("5: ["+key+"]")
		ser.expect(["B3>"])

		ser.sendline("echo ${serial#}")
		ser.readline()
		serial=ser.readline().strip()
		d("6: ["+serial+"]")
		ser.expect(["B3>"])

		print "Eth0  : "+eth0
		print "Eth1  : "+eth1
		print "Key   : "+key
		print "Serial: "+serial
		
		print "Load new u-boot"
		ser.sendline("dhcp 0x400000 192.168.37.71:u-boot.kwb")
		ser.expect(["done"])
		ser.expect(["Bytes transferred = 210616"])
		d("7")
		lngd=ser.readline().split()[0][1:]
		d("8 downloaded: "+lngd)
		ser.expect(["B3>"])
		d("9")
		
		print "Probe flash"
		ser.sendline("sf probe 0:0")
		ser.expect("2048 KiB M25P16 at 0:0 is now current device")
		ser.expect(["B3>"])

		print "Erase flash"
		ser.sendline("sf erase 0 100000")
		ser.expect(["B3>"])

		print "Program flash"
		ser.sendline("sf write 400000 0 "+lngd)
		ser.expect(["B3>"])

		print "Reset board"
		ser.sendline("reset")
		ser.expect(["Hit any key to stop autoboot"])
		ser.sendline("")
		ser.expect(["B3>"])

		print "Removing unwanted env"
		ser.sendline("setenv bootcmd")
		ser.expect(["B3>"])

		print "Reprogram mac"
		ser.sendline("setenv ethaddr "+eth0)
		ser.expect(["B3>"])
		ser.sendline("setenv eth1addr "+eth1)
		ser.expect(["B3>"])

		print "Set serial and key"
		ser.sendline("setenv key "+key)
		ser.expect(["B3>"])
		ser.sendline("setenv serial# "+serial)
		ser.expect(["B3>"])

		print "Saving env to flash"
		ser.sendline("saveenv")
		ser.expect(["done"])
		ser.expect(["B3>"])
		d("10")

		print "Reprogram done"


	except KeyboardInterrupt:
		print "Terminating\n"
		break
