use Data::Dumper;
use IO::File;

$conf_file_name = "control";
$conf_dir       = 'debian';
$model_to_test  = "Debian::Dpkg::Control";

eval { require AptPkg::Config ;} ;
$skip = ( $@ or not -r '/etc/debian_version') ? 1 : 0 ;

my $t3_description = "This is an extension of Dist::Zilla::Plugin::InlineFiles, 
providing the following file:

 - xt/release/pod-spell.t - a standard Test::Spelling test" ;

@tests = (
    {

        # t0
        check => {
            'source Source',          "libdist-zilla-plugins-cjm-perl",
            'source Build-Depends:0', "debhelper (>= 7)",
            'source Build-Depends-Indep:0', "libcpan-meta-perl | perl (>= 5.13.10)",     # fixed
            'source Build-Depends-Indep:1', "libdist-zilla-perl",    # fixed
            'source Build-Depends-Indep:5', "libpath-class-perl",
            'source Build-Depends-Indep:6', "perl (>= 5.11.3) | libmodule-build-perl (>= 0.36)", # fixed
            'binary:libdist-zilla-plugins-cjm-perl Depends:0',
            '${misc:Depends}',
            'source Vcs-Browser' ,'http://anonscm.debian.org/gitweb/?p=pkg-perl/packages/libdist-zilla-plugins-cjm-perl.git',
            'source Vcs-Git', 'git://git.debian.org/pkg-perl/packages/libdist-zilla-plugins-cjm-perl.git',
        },
        load_warnings => [ qr/dependency/, qr/dual life/, (qr/dependency/) x 2, 
                          qr/libmodule-build-perl \(>= 0.36\) \| perl \(>= 5.8.8\)/,
                          qr/should be 'perl \(>= 5.11.3\) \| libmodule-build-perl \(>= 0.36\)/,
                          qr/standards version/, 
                           qr/dependency/, qr/dual life/, (qr/dependency/) x 2 ],
        apply_fix => 1,
    },
    {

        # t1
        check => { 'binary:seaview Recommends:0', 'clustalw', },
        load_warnings => [ qr/dependency is deprecated/,qr/standards version/, qr/too long/ ],
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
            # no longer mess up synopsis with lcfirst
            'binary:libdist-zilla-plugin-podspellingtests-perl Synopsis' =>
              "Release tests for POD spelling",
            'binary:libdist-zilla-plugin-podspellingtests-perl Description' => $t3_description ,
        },
        load_warnings => [ qr/standards version/, (qr/value/) x 2],
        load => 'binary:libdist-zilla-plugin-podspellingtests-perl '.
            'Description="'.$t3_description.'"',
        apply_fix => 1,
    },
    {

        # t4
        check => { 'source X-Python-Version' => ">= 2.3, << 2.5" },
        load_warnings => [ (qr/deprecated/) x 2, qr/empty/ ],
        # dump_warnings => [ qr/empty/ ],
    },
    {

        # t5
        check => { 'source X-Python-Version' => ">= 2.3, << 2.6" },
        load_warnings => [ (qr/deprecated/) x 2, qr/empty/ ],
        # dump_warnings => [ qr/empty/ ],
    },
    {

        # t6
        check => { 'source X-Python-Version' => ">= 2.3" },
        load_warnings => [ (qr/deprecated/) x 2, qr/empty/ ],
        # dump_warnings => [ qr/empty/ ],
    },
    {
        name => 'sdlperl',
        load => 'source Uploaders:2="Sam Hocevar (Debian packages) <sam@zoy.org>"',
        load_warnings => [ ( qr/Warning/) x 6 ],
        load_check => 'no',
        apply_fix => 1,
    },
    {
        name => 'libpango-perl',
        load_warnings => [ ( qr/Warning/) x 2 ],
        verify_annotation => {
            'source Build-Depends' => "do NOT add libgtk2-perl to build-deps (see bug #554704)",
            'source Maintainer'    => "what a fine\nteam this one is",
        },
        load_check => 'no',
        apply_fix => 1,
    },
    {
        name => 'libwx-scintilla-perl',
        load_warnings => [ ( qr/Warning/) x 3 ],
        apply_fix => 1,
    },
);

my $cache_file = 't/model_tests.d/debian-dependency-cache.txt';

my $ch = new IO::File "$cache_file";
foreach ($ch->getlines) {
    chomp;
    my ($k,$v) = split m/ => / ;
    $Config::Model::Debian::Dependency::cache{$k} = time . ' '. $v ;
}
$ch -> close ;

END {
    return if $::DebianDependencyCacheWritten ;
    my %h = %Config::Model::Debian::Dependency::cache ;
    map { s/^\d+ //;} values %h ; # remove time stamp
    my $str = join ("\n", map { "$_ => $h{$_}" ;} sort keys %h) ;

    my $fh = new IO::File "> $cache_file";
    print "writing back cache file\n";
    if ( defined $fh ) {
        # not a big deal if cache cannot be written back
        $fh->print($str);
        $fh->close;
        $::DebianDependencyCacheWritten=1;
    }
}

1;
