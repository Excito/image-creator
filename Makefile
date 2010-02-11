TOPDIR=$(shell pwd)
DISTDIR?=`pwd`/target
DESTDIR=$(DISTDIR)

all:

skel:
	-@rm -rf skeleton.export
	svn export skeleton skeleton.export
	fakeroot make real-skel
	rm -rf skeleton.export

real-skel:
	@dh_testroot
	find skeleton.export -type d -exec chmod 0755 '{}' ';'
	find skeleton.export -type f -exec chmod 0644 '{}' ';'
	(cd skeleton.export && tar --create --gzip --file ../skeleton.tar.gz *) 
dist:
	mkdir -p $(DESTDIR)/bin
	mkdir -p $(DESTDIR)/etc/init.d
	mkdir -p $(DESTDIR)/etc/rc.d
	cp bubbainstall.sh $(DESTDIR)/bin
	cp installbubba $(DESTDIR)/etc/init.d/S80installbubba
	ln -s ../init.d/S80installbubba $(DESTDIR)/etc/rc.d/S80installbubba
	cd $(DESTDIR) && tar zcvf $(TOPDIR)/installer.tar.gz *

clean:
	rm -rf target skeleton.tar.gz

PHONY:
	skel
