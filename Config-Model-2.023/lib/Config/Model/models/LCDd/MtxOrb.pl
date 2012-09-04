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
    'name' => 'LCDd::MtxOrb',
    'element' => [
      'Device',
      {
        'value_type' => 'uniline',
        'upstream_default' => '/dev/lcd',
        'type' => 'leaf',
        'description' => 'Select the output device to use '
      },
      'Size',
      {
        'value_type' => 'uniline',
        'upstream_default' => '20x4',
        'type' => 'leaf',
        'description' => 'Set the display size '
      },
      'Type',
      {
        'value_type' => 'enum',
        'upstream_default' => 'lcd',
        'type' => 'leaf',
        'description' => 'Set the display type ',
        'choice' => [
          'lcd',
          'lkd',
          'vfd',
          'vkd'
        ]
      },
      'Contrast',
      {
        'value_type' => 'uniline',
        'upstream_default' => '480',
        'type' => 'leaf',
        'description' => 'Set the initial contrast 
NOTE: The driver will ignore this if the display
      is a vfd or vkd as they don\'t have this feature'
      },
      'hasAdjustableBacklight',
      {
        'value_type' => 'enum',
        'upstream_default' => 'yes',
        'type' => 'leaf',
        'description' => 'Some old displays do not have an adjustable backlight but only can
switch the backlight on/off. If you experience randomly appearing block
characters, try setting this to false. ',
        'choice' => [
          'yes',
          'no'
        ]
      },
      'Brightness',
      {
        'value_type' => 'integer',
        'min' => '0',
        'upstream_default' => '1000',
        'max' => '1000',
        'type' => 'leaf',
        'description' => 'Set the initial brightness '
      },
      'OffBrightness',
      {
        'value_type' => 'integer',
        'min' => '0',
        'upstream_default' => '0',
        'max' => '1000',
        'type' => 'leaf',
        'description' => 'Set the initial off-brightness 
This value is used when the display is normally
switched off in case LCDd is inactive'
      },
      'Speed',
      {
        'value_type' => 'enum',
        'upstream_default' => '19200',
        'type' => 'leaf',
        'description' => 'Set the communication speed ',
        'choice' => [
          '1200',
          '2400',
          '9600',
          '19200'
        ]
      },
      'KeyMap_A',
      {
        'value_type' => 'uniline',
        'default' => 'Left',
        'type' => 'leaf',
        'description' => 'The following table translates from MtxOrb key letters to logical key names.
By default no keys are mapped, meaning the keypad is not used at all.'
      },
      'KeyMap_B',
      {
        'value_type' => 'uniline',
        'default' => 'Right',
        'type' => 'leaf'
      },
      'KeyMap_C',
      {
        'value_type' => 'uniline',
        'default' => 'Up',
        'type' => 'leaf'
      },
      'KeyMap_D',
      {
        'value_type' => 'uniline',
        'default' => 'Down',
        'type' => 'leaf'
      },
      'KeyMap_E',
      {
        'value_type' => 'uniline',
        'default' => 'Enter',
        'type' => 'leaf'
      },
      'KeyMap_F',
      {
        'value_type' => 'uniline',
        'default' => 'Escape',
        'type' => 'leaf'
      },
      'keypad_test_mode',
      {
        'value_type' => 'uniline',
        'default' => 'no',
        'type' => 'leaf',
        'description' => 'See the [menu] section for an explanation of the key mappings
You can find out which key of your display sends which
character by setting keypad_test_mode to yes and running
LCDd. LCDd will output all characters it receives.
Afterwards you can modify the settings above and set
keypad_set_mode to no again.'
      }
    ]
  }
]
;

