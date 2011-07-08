package Config::Model::Debian::Dependency ;

use strict ;
use warnings ;
use Memoize ;
use Memoize::Expire ;
use DB_File ;
use LWP::Simple ;
use Log::Log4perl qw(get_logger :levels);
use Module::CoreList;
use version ;

# available only in debian. Black magic snatched from 
# /usr/share/doc/libapt-pkg-perl/examples/apt-version 
use AptPkg::Config '$_config';
use AptPkg::System '$_system';
use AptPkg::Version;
use AptPkg::Cache ;

use vars qw/$test_filter/ ;
$test_filter = ''; # reserved for tests

my $logger = get_logger("Tree::Element::Value::Dependency") ;

# initialise the global config object with the default values
$_config->init;

# determine the appropriate system type
$_system = $_config->system;

# fetch a versioning system
my $vs = $_system->versioning;

my $apt_cache = AptPkg::Cache->new ;

# end black magic

use base qw/Config::Model::Value/ ;
use vars qw/%cache/ ;

# Set up persistence
my $cache_file_name = $ENV{HOME}.'/.config_model_depend_cache' ;
my @tie_args = ( 'DB_File', $cache_file_name, O_CREAT|O_RDWR, 0640 ) ;

# Set up expiration policy, supplying persistent hash as a target
# Memoire::Expire doc is wrong
tie %cache => 'Memoize::Expire',
    LIFETIME => 60 * 60 * 24 * 30,    # roughly one month , in seconds
    TIE => \@tie_args 
       unless %cache; # this condition is used during tests


# Memoize::Expire is lacking methods for Data::Dumper to work
#use Data::Dumper; print Dumper(\%cache) ;

# required to write data back to DB_File
END { 
    untie %cache ;
}

# Set up memoization, supplying expiring persistent hash for cache
memoize 'get_available_version' , SCALAR_CACHE => [HASH => \%cache];

my $grammar = << 'EOG' ;

check_depend: depend ( '|' depend)(s?) eofile { 
    my $ret = $arg[0]->check_depend_chain( $item{depend}, @{$item[2]} ) ;
    $return = $ret && ($item[1] ? 1 : 0) ; 
  }

depend: pkg_dep | variable  

variable: /\${[\w:\-]+}/

pkg_dep: pkg_name dep_version arch_restriction(?) {
    my $ok = $arg[0]->check_dep_and_warn( $item{pkg_name}, @{$item{dep_version}} ) ;
    $return = [ $ok, $item{pkg_name}, @{$item{dep_version}} ];
   } 
 | pkg_name arch_restriction(?) {              
    $arg[0]->check_pkg_name($item{pkg_name}) ;
    $return = [ 1 , $item{pkg_name} ] ; 
   }

arch_restriction: '[' arch(s) ']'
dep_version: '(' oper version ')' { $return = [ $item{oper}, $item{version} ] ;} 
pkg_name: /[\w\-\.]+/ 
oper: '<<' | '<=' | '=' | '>=' | '>>'
version: variable | /[\w\.\-~:+]+/
eofile: /^\Z/
arch: not(?) /[\w-]+/
not: '!'

EOG

my $parser ;

sub dep_parser {
    $parser ||= Parse::RecDescent->new($grammar) ;
    return $parser ;
}

# this method may recurse bad:
# check_dep -> meta filter -> control maintainer -> create control class
# autoread started -> read all fileds -> read dependency -> check_dep ...

sub check_value {
    my $self = shift ;
    my %args = @_ > 1 ? @_ : (value => $_[0]) ;
    my $value = $args{value} ;
    my $quiet = $args{quiet} || 0 ;
    my $silent = $args{silent} || 0 ;
    
    # value is one dependency, something like "perl ( >= 1.508 )"
    # or exim | mail-transport-agent or gnumach-dev [hurd-i386]

    # see http://www.debian.org/doc/debian-policy/ch-relationships.html
    
    # to get package list
    # wget -q -O - 'http://qa.debian.org/cgi-bin/madison.cgi?package=perl-doc&text=on'

    my @error = $self->SUPER::check_value(%args) ;
    
    if (defined $value) {
        $logger->debug("check_value '$value', calling check_depend");
        my $prd_check = dep_parser->check_depend ( $value,1,$self) ; 
        $logger->debug("check_value '$value' done");
   
        push @error,"dependency '$value' does not match grammar" unless defined $prd_check ;
    }
    
    return wantarray ? @error : scalar @error ? 0 : 1 ;
}

my @deb_releases = qw/etch lenny squeeze wheezy/;

my %deb_release_h ;
while (@deb_releases) {
    my $k = pop @deb_releases ;
    my $regexp = join('|',@deb_releases,$k);
    $deb_release_h{$k} = qr/$regexp/;
}

# called in Parse::RecDescent grammar
sub check_pkg_name {
    my ($self,$pkg) = @_ ;
    $logger->debug("check_pkg_name: called with $pkg");

    # check if Debian has version older than required version
    my @dist_version = split m/ /,  get_available_version($pkg) ;
    # print "\t'$pkg' => '@dist_version',\n";

    # if no pkg was found
    if (@dist_version == 0) {
        # try to find virtual package
        my $pkg_obj = $apt_cache->get($pkg);
        if (defined $pkg_obj) {
            # virtual package
            $logger->debug("check_pkg_name: package $pkg is pure virtual") ;
        }
        else {
            $logger->debug("check_pkg_name: unknown package $pkg") ;
            push @{$self->{warning_list}} , "package $pkg is unknown. Check for typos." ;
        }
        return ();
    }
    return @dist_version ;
}

# called in Parse::RecDescent grammar
sub check_depend_chain {
    my $self = shift ;
    
    my @alternatives ;
    foreach my $d (@_) {
        my $line = '';
        if( ref ($d) ) {
            $line .= "$d->[1]";
            $line .= " ($d->[2] $d->[3])" if defined $d->[3];
        }
        else { $line .= $d ; } ;
        push @alternatives, $line ;
    }
    my $actual_dep = join (' | ',@alternatives);
    my $ret = 1 ;
    
    foreach my $depend (@_) {
        next unless ref ($depend) ;
        my ($ok, $dep_name, $oper, $dep_v) = @$depend ;
        $logger->debug("check_depend_chain: scanning dependency $dep_name");
        if ($dep_name =~ /lib([\w+\-]+)-perl/) {
            my $pname = $1 ;
            $pname =~ s/-/::/g;
            # check for dual life module, module name follows debian convention...
            my @dep_name_as_perl = Module::CoreList->find_modules(qr/^$pname$/i);
            next unless @dep_name_as_perl ;
            my $v_decimal = Module::CoreList->first_release($dep_name_as_perl[0],$dep_v);
            next unless defined $v_decimal ;
            my $v_normal =  version->new($v_decimal)->normal ;
            $v_normal =~ s/^v//; # loose the v prefix
            $logger->debug("check_depend_chain: dual life $dep_name aka $dep_name_as_perl[0] found in Perl core $v_normal");

            # Here the dependency should be in the form perl (>= 5.10.1) | libtest-simple-perl (>= 0.88)".
            # cf http://pkg-perl.alioth.debian.org/policy.html#debian_control_handling
            my ($ret) = $self->check_dep('perl', '>=', $v_normal) ;
            my $ideal_dep = "perl" ;
            $ideal_dep .= " (>= $v_normal) | $dep_name" if $ret ;
            $ideal_dep .= " (>= $dep_v)" if $ret and defined $dep_v;
            if ($actual_dep ne $ideal_dep) {
                my $msg = "Dependency of dual life package should be '$ideal_dep' not '$actual_dep'";
                push @{$self->{warning_list}} , $msg ;
                push @{$self->{fixes}} , '$_ = "'.$ideal_dep.'"' ;
                $ret = 0;
            }
        }
    }
    
    return $ret ;
}

# called in Parse::RecDescent grammar
sub check_dep {
    my ($self,$pkg,$oper,$vers) = @_ ;
    $logger->debug("check_dep: called with $pkg $oper $vers");

    # special case to keep lintian happy
    return 1 if $pkg eq 'debhelper' ;

    # check if Debian has version older than required version
    my @dist_version = $self->check_pkg_name($pkg) ;

    return 1 unless @dist_version ; # no older for unknow packages

    return 1 unless defined $oper and $oper =~ />/ ;

    return 1 if $vers =~ /^\$/ ; # a dpkg variable

    my $src_pkg_name = $self->grab_value("!Debian::Dpkg::Control source Source") ;
        
    my $filter = $test_filter || $self->grab_value(
        step => qq{!Debian::Dpkg meta package-dependency-filter:"$src_pkg_name"},
        mode => 'loose',
    ) || '';
    $logger->debug("check_dep: using filter $filter") if defined $filter;
    my $regexp = $deb_release_h{$filter} ;

    $logger->debug("check_dep: using regexp $regexp") if defined $regexp;
    
    my @list ;
    my $has_older = 0;
    while (@dist_version) {
        my ($d,$v) = splice @dist_version,0,2 ;
 
        next if defined $regexp and $d =~ $regexp ;

        push @list, "$d -> $v;" ;
        
        if ($vs->compare($vers,$v) > 0 ) {
            $has_older = 1 ;
        }
    }

    $logger->debug("check_dep on $pkg $oper $vers has_older is $has_older (@list)");

    return 1 if $has_older ;
    return (0,@list);
}

sub check_dep_and_warn {
    my ($self,$pkg,$oper,$vers) = @_ ;
    $logger->debug("check_dep_and_warn: called with $pkg $oper $vers");

    my ($ret,@list) = $self->check_dep($pkg,$oper,$vers) ;

    return 1 if $ret ;

    my $msg = "unnecessary versioned dependency: $oper $vers. Debian has @list" ;
    push @{$self->{warning_list}} , $msg ;
    push @{$self->{fixes}} , 's/\s*\(.*\)\s*//;' ;

    return 0 ;
}

sub get_available_version {
    my ($pkg_name) = @_ ;

    $logger->debug("has_older_version called on $pkg_name");

    print "Connecting to qa.debian.org to check $pkg_name versions. Please wait ...\n" ;

    my $res = get("http://qa.debian.org/cgi-bin/madison.cgi?package=$pkg_name&text=on") ;
    
    die "cannot get data for package $pkg_name. Check your proxy ?\n" unless defined $res ;

    my @res ;
    foreach my $line (split /\n/, $res) {
        my ($name,$available_v,$dist,$type) = split /\s*\|\s*/, $line ;
        push @res , $dist,  $available_v ;
    }
    return "@res" ;
}
1;

=head1 NAME

Config::Model::Debian::Dependency - Checks Debian dependency declarations

=head1 SYNOPSIS

 use Config::Model ;
 use Log::Log4perl qw(:easy) ;
 use Data::Dumper ;

 Log::Log4perl->easy_init($WARN);

 # define configuration tree object
 my $model = Config::Model->new ;
 $model ->create_config_class (
    name => "MyClass",
    element => [ 
        Depends => {
            'type'       => 'leaf',
            'value_type' => 'uniline',
            class => 'Config::Model::Debian::Dependency',
        },
    ],
 ) ;

 my $inst = $model->instance(root_class_name => 'MyClass' );

 my $root = $inst->config_root ;

 $root->load( 'Depends="libc6 ( >= 1.0 )"') ;
 # Connecting to qa.debian.org to check libc6 versions. Please wait ...
 # Warning in 'Depends' value 'libc6 ( >= 1.0 )': unnecessary
 # versioned dependency: >= 1.0. Debian has lenny-security ->
 # 2.7-18lenny6; lenny -> 2.7-18lenny7; squeeze-security ->
 # 2.11.2-6+squeeze1; squeeze -> 2.11.2-10; wheezy -> 2.11.2-10; sid
 # -> 2.11.2-10; sid -> 2.11.2-11;

=head1 DESCRIPTION

This class is derived from L<Config::Model::Value>. Its purpose is to
check the value of a Debian package dependency for the following:

=over 

=item *

syntax as described in http://www.debian.org/doc/debian-policy/ch-relationships.html

=item *

Whether the version specified with C<< > >> or C<< >= >> is necessary.
This module will check with Debian server whether older versions can be
found in Debian old-stable or not. If no older version can be found, a
warning will be issued. Note a warning will also be sent if the package
is not found on madison and if the package is not virtual.

=back

=head1 Cache

Queries to Debian server are cached in C<~/.config_model_depend_cache>
for about one month.

=head1 BUGS

=over

=item *

Virtual package names are found scanning local apt cache. Hence an unknown package 
on your system may a virtual package on another system.

=item *

More advanced checks can probably be implemented. The author is open to
new ideas. He's even more open to patches (with tests).

=back

=head1 AUTHOR

Dominique Dumont, ddumont [AT] cpan [DOT] org

=head1 SEE ALSO

L<Config::Model>,
L<Config::Model::Value>,
L<Memoize>,
L<Memoize::Expire>
