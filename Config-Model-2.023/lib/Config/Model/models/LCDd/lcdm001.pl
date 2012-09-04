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
    'name' => 'LCDd::lcdm001',
    'element' => [
      'Device',
      {
        'value_type' => 'uniline',
        'default' => '/dev/ttyS1',
        'type' => 'leaf'
      },
      'PauseKey',
      {
        'value_type' => 'uniline',
        'default' => 'LeftKey',
        'type' => 'leaf',
        'description' => 'keypad settings
Keyname      Function
             Normal context              Menu context
-------      --------------              ------------
PauseKey     Pause/Continue              Enter/select
BackKey      Back(Go to previous screen) Up/Left
ForwardKey   Forward(Go to next screen)  Down/Right
MainMenuKey  Open main menu              Exit/Cancel'
      },
      'BackKey',
      {
        'value_type' => 'uniline',
        'default' => 'UpKey',
        'type' => 'leaf'
      },
      'ForwardKey',
      {
        'value_type' => 'uniline',
        'default' => 'DownKey',
        'type' => 'leaf'
      },
      'MainMenuKey',
      {
        'value_type' => 'uniline',
        'default' => 'RightKey',
        'type' => 'leaf'
      }
    ]
  }
]
;

