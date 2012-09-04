#!perl
#
# This file is part of Config-Model
#
# This software is Copyright (c) 2012 by Dominique Dumont, Krzysztof Tyszecki.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}


use Test::More;

eval "use Pod::Wordlist::hanekomu";
plan skip_all => "Pod::Wordlist::hanekomu required for testing POD spelling"
  if $@;

eval "use Test::Spelling 0.12";
plan skip_all => "Test::Spelling 0.12 required for testing POD spelling"
  if $@;


add_stopwords(<DATA>);
all_pod_files_spelling_ok('lib');
__DATA__
Bzr
CTRL
Cvs
DEP
DFSG
DM
Darcs
GFDL
GPL
HOSTID
Indep
LGPL
MAILTO
MTA
MTA's
Mtn
NIV
OpenSSL
PopCon
Pre
QPL
SUBMITURLS
Svn
USEHTTP
Vcs
Wiki
Xorg
ZLIB
Zope
anyid
anything
augeas
autoadd
autoread
browsable
bz
bzr
cds
cddl
CNRI
checklist
conf
contrib
cpan
cpu
ctrl
cvs
cvsignore
darcs
davfs
ddumont
debconf
debugfs
debian
dep
dfsg
dm
dpkg
dumont
firstkey
freebsd
fs
fsck
fstab
git
gz
gmail
hashid
hg
http
indepicrosystems
inet
ini
IntellectualRights
isc
iso
json
journaling
krzysztof
lan
lenny
lgpl
lppl
listid
lzma
mcloughlin
mailfrom
microsystems
mtn
mpl
nfs
nextkey
objtreescanner
openbsd
openssh
os
pts
proc
redhat
redhat's
scriplets
shellvar
svn
tdeb
tyszecki
udeb
ui
uncheck
uniline
urls
uploaders
usb
usbfs
vcs
vfat
vcss
warper
warpthing
webdav
webmin
wildcard
wildcards
xorg
xserver
xz
yaml
Dominique
Dumont
Krzysztof
Tyszecki
