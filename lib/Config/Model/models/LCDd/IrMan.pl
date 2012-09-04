[
  {
    'class_description' => 'generated from LCDd.conf',
    'name' => 'LCDd::IrMan',
    'element' => [
      'Device',
      {
        'value_type' => 'uniline',
        'default' => '/dev/irman',
        'type' => 'leaf',
        'description' => 'in case of trouble with IrMan, try the Lirc emulator for IrMan
Select the input device to use'
      },
      'Config',
      {
        'value_type' => 'uniline',
        'default' => '/etc/irman.cfg',
        'type' => 'leaf',
        'description' => 'Select the configuration file to use'
      }
    ]
  }
]
;

