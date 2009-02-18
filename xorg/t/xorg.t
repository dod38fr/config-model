# -*- cperl -*-
# $Author: ddumont $
# $Date: 2007-10-01 15:31:07 $
# $Name: not supported by cvs2svn $
# $Revision: 1.5 $

use ExtUtils::testlib;
use Test::More tests => 7;
use Config::Model;
use Log::Log4perl qw(:easy) ;
use Data::Dumper ;
use File::Path ;

use warnings;
no warnings qw(once);

use strict;

use vars qw/$model/;


my $arg = shift || '' ;
my $trace = $arg =~ /t/ ? 1 : 0 ;
$::verbose          = 1 if $arg =~ /v/;
$::debug            = 1 if $arg =~ /d/;
my $log             = 1 if $arg =~ /l/;

Log::Log4perl->easy_init($log ? $DEBUG: $WARN);

$model = Config::Model -> new ( ) ;# model_dir => '.' );

Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

ok(1,"compiled");

# pseudo root where config files are written by config-model
my $wr_root = 'wr_test';

# cleanup before tests
rmtree($wr_root);

my @orig = <DATA> ;

my $wr_dir = $wr_root ;
mkpath($wr_dir.'/etc/X11', { mode => 0755 })
  || die "can't mkpath: $!";
open(XORG,"> $wr_dir/etc/X11/xorg.conf")
  || die "can't open file: $!";
print XORG @orig ;
close XORG ;

my $inst = $model->instance (root_class_name   => 'Xorg', 
			     instance_name     => 'xorg_instance',
			     root_dir          => $wr_dir,
			    );
ok($inst,"Read xorg.conf and created instance") ;

my $root = $inst -> config_root ;

my $orig_data = Config::Model::Xorg::Read::read( object => $root,
						 root   => $wr_dir,
						 config_dir => '/etc/X11',
						 test => 1
					       ) ;

open (FOUT,">$wr_dir/orig_data.pl") || die "can't open $wr_dir/orig_data.pl:$!";
print FOUT Dumper($orig_data) ;
close FOUT ;

#$inst->push_no_value_check('fetch') ;
my $res = $root->describe ;
#$inst->pop_no_value_check;
print "Root node description:\n\n",$res,"\n" if $trace ;

ok($inst,"created description") ;

my $orig_dump = $root->dump_tree ;
ok($inst,"created original xorg cds dump in $wr_dir") ;

open (FOUT,">$wr_dir/xorg_dump.cds") || die "can't open $wr_dir/xorg_dump.cds:$!";
print FOUT $orig_dump ;
close FOUT ;

$inst->write_back ;

ok($inst,"wrote back file in $wr_dir") ;

my $inst2 = $model->instance (root_class_name   => 'Xorg', 
			      instance_name     => 'xorg_instance2',
			      root_dir          =>  $wr_dir,
			     );

ok($inst2,"Read xorg.conf from $wr_dir and created 2nd instance" ) ;

my $wr_data = Config::Model::Xorg::Read::read( object => $root,
					       root   => $wr_dir,
					       config_dir => '/etc/X11',
					       test => 1
					     ) ;

open (FOUT,">$wr_dir/written_data.pl") || die "can't open $wr_dir/written_data.pl:$!";
print FOUT Dumper($wr_data) ;
close FOUT ;

my $wr_dump = $inst2->config_root->dump_tree ;

open (FOUT,">$wr_dir/2nd_dump.cds") || die "can't open $wr_dir/2nd_dump.cds:$!";
print FOUT $wr_dump ;
close FOUT ;

is_deeply([split /\n/, $wr_dump ],
	  [split /\n/, $orig_dump ],
	  "compare dump of original xorg with second dump") ;


# require Tk::ObjScanner; Tk::ObjScanner::scan_object($model) ;

__DATA__


Section "Files"
	# if the local font server has problems, we can fall back on these
	FontPath	"/usr/share/fonts/X11/misc"
	FontPath	"/usr/share/fonts/X11/cyrillic"
	FontPath	"/usr/share/fonts/X11/100dpi/:unscaled"
	FontPath	"/usr/share/fonts/X11/75dpi/:unscaled"
	FontPath	"/usr/share/fonts/X11/Type1"
#	FontPath	"/usr/share/fonts/X11/CID"
	FontPath	"/usr/share/fonts/X11/100dpi"
	FontPath	"/usr/share/fonts/X11/75dpi"
        FontPath        "/var/lib/defoma/x-ttcidfont-conf.d/dirs/TrueType"
EndSection

Section "Module"
	Load	"bitmap"
	Load	"dbe"
	Load	"ddc"
	Load	"dri"
	Load	"extmod"
	Load	"freetype"
	Load	"glx"
	Load	"int10"
	Load	"record"
	Load	"type1"
	Load	"v4l"
	Load	"vbe"
EndSection

Section "InputDevice"
	Identifier	"Generic Keyboard"
	Driver		"keyboard"
	Option		"CoreKeyboard"
	Option		"XkbRules"	"xorg"
	Option		"XkbModel"	"pc104"
	Option		"XkbLayout"	"us"
	Option		"XkbOptions"	"compose:rwin"
	Option          "AutoRepeat"    "501 31"
EndSection

Section "InputDevice"
	Identifier	"Configured Mouse"
	Driver		"mouse"
	Option		"CorePointer"
	Option		"Device"		"/dev/psaux"
	Option		"Protocol"		"ImPS/2"
	Option		"Emulate3Buttons"	"false"
	Option		"ZAxisMapping"		"4 5"
EndSection

Section "InputDevice"
        Identifier  "LIRC-Mouse"
        Driver      "mouse"
        Option      "Device" "/dev/lircm"
        Option      "Protocol" "IntelliMouse"
        Option      "SendCoreEvents"
        Option      "Buttons" "5"
        Option      "ZAxisMapping" "4 5"
EndSection

Section "Device"
	Identifier	"DVI"
	Driver		"radeon"
        BusID           "PCI:3:0:1"
 	Screen          1

	# required if second monitor detection does not work
	# powered off ?
        #	Option "MonitorLayout" "TMDS, CRT"
	Option "MergedFB" "true" # "false"
EndSection

Section "Device"
	Identifier	"VGA"
	BusID           "PCI:3:0:0"
 	Driver    	"radeon"
	Screen          0
	Option "MergedFB" "true" # "false"
EndSection

Section "Monitor"
	Identifier	"Hercules Pro"
	HorizSync	30-80
	VertRefresh	50-75
	Option		"DPMS"
	Gamma           1.001
EndSection

Section "Monitor"
	Identifier "Projector"
	VendorName "Optoma Electronics"
	# not tested on actual config
	DisplaySize  2300 1200
	ModelName "H79"
	HorizSync 27.0 - 96.0
	VertRefresh 50.0 - 160.0
	Gamma     1.001 1.002 1.003

	# From http://www.knoppmythwiki.org/index.php?page=XModLines
	#                           clock       
	#                                    hdisp               vdisp
	#                                         hsyncstart          vsyncstart
        #                                              hsyncend            vsyncend
	#                                                   htota               vtotal
	ModeLine "NTSC-59.94i"       14.350  768  808  864  912  483  485  491  525 Interlace
	ModeLine "NTSC-59.94p"       28.699  768  808  864  912  483  485  491  525
	ModeLine "NTSC-DVD-59.94i"   13.469  720  760  816  856  480  482  488  525 Interlace
	ModeLine "NTSC-DVD-60i"      13.482  720  760  816  856  480  482  488  525 Interlace
	ModeLine "NTSC-DVD-59.94p"   26.937  720  760  816  856  480  482  488  525
	ModeLine "NTSC-DVD-60p"      26.964  720  760  816  856  480  482  488  525
	ModeLine "NTSC-DVD-71.93p"   32.324  720  760  816  856  480  482  488  525
	ModeLine "NTSC-DVD-72p"      32.357  720  760  816  856  480  482  488  525
	ModeLine "ATSC-480-59.94p"   23.916  640  664  736  760  480  482  488  525
	ModeLine "ATSC-480-60p"      23.940  640  664  736  760  480  482  488  525
	ModeLine "ATSC-480-71.93p"   28.699  640  664  736  760  480  482  488  525
	ModeLine "ATSC-480-72p"      28.728  640  664  736  760  480  482  488  525
	ModeLine "ATSC-720-59.94p"   74.086 1280 1320 1376 1648  720  722  728  750
	ModeLine "ATSC-720-60p"      74.160 1280 1320 1376 1648  720  722  728  750
	ModeLine "ATSC-720-71.93p"   88.903 1280 1320 1376 1648  720  722  728  750
	ModeLine "ATSC-720-72p"      88.992 1280 1320 1376 1648  720  722  728  750
	ModeLine "ATSC-1080-59.94i"  74.176 1920 1960 2016 2200 1080 1082 1088 1125 Interlace
	ModeLine "ATSC-1080-60i"     74.250 1920 1960 2016 2200 1080 1082 1088 1125 Interlace
	ModeLine "ATSC-1080-59.94p" 148.352 1920 1960 2016 2200 1080 1082 1088 1125
	ModeLine "ATSC-1080-60p"    148.500 1920 1960 2016 2200 1080 1082 1088 1125
	ModeLine "ATSC-1080-71.93p" 178.022 1920 1960 2016 2200 1080 1082 1088 1125
	ModeLine "ATSC-1080-72p"    178.200 1920 1960 2016 2200 1080 1082 1088 1125

        ModeLine "1280x720p-75Hz"    93.23  1280 1320 1456 1640  720  722  724  758  # 93 MHz, 56.9 kHz, 75.0 Hz




	ModeLine "1280x720p" 74.481 1280 1336 1472 1664 720 721 724 746 +HSync +VSync

	#72Hz ModeLine "1280x720p" 91.607 1280 1365 1504 1696 720 721 724 751 -HSync +VSync
	#48 Hz ModeLine "1280x720p" 61.087 1280 1365 1504 1696 720 721 724 751 -HSync +VSync
	#60 Hz ModeLine "1280x720p" 76.397 1280 1365 1504 1696 720 721 724 751 -HSync +VSync
EndSection

Section "Screen"
 	Identifier	"H79 Screen"
 	Device		"DVI"
 	Monitor		"Projector"
 	DefaultDepth	24
 	SubSection "Display"
 		Depth		24
 		Modes		 "1280x720p-75Hz" "1280x1024"
 	EndSubSection
EndSection

Section "Screen"
	Identifier	"LCD Screen"
	Device		"VGA"
	Monitor		"Hercules Pro"
	DefaultDepth	24
	SubSection "Display"
		Depth		1
		Modes		"1280x1024" "1024x768" "832x624" "800x600" "720x400" "640x480"
	EndSubSection
	SubSection "Display"
		Depth		4
		Modes		"1280x1024" "1024x768" "832x624" "800x600" "720x400" "640x480"
	EndSubSection
	SubSection "Display"
		Depth		8
		Modes		"1280x1024" "1024x768" "832x624" "800x600" "720x400" "640x480"
	EndSubSection
	SubSection "Display"
		Depth		15
		Modes		"1280x1024" "1024x768" "832x624" "800x600" "720x400" "640x480"
	EndSubSection
	SubSection "Display"
		Depth		16
	 	ViewPort        200 100
	        Virtual         1980 1020
		Modes		"1280x1024" "1024x768" "832x624" "800x600" "720x400" "640x480"
	EndSubSection
	SubSection "Display"
		Depth		24
                #                        Virtual    1280 2048
		Modes		"1280x1024" "1024x768" "832x624" "800x600" "720x400" "640x480"
	EndSubSection
EndSection

Section "ServerLayout"
	Identifier	"Default Layout"
	Screen		"LCD Screen"  0  1 
	InputDevice	"Generic Keyboard"
	InputDevice	"Configured Mouse"
        InputDevice     "LIRC-Mouse"
EndSection

Section "ServerLayout"
	Identifier	"HC"
	Screen	1	"H79 Screen" RightOf "LCD Screen"
        Screen 	0       "LCD Screen" 
	InputDevice	"Generic Keyboard" "CoreKeyboard"
	InputDevice	"Configured Mouse"
        InputDevice     "LIRC-Mouse"
EndSection

Section "DRI"
	Mode	0666
EndSection

Section "ServerFlags"
	Option "DefaultServerLayout"  "HC"
	Option "DontZap"  "1"
EndSection

# second dummy card to test nvidia driver model
Section "Device"

    Identifier     "NV 1"
    Driver         "nvidia"
    Screen          0
    Option "TwinView"  "true"
    Option "MetaModes" "1280x1024,1280x1024"
EndSection

Section "Device"
        Identifier      "NV 2"
        Driver          "nvidia"
        Screen          1
    Option "TwinView"  "true"
    Option "MetaModes" "1280x1024,1280x1024"
EndSection

#Section "Extensions"
#	Option "Composite" "Enable"
#EndSection

