use Data::Dumper;
use IO::File;
use File::HomeDir ;

# keep in sync with the hardcoded value in Patch backend
$conf_file_name = "some-patch";

$conf_dir       = 'debian/patches';
$model_to_test  = "Debian::Dpkg::Patch";

eval { require AptPkg::Config; };
$skip = ( $@ or not -r '/etc/debian_version' ) ? 1 : 0;

@tests = (
    { 
        name => 'libperl5i' ,
        dump_warnings => [qr/synopsis/],
        # apply_fix => 1 ,
        check => {
            'Bug:0' => 'https://github.com/schwern/perl5i/issues/218',
            'Bug:1' => 'https://github.com/schwern/perl5i/issues/219',
            'Origin' => 'https://github.com/doherty/perl5i',
            'Bug-Debian:0' => 'http://bugs.debian.org/655329',

        },
        # file_check_sub => $del_home,
    }
);


1;
