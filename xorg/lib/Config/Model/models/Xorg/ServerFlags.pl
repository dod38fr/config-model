# $Author: ddumont $
# $Date: 2007-10-23 16:18:25 $
# $Name: not supported by cvs2svn $
# $Revision: 1.4 $

#    Copyright (c) 2005,2006 Dominique Dumont.
#
#    This file is part of Config-Xorg.
#
#    Config-Xorg is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser Public License as
#    published by the Free Software Foundation; either version 2.1 of
#    the License, or (at your option) any later version.
#
#    Config-Xorg is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser Public License for more details.
#
#    You should have received a copy of the GNU Lesser Public License
#    along with Config-Model; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA


# This model was created from xorg.conf(5x) man page from xorg
# project (http://www.x.org/).

# Model for ServerFlags section of xorg.conf

[
 [
  'name' => 'Xorg::ServerFlags',

  'element'
  => [
      "DefaultServerLayout" => { type => 'leaf',
				 value_type => 'reference',
				 refer_to   => '! ServerLayout',
			       },

      [qw/NoTrapSignals DontVTSwitch DontZap DontZoom DisableVidModeExtension
          AllowNonLocalXvidtune DisableModInDev AllowMouseOpenFail VTSysReq
          XkbDisable NoPM Xinerama AllowDeactivateGrabs AllowClosedownGrabs
          IgnoreABI
       /] 
      =>  { type => 'leaf', value_type => "boolean", built_in => 0 } ,

      
      "VTInit"      => { type => 'leaf', value_type => "uniline" },
      "BlankTime"   => { type => 'leaf', value_type => "integer", built_in => 10 },
      "StandbyTime" => { type => 'leaf', value_type => "integer", built_in => 20 },
      "SuspendTime" => { type => 'leaf', value_type => "integer", built_in => 30 },
      "OffTime"     => { type => 'leaf', value_type => "integer", built_in => 40 },

      "Pixmap"      => { type => 'leaf', value_type => "enum", 
			 built_in => 32, choice => [24,32] },

      "PC98"  => { type => 'leaf', value_type => "boolean" },

      "HandleSpecialKeys"      => { type => 'leaf', value_type => "enum", 
				    built_in => 'WhenNeeded', 
				    choice => [qw/Always Never WhenNeeded/] },

     ],
  'permission' => [
		   [qw/NoTrapSignals VTInit/] => 'master',
		  ],
  'description'
  => [

      "DefaultServerLayout" => 'This specifies the default ServerLayout section to use in the absence of the layout command line option.',

      "NoTrapSignals" => 'This prevents the Xorg server from trapping a range of unexpected fatal signals and exiting cleanly. Instead, the Xorg server will die and drop core where the fault occurred. The default behaviour is for the Xorg server to exit cleanly, but still drop a core file. In general you never want to use this option unless you are debugging an Xorg server problem and know how to deal with the consequences.' ,

      "DontVTSwitch" => 'This disallows the use of the Ctrl+Alt+Fn sequence (where Fn refers to one of the numbered function keys). That sequence is normally used to switch to another "virtual terminal" on operating systems that have this feature. When this option is enabled, that key sequence has no special meaning and is passed to clients. Default: off.',

      "DontZap" => 'This disallows the use of the Ctrl+Alt+Backspace sequence. That sequence is normally used to terminate the Xorg server. When this option is enabled, that key sequence has no special meaning and is passed to clients. Default: off.',

      "DontZoom" => 'This disallows the use of the Ctrl+Alt+Keypad-Plus and Ctrl+Alt+Keypad-Minus sequences. These sequences allows you to switch between video modes. When this option is enabled, those key sequences have no special meaning and are passed to clients. Default: off.',

      "DisableVidModeExtension" =>'This disables the parts of the VidMode extension used by the xvidtune client that can be used to change the video modes. Default: the VidMode extension is enabled.',

      "AllowNonLocalXvidtune" => 'This allows the xvidtune client (and other clients that use the VidMode extension) to connect from another host. Default: off.',

      "DisableModInDev" => 'This disables the parts of the Xorg-Misc extension that can be used to modify the input device settings dynamically. Default: that functionality is enabled.',

      "AllowNonLocalModInDev" => 'This allows a client to connect from another host and change keyboard and mouse settings in the running server. Default: off.',

      "AllowMouseOpenFail" =>'This allows the server to start up even if the mouse device can\'t be opened/initialised. Default: false.',

      "VTInit" => 'Runs command after the VT used by the server has been opened. The command string is passed to "/bin/sh -c", and is run with the real user\'s id with stdin and stdout set to the VT. The purpose of this option is to allow system dependent VT initialisation commands to be run. This option should rarely be needed. Default: not set.',

      "VTSysReq" => 'enables the SYSV-style VT switch sequence for non-SYSV systems which support VT switching. This sequence is Alt-SysRq followed by a function key (Fn). This prevents the Xorg server trapping the keys used for the default VT switch sequence, which means that clients can access them. Default: off.',

      "XkbDisable" => 'disable/enable the XKEYBOARD extension. The -kb command line option overrides this config file option. Default: XKB is enabled.',

      "BlankTime" => 'sets the inactivity timeout for the blank phase of the screensaver. time is in minutes. This is equivalent to the Xorg server\'s -s flag, and the value can be changed at run-time with xset(1). Default: 10 minutes.',

      "StandbyTime" => 'sets the inactivity timeout for the standby phase of DPMS mode. time is in minutes, and the value can be changed at run-time with xset(1). Default: 20 minutes. This is only suitable for VESA DPMS compatible monitors, and may not be supported by all video drivers. It is only enabled for screens that have the "DPMS" option set (see the MONITOR section below).',

      "SuspendTime" => 'sets the inactivity timeout for the suspend phase of DPMS mode. time is in minutes, and the value can be changed at run-time with xset(1). Default: 30 minutes. This is only suitable for VESA DPMS compatible monitors, and may not be supported by all video drivers. It is only enabled for screens that have the "DPMS" option set (see the MONITOR section below).',

      "OffTime" => 'sets the inactivity timeout for the off phase of DPMS mode. time is in minutes, and the value can be changed at run-time with xset(1). Default: 40 minutes. This is only suitable for VESA DPMS compatible monitors, and may not be supported by all video drivers. It is only enabled for screens that have the "DPMS" option set (see the MONITOR section below).',

      "Pixmap" => 'This sets the pixmap format to use for depth 24. Allowed values for bpp are 24 and 32. Default: 32 unless driver constraints don\'t allow this (which is rare). Note: some clients don\'t behave well when this value is set to 24.',

      "PC98" => 'Specify that the machine is a Japanese PC-98 machine. This should not be enabled for anything other than the Japanese-specific PC-98 architecture. Default: auto-detected.',

      "NoPM" => 'Disables something to do with power management events. Default: PM enabled on platforms that support it.',

      "Xinerama" => 'enable or disable XINERAMA extension. Default is disabled.',

      "AllowDeactivateGrabs" => 'This option enables the use of the Ctrl+Alt+Keypad-Divide key sequence to deactivate any active keyboard and mouse grabs. Default: off.',

      "AllowClosedownGrabs" => 'This option enables the use of the Ctrl+Alt+Keypad-Multiply key sequence to kill clients with an active keyboard or mouse grab as well as killing any application that may have locked the server, normally using the XGrabServer(3) Xlib function. Default: off. Note that the options AllowDeactivateGrabs and AllowClosedownGrabs will allow users to remove the grab used by screen saver/locker programs. An API was written to such cases. If you enable this option, make sure your screen saver/locker is updated. Default: off.',

      "HandleSpecialKeys" => 'This option controls when the server uses the builtin handler to process special key combinations (such as Ctrl+Alt+Backspace). Normally the XKEYBOARD extension keymaps will provide mappings for each of the special key combinations, so the builtin handler is not needed unless the XKEYBOARD extension is disabled. The value of when can be Always, Never, or WhenNeeded. Default: Use the builtin handler only if needed. The server will scan the keymap for a mapping to the Terminate action and, if found, use XKEYBOARD for processing actions, otherwise the builtin handler will be used.',

      "IgnoreABI" => 'Allow modules built for a different, potentially incompatible version of the X server to load. Disabled by default.',

     ],
 ],

] ;
