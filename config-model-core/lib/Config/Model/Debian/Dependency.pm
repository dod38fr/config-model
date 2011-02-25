package Config::Model::Debian::Dependency ;

use strict ;
use warnings ;
use Memoize ;
use Memoize::Expire ;
use DB_File ;
use LWP::Simple ;
use Log::Log4perl qw(get_logger :levels);


# available only in debian. Black magic snatched from 
# /usr/share/doc/libapt-pkg-perl/examples/apt-version 
use AptPkg::Config '$_config';
use AptPkg::System '$_system';
use AptPkg::Version;

my $logger = get_logger("Tree::Element::Value::Dependency") ;

# initialise the global config object with the default values
$_config->init;

# determine the appropriate system type
$_system = $_config->system;

# fetch a versioning system
my $vs = $_system->versioning;

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

check_depend: depend ( '|' depend)(s?) eofile 
  { $return = $item[1] ; }

depend: pkg_dep | variable  

variable: /\${[\w:\-]+}/

pkg_dep: pkg_name dep_version arch_restriction(?) 
    {
       $arg[0]->check_dep( $item{pkg_name}, @{$item{dep_version}} ) ;
    } 
 | pkg_name arch_restriction(?) {  $return = 1 ; }

arch_restriction: '[' arch(s) ']'
dep_version: '(' oper version ')' { $return = [ $item{oper}, $item{version} ] ;} 
pkg_name: /[\w\-\.]+/
oper: '<<' | '<=' | '=' | '>=' | '>>'
version: /[\w\.\-~:]+/
eofile: /^\Z/
arch: not(?) /[\w-]+/
not: '!'

EOG

my $parser ;

sub dep_parser {
    $parser ||= Parse::RecDescent->new($grammar) ;
    return $parser ;
}

sub check_value {
    my $self = shift ;
    my %args = @_ > 1 ? @_ : (value => $_[0]) ;
    my $value = $args{value} ;
    my $quiet = $args{quiet} || 0 ;
    my $silent = $args{silent} || 0 ;

    
    my @error = $self->SUPER::check_value(%args) ;
    
    $logger->debug("check_value '$value'");
    my $prd_check = dep_parser->check_depend ( $value,1,$self) ; 
    
    push @error,"dependency '$value' does not match grammar" unless defined $prd_check ;

    # value is one dependency, something like "perl ( >= 1.508 )"
    # or exim | mail-transport-agent or gnumach-dev [hurd-i386]

    # see http://www.debian.org/doc/debian-policy/ch-relationships.html
    
    # to get package list
    # wget -q -O - 'http://qa.debian.org/cgi-bin/madison.cgi?package=perl-doc&text=on'

    return wantarray ? @error : scalar @error ? 0 : 1 ;
}

sub check_dep {
    my ($self,$pkg,$oper,$vers) = @_ ;
    $logger->debug("parser calls check_dep with $pkg $oper $vers");
    return 1 unless defined $oper and $oper =~ />/ ;

    # special case to keep lintian happy
    return 1 if $pkg eq 'debhelper' ;

    # check if Debian has version older than required version
    my @dist_version = split m/ /,  get_available_version($pkg) ;
    # print "\t'$pkg' => '@dist_version',\n";

    my @list ;
    my $has_older = 0;
    while (@dist_version) {
        my ($d,$v) = splice @dist_version,0,2 ;
        push @list, "$d -> $v;";
        
        if ($vs->compare($vers,$v) > 0 ) {
            $has_older = 1 ;
        }
    }
    my $msg = "unnecessary versioned dependency: $oper $vers. Debian has @list" ;

    $logger->debug("check_dep on $pkg $oper $vers has_older is $has_older (@list)");

    return 1 if $has_older ;
    
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
        push @res , $dist,  $available_v unless $dist =~ /etch/ ;
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

Whether the version specified with C<< > >> or C<< >= >> is necessary. This module will check 
with Debian server whether older versions can be found in Debian stable or not. If no older version 
can be found, a warning will be issued. 

=back

=head1 Cache

Queries to Debian server are cached in C<~/.config_model_depend_cache> for about one month.

=head1 BUGS

More advanced checks can probably be implemented. The author is open to
new ideas. He's even more open to patches (with tests).

=head1 AUTHOR

Dominique Dumont, ddumont [AT] cpan [DOT] org

=head1 SEE ALSO

L<Config::Model>,
L<Config::Model::Value>,
L<Memoize>,
L<Memoize::Expire>



=cut
