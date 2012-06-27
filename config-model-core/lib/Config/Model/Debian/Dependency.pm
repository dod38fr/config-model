package Config::Model::Debian::Dependency ;

use 5.10.1;

use Any::Moose;
use namespace::autoclean;

# Debian only module
use lib '/usr/share/lintian/lib' ;
use Lintian::Relation ;

use DB_File ;
use LWP::Simple ;
use Log::Log4perl qw(get_logger :levels);
use Module::CoreList;
use version ;

use AnyEvent::HTTP ;

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

extends qw/Config::Model::Value/ ;
use vars qw/%cache/ ;

# Set up persistence
my $cache_file_name = $ENV{HOME}.'/.config_model_depend_cache' ;

# this condition is used during tests
if (not %cache) {
    tie %cache => 'DB_File', $cache_file_name, 
} 

# required to write data back to DB_File
END { 
    untie %cache ;
}

my $grammar = << 'EOG' ;

check_depend: depend alt_depend(s?) eofile { 
    # cannot use %item with quantifier
    my $ret = $arg[0]->check_depend_chain( $arg[1], $arg[2],$item{depend}, @{$item[2]} ) ;
    $return = $ret && ($item[1] ? 1 : 0) ; 
  }

depend: pkg_dep | variable

alt_depend: '|' depend  

variable: /\${[\w:\-]+}/

pkg_dep: pkg_name dep_version arch_restriction(?) {
    my $ok = $arg[0]->check_dep_and_warn( $arg[1], $arg[2],$item{pkg_name}, @{$item{dep_version}} ) ;
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
    my $apply_fix = $args{fix} || 0 ;
    
    # value is one dependency, something like "perl ( >= 1.508 )"
    # or exim | mail-transport-agent or gnumach-dev [hurd-i386]

    # see http://www.debian.org/doc/debian-policy/ch-relationships.html
    
    # to get package list
    # wget -q -O - 'http://qa.debian.org/cgi-bin/madison.cgi?package=perl-doc&text=on'

    $self->SUPER::check_value(%args) ;
    $value = $self->{data} if $apply_fix ; # check_value may modify data in this case
    my $e_list = $self->{error_list} ;
    
    if (defined $value) {
        $logger->debug("check_value '$value', calling check_depend with Parse::RecDescent");
        my $prd_check = dep_parser->check_depend ( $value,1,$self,$apply_fix, \$value) ; 
        $logger->debug("check_value '$value' done");
   
        push @$e_list,"dependency '$value' does not match grammar" unless defined $prd_check ;
    }
    
    #$self->store(value => $value, check => 'no') if $apply_fix ; 
    $self->{data} = $value if $apply_fix ; 
    
    return wantarray ? @$e_list : scalar @$e_list ? 0 : 1 ;
}

#
# New subroutine "fix_value" extracted - Wed Jun 27 14:33:07 2012.
#
sub fix_value {
    my ($self, $v_ref, $new_v) = @_ ;

    my $old_v = $$v_ref;
    $$v_ref = $new_v ;
    $self->notify_change(old => $old_v, new => $$v_ref, note => 'applied fix') ;
}

sub check_debhelper {
    my ($self,$apply_fix, $v_ref, $dep_name, $oper, $dep_v) = @_ ;

    my $lintian_dep = Lintian::Relation->new( $$v_ref) ;
    $logger->debug("checking '$$v_ref' with lintian");

    # using mode loose because debian-control model can be used alone
    # and compat is outside of debian-control
    my $compat = $self->grab_value(mode => 'loose', step => "!Debian::Dpkg compat") ;
    return unless defined $compat ;

    my $min_dep = Lintian::Relation->new("debhelper ( >= $compat)") ;
    $logger->debug("checking if ".$lintian_dep->unparse." implies ". $min_dep->unparse);
    
    return if $lintian_dep->implies ($min_dep) ;
    
    $logger->debug("'$$v_ref' does not imply debhelper >= $compat");
    
    # $show_rel avoids undef warnings
    my $show_rel = join(' ', map { $_ || ''} ($oper, $dep_v));
    if ($apply_fix) {
        $self->fix_value ($v_ref, $min_dep->unparse );
        $logger->info("fixed debhelper dependency from "
            ."$dep_name $show_rel -> $$v_ref (for compat $compat)");
    }
    else {
        $self->{nb_of_fixes}++ ;
        my $msg = "should be (>= $compat) not ($show_rel) because compat is $compat" ;
        push @{$self->{warning_list}} , $msg ;
        $logger->info("will warn: $msg");
    }
}

my @deb_releases = qw/etch lenny squeeze wheezy/;

my %deb_release_h ;
while (@deb_releases) {
    my $k = pop @deb_releases ;
    my $regexp = join('|',@deb_releases,$k);
    $deb_release_h{$k} = qr/$regexp/;
}

# called in check_dep and in Parse::RecDescent grammar 
sub check_pkg_name {
    my ($self,$pkg) = @_ ;
    $logger->debug("check_pkg_name: called with $pkg");

    # check if Debian has version older than required version
    my ($has_info, @dist_version) = $self->get_available_version($pkg) ;
    # print "\t'$pkg' => '@dist_version',\n";

    return () unless $has_info ;

    # if no pkg was found
    if (@dist_version == 0) {
        # don't know how to distinguish virtual package from source package
        $logger->debug("check_pkg_name: unknown package $pkg") ;
        push @{$self->{warning_list}} , "package $pkg is unknown. Check for typos if not a virtual package." ;
        return ();
    }
    return @dist_version ;
}

# called in Parse::RecDescent grammar
sub check_depend_chain {
    my ($self, $apply_fix, $v_ref, @input) = @_ ;
    
    # even when apply_fix is 1, dependencies stored in @input are not
    # modified by check_dep. Hence the validity of the versioned dependencies
    # must also be checked in this method
    
    my @alternatives ;
    foreach my $d (@input) {
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
    $logger->debug("check_depend_chain: called with $actual_dep");
    
    foreach my $depend (@input) {
        next unless ref ($depend) ;
        my ($ok, $dep_name, $oper, $dep_v) = @$depend ;
        $logger->debug("check_depend_chain: scanning dependency $dep_name".(defined $dep_v ? " $dep_v" : ''));
        if ($dep_name =~ /lib([\w+\-]+)-perl/) {
            my $pname = $1 ;
            $ret &&= $self->check_perl_lib_dep ($apply_fix, $v_ref, $pname, $actual_dep, $depend);
        }
        elsif ( $dep_name eq 'debhelper') {
            $self->check_debhelper($apply_fix, $v_ref, $dep_name, $oper, $dep_v);
        }
        
    }
    #exit if $input[0][1] =~ /module/ ;
    return $ret ;
}

# called in Parse::RecDescent grammar through check_depend_chain
sub check_perl_lib_dep {
    my ($self, $apply_fix, $v_ref, $pname, $actual_dep, $depend) = @_;

    my ( $ok, $dep_name, $oper, $dep_v ) = @$depend;
    my $ret = 1;

    $pname =~ s/-/::/g;

    # check for dual life module, module name follows debian convention...
    my @dep_name_as_perl = Module::CoreList->find_modules(qr/^$pname$/i) ; 
    return $ret unless @dep_name_as_perl;

    my $v_decimal = Module::CoreList->first_release( $dep_name_as_perl[0], $dep_v );
    return $ret unless defined $v_decimal;

    my $v_normal = version->new($v_decimal)->normal;
    $v_normal =~ s/^v//;    # loose the v prefix
    if ( $logger->debug ) {
        my $dep_str = $dep_name . ( defined $dep_v ? ' ' . $dep_v : '' );
        $logger->debug("dual life $dep_str aka $dep_name_as_perl[0] found in Perl core $v_normal");
    }

    # Here the dependency should be in the form perl (>= 5.10.1) | libtest-simple-perl (>= 0.88)".
    # cf http://pkg-perl.alioth.debian.org/policy.html#debian_control_handling
    # If the Perl version is not available in sid, the order of the dependency should be reversed
    # libcpan-meta-perl | perl (>= 5.13.10)
    # because buildd will use the first available alternative

    my ($has_older_perl) = $self->check_dep( 'perl', '>=', $v_normal );
    my @ideal_deps = ('perl');
    $ideal_deps[0] .= " (>= $v_normal)" if $has_older_perl;

    my ($has_older_dep) = defined $dep_v ? $self->check_dep( $dep_name, '>=', $dep_v ) : (0);
    push @ideal_deps, $dep_name if $has_older_perl;
    $ideal_deps[1] .= " (>= $dep_v)" if $has_older_perl and $has_older_dep;

    my ($has_info, %perl_version) = $self->get_available_version('perl');
    return $ret unless $has_info ; # info not yet available

    my $has_older_perl_in_sid = ( $vs->compare( $v_normal, $perl_version{sid} ) < 0 ) ? 1 : 0;
    $logger->debug(
        "check_depend_chain: perl $v_normal is",
        $has_older_perl_in_sid ? ' ' : ' not ',
        "older than perl in sid ($perl_version{sid})"
    );

    my $ideal_dep = join( ' | ', $has_older_perl_in_sid ? @ideal_deps : reverse(@ideal_deps) );

    if ( $actual_dep ne $ideal_dep ) {
        if ($apply_fix) {
            $self->fix_value( $v_ref, $ideal_dep);
            $logger->info("check_depend_chain: fixed dependency with: $ideal_dep");
        }
        else {
            $self->{nb_of_fixes}++;
            my $msg = "Dependency of dual life package should be '$ideal_dep' not '$actual_dep'";
            push @{ $self->{warning_list} }, $msg;
            $logger->info("check_depend_chain: will warn: $msg");
        }
        $ret = 0;
    }
   return $ret ;
}

sub check_dep {
    my ($self, $pkg,$oper,$vers) = @_ ;
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
        step => qq{!Debian::Dpkg my_config package-dependency-filter:"$src_pkg_name"},
        mode => 'loose',
    ) || '';
    return $self->has_older_version_than ($pkg, $vers,  $filter, \@dist_version );
}

sub has_older_version_than {
    my ($self, $pkg, $vers, $filter, $dist_version ) = @_;

    $logger->debug("has_older_version_than: using filter $filter") if $filter;
    my $regexp = $deb_release_h{$filter} ;

    $logger->debug("has_older_version_than: using regexp $regexp") if defined $regexp;
    
    my @list ;
    my $has_older = 0;
    while (@$dist_version) {
        my ($d,$v) = splice @$dist_version,0,2 ;
 
        next if defined $regexp and $d =~ $regexp ;

        push @list, "$d -> $v;" ;
        
        if ($vs->compare($vers,$v) > 0 ) {
            $has_older = 1 ;
        }
    }

    $logger->debug("has_older_version_than on $pkg $vers has_older is $has_older (@list)");

    return 1 if $has_older ;
    return (0,@list);
}

sub check_dep_and_warn {
    my ($self,$apply_fix,$v_ref, $pkg,$oper,$vers) = @_ ;
    $logger->debug("called with $pkg $oper $vers");

    my ($ret,@list) = $self->check_dep($pkg,$oper,$vers) ;

    return 1 if $ret ;

    if ($apply_fix) {
        $self->fix_value($v_ref, $pkg) ;
        $logger->info("check_dep_and_warn: removed versioned dependency from $pkg $oper $vers -> $$v_ref");
    }
    else {
        $self->{nb_of_fixes}++ ;
        my $msg = "unnecessary versioned dependency: $oper $vers. Debian has @list" ;
        push @{$self->{warning_list}} , $msg ;
        $logger->info("check_dep_and_warn: will warn: $msg");
    }

    return 0 ;
}

sub get_available_version {
    my ($self,$pkg_name) = @_ ;
    state %requested ;

    $logger->debug("get_available_version called on $pkg_name");

    my ($time,@res) = split / /, ($cache{$pkg_name} || '');
    if ($requested{$pkg_name} 
        or (defined $time and $time =~ /^\d+$/ and $time + 24 * 60 * 60 * 7 > time) ) {
        return (1, @res) ;
    }

    my $url = "http://qa.debian.org/cgi-bin/madison.cgi?package=$pkg_name&text=on" ;
    $requested{$pkg_name} = 1 ;

    # async fetch
    my $cv= $self->grab("!Debian::Dpkg::Control")->backend_mgr
        ->get_backend("Debian::Dpkg::Control")->condvar;
    $cv->begin;

    say "Connecting to qa.debian.org to check $pkg_name versions. Please wait..." ;


    my $request;
    $request = http_request(
        GET => $url,
        timeout => 20, # seconds
        sub {
            my ($body, $hdr) = @_;
            if ($hdr->{Status} =~ /^2/) {
                my @res ;
                foreach my $line (split /\n/, $body) {
                    my ($name,$available_v,$dist,$type) = split /\s*\|\s*/, $line ;
                    $type =~ s/\s//g ;
                    push @res , $dist,  $available_v unless $type eq 'source';
                }
                say "got info for $pkg_name" ;
                $cache{$pkg_name} = time ." @res" ;
            }
            else {
                say "Error for $url: ($hdr->{Status}) $hdr->{Reason}";
            }
            undef $request;
            $cv->end;
        }
    );
    
    return (0) ; # will re-check dep once the info is retrieved
}

__PACKAGE__->meta->make_immutable;

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

=item * 

Whether a Perl library is dual life. In this case the dependency is checked according to
L<Debian Perl policy|http://pkg-perl.alioth.debian.org/policy.html#debian_control_handling>.
Because Debian auto-build systems (buildd) will use the first available alternative, 
the dependency should be in the form :

=over 

=item * 

C<< perl (>= 5.10.1) | libtest-simple-perl (>= 0.88) >> when
the required perl version is available in sid. ".

=item *

C<< libcpan-meta-perl | perl (>= 5.13.10) >> when the Perl version is not available in sid

=back

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
