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
    'name' => 'LCDd::picolcd',
    'element' => [
      'KeyTimeout',
      {
        'value_type' => 'integer',
        'min' => '0',
        'upstream_default' => '500',
        'max' => '1000',
        'type' => 'leaf',
        'description' => 'KeyTimeout is the time in ms that LCDd spends waiting for a key press before
cycling through other duties.  Higher values make LCDd use less CPU time and
make key presses more detectable.  Lower values make LCDd more responsive
but a little prone to missing key presses.  500 (.5 second) is the default
and a balanced value. '
      },
      'Backlight',
      {
        'value_type' => 'enum',
        'upstream_default' => 'on',
        'type' => 'leaf',
        'description' => 'Sets the initial state of the backlight upon start-up.',
        'choice' => [
          'on',
          'off'
        ]
      },
      'Brightness',
      {
        'value_type' => 'integer',
        'min' => '0',
        'upstream_default' => '1000',
        'max' => '1000',
        'type' => 'leaf',
        'description' => 'Set the initial brightness . Works only
with the 20x4 device'
      },
      'OffBrightness',
      {
        'value_type' => 'integer',
        'min' => '0',
        'upstream_default' => '0',
        'max' => '1000',
        'type' => 'leaf',
        'description' => 'Set the brightness while the backlight is \'off\' .
Works only with the 20x4 device.'
      },
      'Contrast',
      {
        'value_type' => 'integer',
        'min' => '0',
        'upstream_default' => '1000',
        'max' => '1000',
        'type' => 'leaf',
        'description' => 'Set the initial contrast '
      },
      'Keylights',
      {
        'value_type' => 'enum',
        'upstream_default' => 'on',
        'type' => 'leaf',
        'description' => 'Light the keys? ',
        'choice' => [
          'on',
          'off'
        ]
      },
      'Key0Light',
      {
        'value_type' => 'enum',
        'upstream_default' => 'on',
        'type' => 'leaf',
        'description' => 'If Keylights is on, the you can unlight specific keys below:
Key0 is the directional pad.  Key1 - Key5 correspond to the F1 - F5 keys.
There is no LED for the +/- keys.  This is a handy way to indicate to users
which keys are disabled.  ',
        'choice' => [
          'on',
          'off'
        ]
      },
      'Key1Light',
      {
        'value_type' => 'uniline',
        'default' => 'on',
        'type' => 'leaf'
      },
      'Key2Light',
      {
        'value_type' => 'uniline',
        'default' => 'on',
        'type' => 'leaf'
      },
      'Key3Light',
      {
        'value_type' => 'uniline',
        'default' => 'on',
        'type' => 'leaf'
      },
      'Key4Light',
      {
        'value_type' => 'uniline',
        'default' => 'on',
        'type' => 'leaf'
      },
      'Key5Light',
      {
        'value_type' => 'uniline',
        'default' => 'on',
        'type' => 'leaf'
      },
      'LircHost',
      {
        'value_type' => 'uniline',
        'default' => '127.0.0.1',
        'type' => 'leaf',
        'description' => 'Host name or IP address of the LIRC instance that is to receive IR codes
If not set, or set to an empty value, IR support is disabled.'
      },
      'LircPort',
      {
        'value_type' => 'integer',
        'min' => '1',
        'upstream_default' => '8765',
        'max' => '65535',
        'type' => 'leaf',
        'description' => 'UDP port on which LIRC is listening '
      },
      'LircFlushThreshold',
      {
        'value_type' => 'integer',
        'upstream_default' => '100',
        'max' => '32767',
        'type' => 'leaf',
        'description' => 'Threshold in jiffies of synthesized gap that triggers flushing the IR data
to lirc 
100 means 6.1ms. legal: 16 - 32767; Use 0 to disable.'
      }
    ]
  }
]
;

