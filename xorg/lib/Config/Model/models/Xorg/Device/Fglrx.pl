[
          {
            'class_description' => 'Fglrx model. This model was written from Debian flgrx man page. It may be out of date compared to latest flgrx release from  AMD',
            'name' => 'Xorg::Device::Fglrx',
            'element' => [
                           'AGPMask',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf',
                             'description' => 'This option applies to AGPv1/2. To handle an AGPv3 interface, you will additionally need Option "AGPv3Mask".

  "0x00000001" Disable AGP 1x (forces 2x or 4x).
  "0x00000002" Disable AGP 2x (forces 1x or 4x).
  "0x00000004" Disable AGP 4x (forces 1x or 2x).
  "0x00000010" Disable fast-writes.
  "0x00000200" Disable sidebanding.

To combine several settings, only add the values. Let me show an example: "0x00000216" means: force AGP 1x (disable AGP 2x and 4x), disable fast-writes and sidebanding.

You can check, if fast-writes has been disabled by searching your kernel log for "AgpCommand = hex-integer". The second last hex digit should be 0 (zero) if fast-writes is off, or 1 (one) if it is on.'
                           },
                           'AGPv3Mask',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf',
                             'description' => 'This option only applies to AGPv3.

Important: It is used in addition to Option "AGPMask". That means, that you turn off fast-writes or sidebanding with Option "AGPMask".
"0x00000001" Disable AGP 4x (forces 8x).
"0x00000002" Disable AGP 8x (forces 4x).'
                           },
                           'AGP8XDisableFix',
                           {
                             'value_type' => 'enum',
                             'type' => 'leaf',
                             'choice' => [
                                           'yes',
                                           'no'
                                         ]
                           },
                           'ASICClock',
                           {
                             'value_type' => 'integer',
                             'type' => 'leaf'
                           },
                           'BackingStore',
                           {
                             'value_type' => 'enum',
                             'upstream_default' => 'off',
                             'type' => 'leaf',
                             'description' => 'Enable or disable the "Backing store" mechanism. If this option is enabled, the X-server stores (parts of) the window content.',
                             'choice' => [
                                           'on',
                                           'off'
                                         ]
                           },
                           'BlockSignalsOnLock',
                           {
                             'value_type' => 'enum',
                             'type' => 'leaf',
                             'description' => 'To allow the debugging (using gdb(1), totalview(1) and others) of
           multi-threaded OpenGL applications it can become necessary to
           disable the blocking of task interruption signals. The default is:
           "on".

           "off"
               The driver will not use signal blocking. This introduces the
               risk of suffering memory leaks in combination with specific
               user activity.

               Caution
               Only use it, if you really know what you are doing.

           "on"
               The default value. The driver does not block signals for
               locking.

           As of now it is uncertain which is the real origin of the problem.
           As of now it does look like the debugger application is getting in
           some trouble because of not getting back the debugging control
           after the lock condition was removed by the driver. This might be
           further investigated.',
                             'choice' => [
                                           'on',
                                           'off'
                                         ]
                           },
                           'BufferTiling',
                           {
                             'value_type' => 'enum',
                             'type' => 'leaf',
                             'choice' => [
                                           'on',
                                           'off'
                                         ]
                           },
                           'BusType',
                           {
                             'value_type' => 'enum',
                             'type' => 'leaf',
                             'description' => '
           This option allows to overwrite the detected bus type. Use it, when
           the drivers bus detection is incorrect or when you want to force an
           AGP card to PCI bus. The default situation is, that the driver
           auto-detects the bus type. Possible values for this option are:

           "AGP"    AGP bus.

           "PCI"    PCI bus.
           "PCIE"   PCI Express bus (fallback: PCI).

           Caution
           NEVER try to force a PCI card to AGP bus.',
                             'choice' => [
                                           'AGP',
                                           'PCI',
                                           'PCIE'
                                         ]
                           },
                           'Capabilities',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf',
                             'description' => '
           ... hex ... Needs to be documented.

           "0x00000000"   Default.
           "0x00000800"   Disable VSync.
           "0x00008000"   Maya, Houdini 4.0, Houdini 5.0, Houdini
                          5.5.
           "0x20008000"   SOFTIMAGE|XSI, SOFTIMAGE|3D.'
                           },
                           'CapabilitiesEx',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf',
                             'description' => '... hex ... Needs to be documented.'
                           },
                           'CenterMode',
                           {
                             'value_type' => 'enum',
                             'type' => 'leaf',
                             'description' => '
           The Center-Mode allows "real" screen display in non-"panel native
           modes" (e.g. a resolution of 1280x1024 on a 1600x1200 LCD): one
           pixel of the frame buffer is one pixel on the screen. The display
           is centered on the screen and the surrounding screen area remains
           black. Note that some panels may not work in Center-Mode, so the
           screen remains black then. The default is: "off".',
                             'choice' => [
                                           'on',
                                           'off'
                                         ]
                           },
                           'ClientDriverName',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf',
                             'description' => 'Needs to be documented.'
                           },
                           'Dac6Bit',
                           {
                             'value_type' => 'enum',
                             'type' => 'leaf',
                             'description' => '
           Enables or disables the use of 6 bits per color component when in 8
           bpp mode (emulates VGA mode). By default, all 8 bits per color
           component are used. The default is: "off".',
                             'choice' => [
                                           'on',
                                           'off'
                                         ]
                           },
                           'DefaultVisualTrueColor',
                           {
                             'value_type' => 'enum',
                             'type' => 'leaf',
                             'description' => '
           Set the X-server to use a TrueColor visual as default. You can
           check the result with xpdyinfo(1). The default is: "off".',
                             'choice' => [
                                           'on',
                                           'off'
                                         ]
                           },
                           'DesktopSetup',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf',
                             'description' => '
This option defines the desktop setup. The driver can work with the
following modes:

"0x00000000"   "single"               Single head mode.
"0x00000100"   "clone"                Clone mode.
"0x00000101"   "mirror"               Mirror mode.
"0x00000200"   "horizontal"           Big Desktop mode.
"0x00000201"   "horizontal,reverse"   Big Desktop mode.
"0x00000300"   "vertical,reverse"     Big Desktop mode.
"0x00000301"   "vertical"             Big Desktop mode.
"0x00000000"                          Dual head mode.

The modes are:

Single head mode:
    Single monitor operation only. If a second monitor is
    connected, it remains dark. Only in this mode a full overlay
    functionality is available.

Clone mode:
    The contents of the primary monitor are duplicated on the
    second monitor. If one monitor cannot display the selected
    resolution, a lower resolution is automatically selected for
    this monitor. The original resolution is used then as it was
    specified as the virtual resolution. This means the second
    screen will do panning when the mouse moves ahead.

Mirror mode:
    The contents of the primary monitor are duplicated on the
    second monitor. Both monitors have an identical refresh rate
    and resolution.

    Important
    This mode is not supported on RADEON X1x00 and FireGL V3300,
    V3400, V5200, V7200, V7300, V7350 cards.

Big Desktop mode(s):
    There is a single big frame buffer that gets split either
    horizontally or vertically and each half is sent to a single
    monitor. Both monitors have to operate with the same video mode
    settings and only one window manager can be used. The
    orientation is set with:

    "0x00000200"   Primary display is left.
    "0x00000201"   Primary display is right.
    "0x00000300"   Primary display is top.
    "0x00000301"   Primary display is bottom.


Dual head mode:
    A dual head setup uses separate frame buffers, independent
    displays and video modes for each monitor. Two window managers
    can be used.


Note
A connected digital display is always the primary display. If two
display devices are connected, the primary head is: the bottom DVI
port on FireGL X1, LCD output on MOBILITY RADEON M9 and the only
DVI port on other cards. The secondary head is: the top DVI port on
FireGL X1 and the VGA port on all other cards.'
                           },
                           'DisableOvScaler',
                           {
                             'value_type' => 'enum',
                             'type' => 'leaf',
                             'description' => 'Needs to be documented.',
                             'choice' => [
                                           'yes',
                                           'no'
                                         ]
                           },
                           'DRM_bufsize',
                           {
                             'value_type' => 'integer',
                             'type' => 'leaf',
                             'description' => 'Needs to be documented. (number of DRM buffers - default 100, max 127)'
                           },
                           'DRM_nbufs',
                           {
                             'value_type' => 'integer',
                             'type' => 'leaf',
                             'description' => 'Needs to be documented. (DRM buffer size, default 65536 Byte, value in Byte)'
                           },
                           'EnableDepthMoves',
                           {
                             'value_type' => 'enum',
                             'type' => 'leaf',
                             'description' => 'Needs to be documented.',
                             'choice' => [
                                           'yes',
                                           'no'
                                         ]
                           },
                           'EnableHPV',
                           {
                             'value_type' => 'enum',
                             'type' => 'leaf',
                             'description' => 'Needs to be documented.',
                             'choice' => [
                                           'yes',
                                           'no'
                                         ]
                           },
                           'EnableLogo',
                           {
                             'value_type' => 'enum',
                             'type' => 'leaf',
                             'description' => 'Needs to be documented.',
                             'choice' => [
                                           'yes',
                                           'no'
                                         ]
                           },
                           'EnableMonitor',
                           {
                             'value_type' => 'string',
                             'type' => 'leaf',
                             'description' => 'Needs to be documented.'
                           },
                           'EnableOpaqueOverlayVisual',
                           {
                             'value_type' => 'enum',
                             'type' => 'leaf',
                             'description' => 'Enable a depth 8 PseudoColor visual in the overlay planes that does not reserve index 255 for transparency.',
                             'choice' => [
                                           'yes',
                                           'no'
                                         ]
                           },
                           'EnablePrivateBackZ',
                           {
                             'value_type' => 'enum',
                             'type' => 'leaf',
                             'description' => 'Needs to be documented.',
                             'choice' => [
                                           'yes',
                                           'no'
                                         ]
                           },
                           'ForceGenericCPU',
                           {
                             'value_type' => 'enum',
                             'type' => 'leaf',
                             'description' => 'Needs to be documented.',
                             'choice' => [
                                           'yes',
                                           'no'
                                         ]
                           },
                           'ForceMonitors',
                           {
                             'value_type' => 'string',
                             'type' => 'leaf',
                             'description' => '"string[,string,...]"
           ... Available values are: crt1, crt2, lvds, tmds1, tmds2, tmds2i,
           tv, nocrt1, nocrt2, nolvds, notmds1, notmds2, notmds2i, notv.'
                           },
                           'FSAAEnable',
                           {
                             'value_type' => 'enum',
                             'type' => 'leaf',
                             'choice' => [
                                           'yes',
                                           'no'
                                         ]
                           },
                           'FSAADisableGamma',
                           {
                             'value_type' => 'enum',
                             'type' => 'leaf',
                             'description' => 'By default the Full scene Anti Aliasing (FSAA) gamma is set to 2.2, which is typical for CRT displays. Use this option to disable FSAA gamma. The default is: "no".',
                             'choice' => [
                                           'yes',
                                           'no'
                                         ]
                           },
                           'IgnoreEDID',
                           {
                             'value_type' => 'enum',
                             'type' => 'leaf',
                             'description' => 'Do not use EDID data for mode validation, but DDC is still used for monitor detection. This is different from Option "NoDDC". The default is: "off". If the server is ignoring your modlines, set this option to "on" and try again.',
                             'choice' => [
                                           'yes',
                                           'no'
                                         ]
                           },
                           'MaxGARTSize',
                           {
                             'value_type' => 'integer',
                             'type' => 'leaf',
                             'description' => 'Configure the ATI AGP GART (Graphic Address Remapping Table) size.'
                           },
                           'Mode2',
                           {
                             'cargo' => {
                                          'value_type' => 'uniline',
                                          'type' => 'leaf'
                                        },
                             'type' => 'list',
                             'description' => 'set possible resolution'
                           },
                           'mtrr',
                           {
                             'value_type' => 'enum',
                             'type' => 'leaf',
                             'description' => 'Enable or disable DRI Memory Type Range Registers (MTRR) mapper. Be aware, that the driver has its own code for MTRR. The default is: "off".',
                             'choice' => [
                                           'on',
                                           'off'
                                         ]
                           },
                           'no_accel',
                           {
                             'value_type' => 'enum',
                             'type' => 'leaf',
                             'description' => 'Enables or disables all hardware acceleration (XAA). The default is: "off".',
                             'choice' => [
                                           'on',
                                           'off'
                                         ]
                           },
                           'no_dri',
                           {
                             'value_type' => 'enum',
                             'type' => 'leaf',
                             'description' => 'Enables or disables DRI extension. The default is: "off".',
                             'choice' => [
                                           'on',
                                           'off'
                                         ]
                           },
                           'NoDDC',
                           {
                             'value_type' => 'enum',
                             'type' => 'leaf',
                             'description' => 'Disable probing of DDC-information from your monitor. The default is: "off".',
                             'choice' => [
                                           'on',
                                           'off'
                                         ]
                           },
                           'NoTV',
                           {
                             'value_type' => 'enum',
                             'type' => 'leaf',
                             'description' => 'Enable or disable TV-Out for a monitor.',
                             'choice' => [
                                           'on',
                                           'off'
                                         ]
                           },
                           'OpenGLOverlay',
                           {
                             'value_type' => 'enum',
                             'type' => 'leaf',
                             'description' => 'If you enable this option, Option "VideoOverlay" will be disabled automatically.',
                             'choice' => [
                                           'on',
                                           'off'
                                         ]
                           },
                           'PBuffer',
                           {
                             'value_type' => 'enum',
                             'type' => 'leaf',
                             'description' => '"0" PBuffer area disabled. 
"1" Size of PBuffer area 1280x1024. 
"2" Size of PBuffer area 1600x1200. 
"3" Size of PBuffer area 1920x1200. 
"4" Size of PBuffer area 2048x1536.',
                             'choice' => [
                                           0,
                                           1,
                                           2,
                                           3,
                                           4
                                         ]
                           },
                           'PowerState',
                           {
                             'value_type' => 'uniline',
                             'type' => 'leaf'
                           },
                           'PseudoColorVisuals',
                           {
                             'value_type' => 'enum',
                             'upstream_default' => 'off',
                             'type' => 'leaf',
                             'description' => 'Enabling this options allows the usage of pseudo color visuals at the same time with true color visuals using the overlay technique. The default is: "off".',
                             'choice' => [
                                           'on',
                                           'off'
                                         ]
                           },
                           'RingSize',
                           {
                             'value_type' => 'integer',
                             'type' => 'leaf',
                             'description' => 'Needs to be documented. (ring buffer size, default = "1", values in MB)'
                           },
                           'ScreenOverlap',
                           {
                             'value_type' => 'integer',
                             'type' => 'leaf',
                             'description' => 'This option is intended to allow image overlapping with e.g. two video projectors. It only applies to big desktops (see Option "DesktopSetup").'
                           },
                           'SilkenMouse',
                           {
                             'value_type' => 'enum',
                             'type' => 'leaf',
                             'description' => 'Enable or disable the hardware cursor to be updated asynchronously by the signal handler associated with mouse events. The default is: "on".',
                             'choice' => [
                                           'on',
                                           'off'
                                         ]
                           },
                           'Stereo',
                           {
                             'value_type' => 'enum',
                             'type' => 'leaf',
                             'description' => 'To enable Stereo mode of Quad Buffer Stereo ("Active Stereo") capable cards, set this value to "on" and disable Option "VideoOverlay" and Option "OpenGLOverlay". The default is: "off". If you enable Stereo Quad Buffering then you should not use virtual desktops bigger than the selected resolution. Further the stereo feature will only initialize if your adapter is in text-mode when launching X and the respective display mode. The adapter can not switch between multiple resolutions while keeping the stereo setup. For that reason it is highly recommended that you have only one single modes in your config file at Section "Screen" -> SubSection "Display".',
                             'choice' => [
                                           'on',
                                           'off'
                                         ]
                           },
                           'StereoSyncEnable',
                           {
                             'value_type' => 'integer',
                             'type' => 'leaf'
                           },
                           'SWCursor',
                           {
                             'value_type' => 'enum',
                             'type' => 'leaf',
                             'description' => 'Disable or enable the use of a software cursor. The default is: "off".',
                             'choice' => [
                                           'on',
                                           'off'
                                         ]
                           },
                           'TMDSCoherentMode',
                           {
                             'value_type' => 'enum',
                             'type' => 'leaf',
                             'description' => 'Internal TMDS transmitter can be programmed in 2 different ways to get best signal qualities depending on connected transmitter chips in the panel. The noise must appear in 1600x1200 mode, but can also come up in 1280x1024x75Hz. You can enable or disable the coherent mode using this option. The default is: "on".',
                             'choice' => [
                                           'on',
                                           'off'
                                         ]
                           },
                           'TexturedVideo',
                           {
                             'value_type' => 'enum',
                             'experience' => 'advanced',
                             'type' => 'leaf',
                             'choice' => [
                                           'on',
                                           'off'
                                         ]
                           },
                           'TVFormat',
                           {
                             'value_type' => 'enum',
                             'type' => 'leaf',
                             'description' => 'Choose the TV format.',
                             'choice' => [
                                           'NTSC-JPN',
                                           'NTSC-M',
                                           'NTSC-N',
                                           'PAL-B',
                                           'PAL-CN',
                                           'PAL-D',
                                           'PAL-G',
                                           'PAL-H',
                                           'PAL-I',
                                           'PAL-K',
                                           'PAL-K1',
                                           'PAL-L',
                                           'PAL-M',
                                           'PAL-N',
                                           'PAL-SCART'
                                         ]
                           },
                           'TVOverscan',
                           {
                             'value_type' => 'enum',
                             'upstream_default' => 'on',
                             'type' => 'leaf',
                             'description' => 'Enable or disable TV overscan. Available values are: on, off. The default is: "on". Note: Not all TV formats support overscan. Try to toggle overscan off before changing Option "TVFormat" if an error occurs.',
                             'choice' => [
                                           'on',
                                           'off'
                                         ]
                           },
                           'TVStandard',
                           {
                             'value_type' => 'enum',
                             'type' => 'leaf',
                             'description' => 'Choose the TV standard.',
                             'choice' => [
                                           'VIDEO',
                                           'SCART',
                                           'YUF'
                                         ]
                           },
                           'TVColorAdj',
                           {
                             'value_type' => 'integer',
                             'type' => 'leaf'
                           },
                           'TVHPosAdj',
                           {
                             'value_type' => 'integer',
                             'type' => 'leaf',
                             'description' => '
           Define the horizontal pixel offset from the center of the screen.
           The range for integer depends on the ASIC. Try to use aticonfig(1x)
           with option --tv-info to get a valid range.'
                           },
                           'TVVPosAdj',
                           {
                             'value_type' => 'integer',
                             'type' => 'leaf',
                             'description' => '
           Define the vertical pixel offset from the center of the screen. The
           range for integer depends on the ASIC. Try to use aticonfig(1x)
           with option --tv-info to get a valid range.'
                           },
                           'TVHSizeAdj',
                           {
                             'value_type' => 'integer',
                             'max' => 100,
                             'type' => 'leaf',
                             'description' => '
           Define the height of the TV geometry (as percentage unit). As a
           rule of thumb the value is valid in the range of [1..100], but it
           depends on what has been chosen for Option "TVFormat".'
                           },
                           'TVVSizeAdj',
                           {
                             'value_type' => 'integer',
                             'max' => 100,
                             'type' => 'leaf',
                             'description' => '
           Define the width of the TV geometry (as percentage unit). As a rule
           of thumb the value is valid in the range of [1..100], but it
           depends on what has been chosen for Option "TVFormat".'
                           },
                           'TVHStartAdj',
                           {
                             'value_type' => 'integer',
                             'type' => 'leaf'
                           },
                           'UseFastTLS',
                           {
                             'value_type' => 'enum',
                             'help' => {
                                         '1' => 'Fast operations.',
                                         '0' => 'Fast operations. Provides the highest possible OpenGL
               performance. The method makes use of a quite limited resource.
               This is the default.',
                                         '2' => 'Compatible mode. Fast operations are turned off. This method is
               some 10% slower and uses a less limited resource. Preferred for
               Wine(X), emulators and other VM manipulating programs.'
                                       },
                             'upstream_default' => 'off',
                             'type' => 'leaf',
                             'description' => 'Use this option to set the method to maintain the so called Thread Local Storage (TLS) locations. The default is: "off".

If you do spot an immediate segmentation fault after launching a program that makes use of OpenGL and further when the fault can be traced down to the OpenGL implementation of the graphics driver, then you should try to tune the TLS settings.',
                             'choice' => [
                                           'off',
                                           'on'
                                         ]
                           },
                           'UseInternalAGPGART',
                           {
                             'value_type' => 'enum',
                             'type' => 'leaf',
                             'description' => '
           Enable or disable the usage of an internal agpgart module. If you
           set this option to "yes", the driver will not use the kernel\'s
           AGPGart module. Instead it will make use of the "built-in" AGP
           support. The default is "no", as long as the graphics driver\'s
           kernel module detects the presence of an agpgart kernel module.

           Warning
           If you set this option to "yes" you must ensure, that you do not
           have the kernel AGP support compiled in. Instead compile it as
           modules.

           The AGP support in the driver may not always work, depending on the
           type of motherboard and/or card that you have. But there is a
           possibility, which maybe still works. Refer to the
           "agp_try_unsupported=1" value for Option "KernelModuleParm".',
                             'choice' => [
                                           'yes',
                                           'no'
                                         ]
                           },
                           'VideoOverlay',
                           {
                             'value_type' => 'enum',
                             'type' => 'leaf',
                             'description' => '
           ... Video Overlay for the Xv extension ... If you want enable this
           option, Option "OpenGLOverlay" must not be enabled.',
                             'choice' => [
                                           'on',
                                           'off'
                                         ]
                           },
                           'VRefresh2',
                           {
                             'value_type' => 'integer',
                             'type' => 'leaf',
                             'description' => '"frequency"
           Vertical refresh rate range for the second monitor in e.g. big
           desktop mode.

           Note
           You can skip this value, if you define an appropriate VertRefresh
           line in the related Section "Monitor".'
                           }
                         ]
          }
        ]
;
