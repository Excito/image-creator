# Creating an Excito B3 installer

## Pre-requists

 * One clean B3 in server mode without wireless active (important due to resetting of firewall)
 * the package cdebootstrap-excito installable (needed for enabling cdebootstrap to access the excito package repository). It's available from the main repository and the build script will try to install this if it doesn't exists allready.
 * git

## Steps

First the repository testing\_full suite needs to be synchronized, 
this by executing following command on the repository server:

```
sudo -H -u repository reprepro pull testing_full
```

On the B3, checkout this project, i.e.

```
git clone --depth 1 git@github.com:Excito/installer.git
```

Change into the installer directory, and from there issue following command:

```
./buildscript.sh VERSION
```

Where VERSION is the current version to release, for example `2.3-RC2`

Total build time will take around 50 minutes depending on upstream network bandwidth towards the central repository.
The resulting zip file and sha sums will be places into the current directory.

## Customization

As cdebootstrap requires suits to be defined centrally, for customizations the simplest way can be to add custom installation after the main installation in the `buildscript_stage2.sh` script before the `rm -f /usr/sbin/policy-rc.d` line.

First in `buildscript.sh` add code, before the executing of the stage two build script, to copy the debs into the chroot:

```
cp bubba-backend_custom.deb $ROOT
```

and in `buildscript_stage2.sh` run:

```
DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true dpkg -i bubba-backend_custom.deb;
rm -f bubba-backend_custom.deb;
```
