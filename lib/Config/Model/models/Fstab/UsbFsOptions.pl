use strict;
use warnings;
use v5.20;
use utf8;

return [
  {
    'author' => [
      'Dominique Dumont'
    ],
    'class_description' => 'usbfs options',
    'copyright' => [
      '2010,2011 Dominique Dumont'
    ],
    'element' => [
      'devuid',
      {
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'integer'
      },
      'devgid',
      '*devuid',
      'busuid',
      '*devuid',
      'budgid',
      '*devuid',
      'listuid',
      '*devuid',
      'listgid',
      '*devuid',
      'devmode',
      {
        'type' => 'leaf',
        'upstream_default' => '0644',
        'value_type' => 'integer'
      },
      'busmode',
      {
        'type' => 'leaf',
        'upstream_default' => '0555',
        'value_type' => 'integer'
      },
      'listmode',
      {
        'type' => 'leaf',
        'upstream_default' => '0444',
        'value_type' => 'integer'
      }
    ],
    'include' => [
      'Fstab::CommonOptions'
    ],
    'license' => 'LGPL2',
    'name' => 'Fstab::UsbFsOptions'
  }
]
;
