[
          {
            'name' => 'Xorg::Screen::Option',
            'element' => [
                           'Accel',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 1,
                             'type' => 'leaf',
                             'description' => 'Enables XAA (X Acceleration Architecture), a mechanism that makes video cards\' 2D hardware acceleration available to the __xservername__ server. This option is on by default, but it may be necessary to turn it off if there are bugs in the driver. There are many options to disable specific accelerated operations, listed below.  Note that disabling an operation will have no effect if the operation is not accelerated (whether due to lack of support in the hardware or in the driver).'
                           },
                           'InitPrimary',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 0,
                             'type' => 'leaf',
                             'description' => 'Disables accelerated dashed line draws between two arbitrary points.'
                           },
                           'NoInt10',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 0,
                             'type' => 'leaf',
                             'description' => 'Disables accelerated dashed line draws between two arbitrary points.'
                           },
                           'NoMTRR',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 0,
                             'type' => 'leaf',
                             'description' => 'Disables accelerated dashed line draws between two arbitrary points.'
                           },
                           'XaaNoCPUToScreenColorExpandFill',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 0,
                             'type' => 'leaf',
                             'description' => 'Disables accelerated dashed line draws between two arbitrary points.'
                           },
                           'XaaNoColor8x8PatternFillRect',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 0,
                             'type' => 'leaf',
                             'description' => 'Disables accelerated dashed line draws between two arbitrary points.'
                           },
                           'XaaNoColor8x8PatternFillTrap',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 0,
                             'type' => 'leaf',
                             'description' => 'Disables accelerated dashed line draws between two arbitrary points.'
                           },
                           'XaaNoDashedBresenhamLine',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 0,
                             'type' => 'leaf',
                             'description' => 'Disables accelerated dashed line draws between two arbitrary points.'
                           },
                           'XaaNoDashedTwoPointLine',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 0,
                             'type' => 'leaf',
                             'description' => 'Disables accelerated dashed line draws between two arbitrary points.'
                           },
                           'XaaNoImageWriteRect',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 0,
                             'type' => 'leaf',
                             'description' => 'Disables accelerated dashed line draws between two arbitrary points.'
                           },
                           'XaaNoMono8x8PatternFillRect',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 0,
                             'type' => 'leaf',
                             'description' => 'Disables accelerated dashed line draws between two arbitrary points.'
                           },
                           'XaaNoMono8x8PatternFillTrap',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 0,
                             'type' => 'leaf',
                             'description' => 'Disables accelerated dashed line draws between two arbitrary points.'
                           },
                           'XaaNoOffscreenPixmaps',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 0,
                             'type' => 'leaf',
                             'description' => 'Disables accelerated dashed line draws between two arbitrary points.'
                           },
                           'XaaNoPixmapCache',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 0,
                             'type' => 'leaf',
                             'description' => 'Disables accelerated dashed line draws between two arbitrary points.'
                           },
                           'XaaNoScanlineCPUToScreenColorExpandFill',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 0,
                             'type' => 'leaf',
                             'description' => 'Disables accelerated dashed line draws between two arbitrary points.'
                           },
                           'XaaNoScanlineImageWriteRect',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 0,
                             'type' => 'leaf',
                             'description' => 'Disables accelerated dashed line draws between two arbitrary points.'
                           },
                           'XaaNoScreenToScreenColorExpandFill',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 0,
                             'type' => 'leaf',
                             'description' => 'Disables accelerated dashed line draws between two arbitrary points.'
                           },
                           'XaaNoScreenToScreenCopy',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 0,
                             'type' => 'leaf',
                             'description' => 'Disables accelerated dashed line draws between two arbitrary points.'
                           },
                           'XaaNoSolidBresenhamLine',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 0,
                             'type' => 'leaf',
                             'description' => 'Disables accelerated dashed line draws between two arbitrary points.'
                           },
                           'XaaNoSolidFillRect',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 0,
                             'type' => 'leaf',
                             'description' => 'Disables accelerated dashed line draws between two arbitrary points.'
                           },
                           'XaaNoSolidFillTrap',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 0,
                             'type' => 'leaf',
                             'description' => 'Disables accelerated dashed line draws between two arbitrary points.'
                           },
                           'XaaNoSolidHorVertLine',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 0,
                             'type' => 'leaf',
                             'description' => 'Disables accelerated dashed line draws between two arbitrary points.'
                           },
                           'XaaNoSolidTwoPointLine',
                           {
                             'value_type' => 'boolean',
                             'upstream_default' => 0,
                             'type' => 'leaf',
                             'description' => 'Disables accelerated dashed line draws between two arbitrary points.'
                           },
                           'BiosLocation',
                           {
                             'value_type' => 'uniline',
                             'experience' => 'master',
                             'type' => 'leaf',
                             'description' => 'Set the location of the BIOS for the Int10 module. One may select a BIOS of another card for posting or the legacy V_BIOS range located at 0xc0000 or an alterna- tive address (BUS_ISA). This is only useful under very special circumstances and should be used with extreme care.'
                           }
                         ]
          }
        ]
;
