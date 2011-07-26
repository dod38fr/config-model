use Data::Dumper;
use IO::File;

$conf_file_name = "";
$conf_dir       = '';
$model_to_test  = "Debian::Dpkg";

eval { require AptPkg::Config; };
$skip = ( $@ or not -r '/etc/debian_version' ) ? 1 : 0;

@tests = (
    {   name => 't0',
        check =>
          { 'control source Build-Depends-Indep:3', 'libtest-pod-perl', },
        dump_warnings => [ (qr/deprecated/) x 3 ],

        #errors => [ ],
    },
    {   name => 't1',
        check => {
            'patches:fix-spelling Synopsis', 'fix man page spelling',
            'patches:use-standard-dzil-test Synopsis', "use standard dzil test suite",
            'patches:use-standard-dzil-test Description',
              "Test is modified in order not to load the Test:Dzil module\nprovided in t/lib",
        },
        load => qq!patches:fix-spelling Description="more spelling details"! ,
        # dump_warnings => [ (qr/deprecated/) x 3 ],
    },

    { 
        name => 'libversion' ,
        apply_fix => 1 ,
    }
    # FIXME: add t2 to fix gregoa's issue
);

my $cache_file = 't/model_tests.d/debian-dependency-cache.txt';

my $ch = new IO::File "$cache_file";
foreach ( $ch->getlines ) {
    chomp;
    my ( $k, $v ) = split m/ => /;
    $Config::Model::Debian::Dependency::cache{$k} = $v;
}
$ch->close;

END {
    return if $::DebianDependencyCacheWritten;
    my %h = %Config::Model::Debian::Dependency::cache;
    my $str = join( "\n", map { "$_ => $h{$_}"; } sort keys %h );

    my $fh = new IO::File "> $cache_file";
    print "writing back cache file\n";
    if ( defined $fh ) {

        # not a big deal if cache cannot be written back
        $fh->print($str);
        $fh->close;
        $::DebianDependencyCacheWritten = 1;
    }
}

1;
