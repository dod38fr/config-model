
$model_to_test = "Multistrap";

$from_scratch_file = <<'EOF' ,
## This file was written by Config::Model
## You may modify the content of this file. Configuration 
## modifications will be preserved. Modifications in
## comments may be mangled.

[general]
include=/usr/share/multistrap/crosschroot.conf
EOF

@tests = (
    {
        name        => 'arm',
        config_file => '/home/foo/my_arm.conf',
        check       => {
                'sections:toolchains packages:0' ,'g++-4.2-arm-linux-gnu',
                'sections:toolchains packages:1', 'linux-libc-dev-arm-cross',
            },
    },
    {
        name => 'from_scratch',
        config_file => '/home/foo/my_arm.conf',
        load => "include=/usr/share/multistrap/crosschroot.conf" ,

        # values brought by included file
        check_layered  => {
                'sections:debian packages:0' ,'dpkg-dev',
                'sections:base packages:0', 'gcc-4.2-base',
            },
        check  => {
                'sections:toolchains packages:0' ,undef,
                'sections:toolchains packages:1', undef,
            },
        file_check_sub => sub { 
            my $r = shift ; 
            # this file was created after the load instructions above
            unshift @$r, "/home/foo/my_arm.conf";
        },
        file_content => { 
            "/home/foo/my_arm.conf" => $from_scratch_file ,
        }
    },
    {
        name => 'igep0020',
        config_file => '/home/foo/strap-igep0020.conf',
    },
);

1;
