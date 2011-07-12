use Data::Dumper ;
use IO::File ;

$conf_file_name = "control" ;
$conf_dir='debian' ;
$model_to_test = "Debian::Dpkg" ;

eval { require AptPkg::Config ;} ;
$skip = ( $@ or not -r '/etc/debian_version') ? 1 : 0 ;

@tests = (
    { # t0
     check => { 
         'control source Build-Depends-Indep:3','libtest-pod-perl',
     },
     dump_warnings => [ (qr/deprecated/) x 3 ],
     #errors => [ ],
    },
    #{ #t1
    # check => { 
    #          },
    # },
);

my $cache_file = 't/model_tests.d/debian-dependency-cache.pl' ;

unless (my $return = do $cache_file ) {
        warn "couldn't parse $cache_file: $@" if $@;
        warn "couldn't do $cache_file: $!"    unless defined $return;
        warn "couldn't run $cache_file"       unless $return;
    }

END {
    return if $::DebianDependencyCacheWritten ;
    my $str = Data::Dumper->Dump([\%Config::Model::Debian::Dependency::cache], ['*Config::Model::Debian::Dependency::cache']);
    my $fh = new IO::File "> $cache_file";
    print "writing back cache file\n";
    if (defined $fh) {
        # not a bit deal if cache cannot be written back
        $fh->print($str);
        $fh->close;
        $::DebianDependencyCacheWritten=1;
    }
}

1;
