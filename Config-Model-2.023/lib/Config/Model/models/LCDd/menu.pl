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
    'name' => 'LCDd::menu',
    'element' => [
      'MenuKey',
      {
        'value_type' => 'uniline',
        'default' => 'Escape',
        'type' => 'leaf',
        'description' => 'You can configure what keys the menu should use. Note that the MenuKey
will be reserved exclusively, the others work in shared mode.
Up to six keys are supported. The MenuKey (to enter and exit the menu), the
EnterKey (to select values) and at least one movement keys are required.
These are the default key assignments:'
      },
      'EnterKey',
      {
        'value_type' => 'uniline',
        'default' => 'Enter',
        'type' => 'leaf'
      },
      'UpKey',
      {
        'value_type' => 'uniline',
        'default' => 'Up',
        'type' => 'leaf'
      },
      'DownKey',
      {
        'value_type' => 'uniline',
        'default' => 'Down',
        'type' => 'leaf'
      },
      'LeftKey',
      {
        'value_type' => 'uniline',
        'default' => 'Left',
        'type' => 'leaf'
      },
      'RightKey',
      {
        'value_type' => 'uniline',
        'default' => 'Right',
        'type' => 'leaf'
      }
    ]
  }
]
;

