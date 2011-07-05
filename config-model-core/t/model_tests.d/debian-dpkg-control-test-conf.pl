use Data::Dumper;
use IO::File;

$conf_file_name = "control";
$conf_dir       = 'debian';
$model_to_test  = "Debian::Dpkg::Control";

@tests = (
    {

        # t0
        check => {
            'source Source',          "libdist-zilla-plugins-cjm-perl",
            'source Build-Depends:0', "debhelper (>= 7)",
            'source Build-Depends-Indep:0', "libcpan-meta-perl",     # fixed
            'source Build-Depends-Indep:1', "libdist-zilla-perl",    # fixed
            'source Build-Depends-Indep:5', "libpath-class-perl",
            'source Build-Depends-Indep:6', "perl (>= 5.10.1)",
            'binary:libdist-zilla-plugins-cjm-perl Depends:0',
            '${misc:Depends}',
        },
        load_warnings => [ (qr/dependency/) x 3, qr/standard version/, 
                           (qr/dependency/) x 3, qr/description/ ],
        apply_fix => 1,
    },
    {

        # t1
        check => { 'binary:seaview Recommends:0', 'clustalw', },
        load_warnings => [ qr/standard version/, qr/description/ ],
        apply_fix => 1,
        load => 'binary:seaview Synopsis="multiplatform interface for sequence alignment"',
    },
    {

        # t2
        check => {
            'binary:xserver-xorg-video-all Architecture',
            'any',
            'binary:xserver-xorg-video-all Depends:0',
            '${F:XServer-Xorg-Video-Depends}',
            'binary:xserver-xorg-video-all Depends:1',
            '${misc:Depends}',
            'binary:xserver-xorg-video-all Replaces:0',
            'xserver-xorg-driver-all',
            'binary:xserver-xorg-video-all Conflicts:0',
            'xserver-xorg-driver-all',
        },
        apply_fix => 1,
        load_warnings => undef, #skipped
        dump_warnings => undef, #skipped
        no_warnings => 1,
    },
    {

        # t3
        check => {
            'binary:libdist-zilla-plugin-podspellingtests-perl Synopsis' =>
              "release tests for POD spelling",
            'binary:libdist-zilla-plugin-podspellingtests-perl Description' =>
              "This is an extension of Dist::Zilla::Plugin::InlineFiles,
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx providing the following file:

 - xt/release/pod-spell.t - a standard Test::Spelling test"
        },
        load_warnings => [ qr/standard version/, qr/description/, qr/value/],
        apply_fix => 1,
    },
    {

        # t4
        check => { 'source X-Python-Version' => ">= 2.3, << 2.5" },
        load_warnings => [ (qr/deprecated/) x 2 ],
    },
    {

        # t5
        check => { 'source X-Python-Version' => ">= 2.3, << 2.6" },
        load_warnings => [ (qr/deprecated/) x 2 ],
    },
    {

        # t6
        check => { 'source X-Python-Version' => ">= 2.3" },
        load_warnings => [ (qr/deprecated/) x 2 ],
    },
);

my $cache_file = 't/model_tests.d/debian-dependency-cache.pl';

unless ( my $return = do $cache_file ) {
    warn "couldn't parse $cache_file: $@" if $@;
    warn "couldn't do $cache_file: $!" unless defined $return;
    warn "couldn't run $cache_file" unless $return;
}

END {
    my $str = Data::Dumper->Dump(
        [ \%Config::Model::Debian::Dependency::cache ],
        ['*Config::Model::Debian::Dependency::cache']
    );
    my $fh = new IO::File "> $cache_file";
    print "writing back cache file\n";
    if ( defined $fh ) {

        # not a bit deal if cache cannot be written back
        $fh->print($str);
        $fh->close;
    }
}

1;
