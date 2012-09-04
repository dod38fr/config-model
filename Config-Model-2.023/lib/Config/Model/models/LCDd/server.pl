#
# This file is part of Config-Model
#
# This software is Copyright (c) 2012 by Dominique Dumont, Krzysztof Tyszecki.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
[
  {
    'class_description' => 'generated from LCDd.conf',
    'name' => 'LCDd::server',
    'element' => [
      'DriverPath',
      {
        'value_type' => 'uniline',
        'default' => 'server/drivers/',
        'type' => 'leaf',
        'description' => 'Where can we find the driver modules ?
IMPORTANT: Make sure to change this setting to reflect your
           specific setup! Otherwise LCDd won\'t be able to find
           the driver modules and will thus not be able to
           function properly.
NOTE: Always place a slash as last character !'
      },
      'Driver',
      {
        'value_type' => 'enum',
        'type' => 'leaf',
        'description' => 'Tells the server to load the given drivers. Multiple lines can be given.
The name of the driver is case sensitive and determines the section
where to look for further configuration options of the specific driver
as well as the name of the dynamic driver module to load at runtime.
The latter one can be changed by giving a File= directive in the
driver specific section.

The following drivers are supported:
  bayrad, CFontz, CFontzPacket, curses, CwLnx, ea65,
  EyeboxOne, g15, glcdlib, glk, hd44780, icp_a106, imon, imonlcd,
  IOWarrior, irman, joy, lb216, lcdm001, lcterm, lirc, lis, MD8800,
  mdm166a, ms6931, mtc_s16209x, MtxOrb, mx5000, NoritakeVFD, picolcd,
  pyramid, sed1330, sed1520, serialPOS, serialVFD, shuttleVFD, sli,
  stv5730, svga, t6963, text, tyan, ula200, vlsys_m428, xosd',
        'choice' => [
          'bayrad',
          'CFontz',
          'CFontzPacket',
          'curses',
          'CwLnx',
          'ea65',
          'EyeboxOne',
          'g15',
          'glcdlib',
          'glk',
          'hd44780',
          'icp_a106',
          'imon',
          'imonlcd',
          'IOWarrior',
          'irman',
          'joy',
          'lb216',
          'lcdm001',
          'lcterm',
          'lirc',
          'lis',
          'MD8800',
          'mdm166a',
          'ms6931',
          'mtc_s16209x',
          'MtxOrb',
          'mx5000',
          'NoritakeVFD',
          'picolcd',
          'pyramid',
          'sed1330',
          'sed1520',
          'serialPOS',
          'serialVFD',
          'shuttleVFD',
          'sli',
          'stv5730',
          'svga',
          't6963',
          'text',
          'tyan',
          'ula200',
          'vlsys_m428',
          'xosd'
        ]
      },
      'Bind',
      {
        'value_type' => 'uniline',
        'default' => '127.0.0.1',
        'type' => 'leaf',
        'description' => 'Tells the driver to bind to the given interface'
      },
      'Port',
      {
        'value_type' => 'integer',
        'default' => '13666',
        'type' => 'leaf',
        'description' => 'Listen on this specified port; defaults to 13666.'
      },
      'ReportLevel',
      {
        'value_type' => 'integer',
        'default' => '3',
        'type' => 'leaf',
        'description' => 'Sets the reporting level; defaults to 2 (warnings and errors only).'
      },
      'ReportToSyslog',
      {
        'value_type' => 'enum',
        'upstream_default' => 'no',
        'type' => 'leaf',
        'description' => 'Should we report to syslog instead of stderr ? ',
        'choice' => [
          'yes',
          'no'
        ]
      },
      'User',
      {
        'value_type' => 'uniline',
        'default' => 'nobody',
        'type' => 'leaf',
        'description' => 'User to run as.  LCDd will drop its root privileges, if any,
and run as this user instead.'
      },
      'Foreground',
      {
        'value_type' => 'uniline',
        'default' => 'no',
        'type' => 'leaf',
        'description' => 'The server will stay in the foreground if set to true.'
      },
      'Hello',
      {
        'cargo' => {
          'value_type' => 'uniline',
          'type' => 'leaf'
        },
        'default_with_init' => {
          '1' => '"    LCDproc!"',
          '0' => '"    Hello"'
        },
        'type' => 'list',
        'description' => 'Hello message: each entry represents a display line; default: builtin'
      },
      'GoodBye',
      {
        'cargo' => {
          'value_type' => 'uniline',
          'type' => 'leaf'
        },
        'default_with_init' => {
          '1' => '"    LCDproc!"',
          '0' => '"    GoodBye"'
        },
        'type' => 'list',
        'description' => 'GoodBye message: each entry represents a display line; default: builtin'
      },
      'WaitTime',
      {
        'value_type' => 'integer',
        'default' => '5',
        'type' => 'leaf',
        'description' => 'Sets the default time in seconds to displays a screen.'
      },
      'AutoRotate',
      {
        'value_type' => 'enum',
        'upstream_default' => 'on',
        'type' => 'leaf',
        'description' => 'If set to no, LCDd will start with screen rotation disabled. This has the
same effect as if the ToggleRotateKey had been pressed. Rotation will start
if the ToggleRotateKey is pressed. Note that this setting does not turn off
priority sorting of screens. ',
        'choice' => [
          'on',
          'off'
        ]
      },
      'ServerScreen',
      {
        'value_type' => 'enum',
        'upstream_default' => 'on',
        'type' => 'leaf',
        'description' => 'If yes, the the serverscreen will be rotated as a usual info screen. If no,
it will be a background screen, only visible when no other screens are
active. The special value \'blank\' is similar to no, but only a blank screen
is displayed. ',
        'choice' => [
          'on',
          'off',
          'blank'
        ]
      },
      'Backlight',
      {
        'value_type' => 'enum',
        'upstream_default' => 'open',
        'type' => 'leaf',
        'description' => 'Set master backlight setting. If set to \'open\' a client may control the
backlight for its own screens (only). ',
        'choice' => [
          'off',
          'open',
          'on'
        ]
      },
      'Heartbeat',
      {
        'value_type' => 'enum',
        'upstream_default' => 'open',
        'type' => 'leaf',
        'description' => 'Set master heartbeat setting. If set to \'open\' a client may control the
heartbeat for its own screens (only). ',
        'choice' => [
          'off',
          'open',
          'on'
        ]
      },
      'TitleSpeed',
      {
        'value_type' => 'integer',
        'min' => '0',
        'upstream_default' => '10',
        'max' => '10',
        'type' => 'leaf',
        'description' => 'set title scrolling speed '
      },
      'ToggleRotateKey',
      {
        'value_type' => 'uniline',
        'default' => 'Enter',
        'type' => 'leaf',
        'description' => 'The "...Key=" lines define what the server does with keypresses that
don\'t go to any client. The ToggleRotateKey stops rotation of screens, while
the PrevScreenKey and NextScreenKey go back / forward one screen (even if
rotation is disabled.
Assign the key string returned by the driver to the ...Key setting. These
are the defaults:'
      },
      'PrevScreenKey',
      {
        'value_type' => 'uniline',
        'default' => 'Left',
        'type' => 'leaf'
      },
      'NextScreenKey',
      {
        'value_type' => 'uniline',
        'default' => 'Right',
        'type' => 'leaf'
      },
      'ScrollUpKey',
      {
        'value_type' => 'uniline',
        'default' => 'Up',
        'type' => 'leaf'
      },
      'ScrollDownKey',
      {
        'value_type' => 'uniline',
        'default' => 'Down',
        'type' => 'leaf'
      }
    ]
  }
]
;

