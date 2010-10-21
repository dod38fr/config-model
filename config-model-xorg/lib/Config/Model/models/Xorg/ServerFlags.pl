[
          {
            'name' => 'Xorg::ServerFlags',
            'element' => [
                           'DefaultServerLayout',
                           {
                             'value_type' => 'reference',
                             'type' => 'leaf',
                             'description' => 'This specifies the default ServerLayout section to use in the absence of the layout command line option.',
                             'refer_to' => '! ServerLayout'
                           },
                           'NoTrapSignals',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 0,
                             'type' => 'leaf',
                             'description' => 'This disables the parts of the Xorg-Misc extension that can be used to modify the input device settings dynamically. Default: that functionality is enabled.'
                           },
                           'DontVTSwitch',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 0,
                             'type' => 'leaf',
                             'description' => 'This disables the parts of the Xorg-Misc extension that can be used to modify the input device settings dynamically. Default: that functionality is enabled.'
                           },
                           'DontZap',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 0,
                             'type' => 'leaf',
                             'description' => 'This disables the parts of the Xorg-Misc extension that can be used to modify the input device settings dynamically. Default: that functionality is enabled.'
                           },
                           'DontZoom',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 0,
                             'type' => 'leaf',
                             'description' => 'This disables the parts of the Xorg-Misc extension that can be used to modify the input device settings dynamically. Default: that functionality is enabled.'
                           },
                           'DisableVidModeExtension',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 0,
                             'type' => 'leaf',
                             'description' => 'This disables the parts of the Xorg-Misc extension that can be used to modify the input device settings dynamically. Default: that functionality is enabled.'
                           },
                           'AllowNonLocalXvidtune',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 0,
                             'type' => 'leaf',
                             'description' => 'This disables the parts of the Xorg-Misc extension that can be used to modify the input device settings dynamically. Default: that functionality is enabled.'
                           },
                           'DisableModInDev',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 0,
                             'type' => 'leaf',
                             'description' => 'This disables the parts of the Xorg-Misc extension that can be used to modify the input device settings dynamically. Default: that functionality is enabled.'
                           },
                           'AllowMouseOpenFail',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 0,
                             'type' => 'leaf',
                             'description' => 'This disables the parts of the Xorg-Misc extension that can be used to modify the input device settings dynamically. Default: that functionality is enabled.'
                           },
                           'VTSysReq',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 0,
                             'type' => 'leaf',
                             'description' => 'This disables the parts of the Xorg-Misc extension that can be used to modify the input device settings dynamically. Default: that functionality is enabled.'
                           },
                           'XkbDisable',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 0,
                             'type' => 'leaf',
                             'description' => 'This disables the parts of the Xorg-Misc extension that can be used to modify the input device settings dynamically. Default: that functionality is enabled.'
                           },
                           'NoPM',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 0,
                             'type' => 'leaf',
                             'description' => 'This disables the parts of the Xorg-Misc extension that can be used to modify the input device settings dynamically. Default: that functionality is enabled.'
                           },
                           'Xinerama',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 0,
                             'type' => 'leaf',
                             'description' => 'This disables the parts of the Xorg-Misc extension that can be used to modify the input device settings dynamically. Default: that functionality is enabled.'
                           },
                           'AllowDeactivateGrabs',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 0,
                             'type' => 'leaf',
                             'description' => 'This disables the parts of the Xorg-Misc extension that can be used to modify the input device settings dynamically. Default: that functionality is enabled.'
                           },
                           'AllowClosedownGrabs',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 0,
                             'type' => 'leaf',
                             'description' => 'This disables the parts of the Xorg-Misc extension that can be used to modify the input device settings dynamically. Default: that functionality is enabled.'
                           },
                           'IgnoreABI',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 0,
                             'type' => 'leaf',
                             'description' => 'This disables the parts of the Xorg-Misc extension that can be used to modify the input device settings dynamically. Default: that functionality is enabled.'
                           },
                           'VTInit',
                           {
                             'value_type' => 'uniline',
                             'experience' => 'master',
                             'type' => 'leaf',
                             'description' => 'Runs command after the VT used by the server has been opened. The command string is passed to "/bin/sh -c", and is run with the real user\'s id with stdin and stdout set to the VT. The purpose of this option is to allow system dependent VT initialisation commands to be run. This option should rarely be needed. Default: not set.'
                           },
                           'BlankTime',
                           {
                             'value_type' => 'integer',
                             'upstream_default' => 10,
                             'type' => 'leaf',
                             'description' => 'sets the inactivity timeout for the blank phase of the screensaver. time is in minutes. This is equivalent to the Xorg server\'s -s flag, and the value can be changed at run-time with xset(1). Default: 10 minutes.'
                           },
                           'StandbyTime',
                           {
                             'value_type' => 'integer',
                             'upstream_default' => 20,
                             'type' => 'leaf',
                             'description' => 'sets the inactivity timeout for the standby phase of DPMS mode. time is in minutes, and the value can be changed at run-time with xset(1). Default: 20 minutes. This is only suitable for VESA DPMS compatible monitors, and may not be supported by all video drivers. It is only enabled for screens that have the "DPMS" option set (see the MONITOR section below).'
                           },
                           'SuspendTime',
                           {
                             'value_type' => 'integer',
                             'upstream_default' => 30,
                             'type' => 'leaf',
                             'description' => 'sets the inactivity timeout for the suspend phase of DPMS mode. time is in minutes, and the value can be changed at run-time with xset(1). Default: 30 minutes. This is only suitable for VESA DPMS compatible monitors, and may not be supported by all video drivers. It is only enabled for screens that have the "DPMS" option set (see the MONITOR section below).'
                           },
                           'OffTime',
                           {
                             'value_type' => 'integer',
                             'upstream_default' => 40,
                             'type' => 'leaf',
                             'description' => 'sets the inactivity timeout for the off phase of DPMS mode. time is in minutes, and the value can be changed at run-time with xset(1). Default: 40 minutes. This is only suitable for VESA DPMS compatible monitors, and may not be supported by all video drivers. It is only enabled for screens that have the "DPMS" option set (see the MONITOR section below).'
                           },
                           'Pixmap',
                           {
                             'value_type' => 'enum',
                             'upstream_default' => 32,
                             'type' => 'leaf',
                             'description' => 'This sets the pixmap format to use for depth 24. Allowed values for bpp are 24 and 32. Default: 32 unless driver constraints don\'t allow this (which is rare). Note: some clients don\'t behave well when this value is set to 24.',
                             'choice' => [
                                           24,
                                           32
                                         ]
                           },
                           'PC98',
                           {
                             'value_type' => 'boolean',
                             'type' => 'leaf',
                             'description' => 'Specify that the machine is a Japanese PC-98 machine. This should not be enabled for anything other than the Japanese-specific PC-98 architecture. Default: auto-detected.'
                           },
                           'HandleSpecialKeys',
                           {
                             'value_type' => 'enum',
                             'upstream_default' => 'WhenNeeded',
                             'type' => 'leaf',
                             'description' => 'This option controls when the server uses the builtin handler to process special key combinations (such as Ctrl+Alt+Backspace). Normally the XKEYBOARD extension keymaps will provide mappings for each of the special key combinations, so the builtin handler is not needed unless the XKEYBOARD extension is disabled. The value of when can be Always, Never, or WhenNeeded. Default: Use the builtin handler only if needed. The server will scan the keymap for a mapping to the Terminate action and, if found, use XKEYBOARD for processing actions, otherwise the builtin handler will be used.',
                             'choice' => [
                                           'Always',
                                           'Never',
                                           'WhenNeeded'
                                         ]
                           },
                           'AIGLX',
                           {
                             'value_type' => 'enum',
                             'upstream_default' => 'on',
                             'type' => 'leaf',
                             'description' => 'enable or disable AIGLX.',
                             'choice' => [
                                           'off',
                                           'on'
                                         ]
                           },
                           'UseDefaultFontPath',
                           {
                             'value_type' => 'enum',
                             'upstream_default' => 'on',
                             'type' => 'leaf',
                             'description' => 'Include the default font path even if other paths are specified in xorg.conf. If enabled, other font paths are included as well.',
                             'choice' => [
                                           'off',
                                           'on'
                                         ]
                           }
                         ]
          }
        ]
;
