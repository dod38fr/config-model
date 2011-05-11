package Config::Model::Backend::OpenSsh::Ssh ;

use Any::Moose ;
extends "Config::Model::Backend::OpenSsh" ;

use Carp ;
use IO::File ;
use Log::Log4perl;
use File::Copy ;
use File::Path ;

my $logger = Log::Log4perl::get_logger("Backend::OpenSsh");

my $__test_ssh_root_file = 0;
sub _set_test_ssh_root_file { $__test_ssh_root_file = shift ;} 
my $__test_ssh_home = '';
sub _set_test_ssh_home { $__test_ssh_home = shift ;}

# for ssh_read:
# if root: use /etc/ssh/ssh_config as usual
# if normal user: load root file in "preset mode" 
#                 load ~/.ssh/config in normal mode
#                 write back to ~/.ssh/config
#                 Ssh model can only specify root config_dir

sub read {
    my $self=shift;
    my %args = @_ ;
    my $config_root = $args{object}
      || croak __PACKAGE__," ssh_read: undefined config root object";
    my $instance = $config_root -> instance ;

    my $is_user = 1 ;

    # $__test_root_file is a special global variable used only for tests
    $is_user = 0 if ($> == 0 or $__test_ssh_root_file ); 

    my $home_dir = $__test_ssh_home || $ENV{HOME} ;

    $logger->info("ssh_read: reading ".($is_user ? 'user' :'root').
		 " ssh config in ". ($is_user ? $home_dir : $args{config_dir}));

    $instance -> preset_start if $is_user ; # regular user

    my $ret = $self->read_ssh_file( @_, file => 'ssh_config' ) ;

    $instance -> preset_stop if $is_user ;

    if ( $is_user) {
	# don't croak if user config file is missing
	$self->read_ssh_file( @_ , file => 'config',
		       config_dir => $home_dir.'/.ssh') ;
    }

    return $ret ;
}


sub host {
    my ($self,$root,$key, $patterns,$comment)  = @_;
    $logger->debug("host: pattern @$patterns # $comment");
    my $hash_obj = $root->fetch_element('Host');

    $logger->info("ssh: load host patterns '".join("','", @$patterns)."'");
    my $hv = $hash_obj->fetch_with_id("@$patterns") ;
    $hv -> annotation($comment) if $comment ;

    $self->current_node($hv);
}

sub forward {
    my ($self,$root,$key,$args,$comment)  = @_;
    $logger->debug("forward: $key @$args # $comment");
    $self->current_node = $root unless defined $self->current_node ;

    my $elt_name = $key =~ /local/i ? 'Localforward' : 'RemoteForward' ;
    my $size = $self->current_node->fetch_element($key)->fetch_size;

    $logger->info("ssh: load $key '".join("','", @$args)."'");

    my $v6 = ($args->[1] =~ m![/\[\]]!) ? 1 : 0;

    # cleanup possible square brackets used for IPv6
    foreach (@$args) {s/[\[\]]+//g;}

    # reverse enable to assign string to port even if no bind_adress
    # is specified
    my $re = $v6 ? qr!/! : qr!:! ; 
    my ($port,$bind_adr ) = reverse split $re,$args->[0] ;
    my ($host,$host_port) = split $re,$args->[1] ;

    my $load_str = '';
    $load_str .= "GatewayPorts=1 " if $bind_adr ;
    my $note = $comment || '' ;
    $note =~ s/"/\\"/g;
    $note = qq!#"$note"! if $note ;
    $load_str .= "$key:$size$note ";

    $load_str .= 'ipv6=1 ' if $v6 ;

    $load_str .= "bind_address=$bind_adr " if defined $bind_adr ;
    $load_str .= "port=$port host=$host hostport=$host_port";

    $self->current_node -> load($load_str) ;
}

# for ssh_write:
# if root: use /etc/ssh/ssh_config as usual
# if normal user: load root file in "preset mode" 
#                 load ~/.ssh/config in normal mode
#                 write back to ~/.ssh/config
#                 Ssh model can only specify root config_dir

sub write {
    my $self = shift ;
    my %args = @_ ;
    my $config_root = $args{object}
      || croak __PACKAGE__," ssh_write: undefined config root object";

    my $is_user = 1 ;
    # $__test_root_file is a special global variable used only for tests
    $is_user = 0 if ($> == 0 or $__test_ssh_root_file ); 
    my $home_dir = $__test_ssh_home || $ENV{HOME} ;

    my $config_dir = $is_user ? $home_dir.'/.ssh' : $args{config_dir} ;
    my $dir = $args{root}.$config_dir ;

    mkpath($dir, {mode => 0755} )  unless -d $dir ;

    my $file = $is_user ? "$dir/config" : "$dir/ssh_config" ;

    $logger->info("writing config file $file");

    my $ioh = IO::File->new ;
    $ioh-> open($file,">") || die "cannot open $file:$!";
    $self->write_global_comment($ioh,'#') ;

    my $result = $self->write_node_content($config_root,'custom');

    #print $result ;
    $ioh->print ($result);
    $ioh -> close ;

    return 1;
}

sub write_all_host_block {
    my $self = shift ;
    my $host_elt = shift ;
    my $mode = shift || '';

    my $result = '' ;

    foreach my $pattern ( $host_elt->get_all_indexes) {
	my $block_elt = $host_elt->fetch_with_id($pattern) ;
        $logger->debug("write_all_host_block on ".$block_elt->location." mode $mode");
	my $block_data = $self->write_node_content($block_elt,'custom') ;

	# write data only if custom pattern or custom data is found this
	# is necessary to avoid writing data from /etc/ssh/ssh_config that
	# were entered as 'preset' data
	if ($block_data) {
	    $result .= $self->write_line(Host => $pattern, $block_elt->annotation);
	    $result .= "$block_data\n" ;
	}
    }
    return $result ;
}

sub write_forward {
    my $self = shift ;
    my $forward_elt = shift ;
    my $mode = shift || '';

    my $result = '' ;

    my $v6 = $forward_elt->grab_value('ipv6') ;
    my $sep = $v6 ? '/' : ':';

    my $line = '';
    foreach my $name ($forward_elt->get_element_name(for => 'master') ) {
	next if $name eq 'ipv6' ;
	my $elt = $forward_elt->fetch_element($name) ;
	my $v = $elt->fetch($mode) ;
	next unless length($v);
	$line .=  $name =~ /bind|host$/ ? "$v$sep"
	       :  $name eq 'port'       ? "$v "
	       :                           $v ;
    }

    return $self->write_line($forward_elt->element_name,$line,$forward_elt->annotation) ;
}
1;

no Any::Moose;

__END__

=head1 NAME

Config::Model::Backend::OpenSsh::Ssh - Backend for ssh configuration files

=head1 SYNOPSIS

=head2 invoke editor

The following will launch a graphical editor (if L<Config::Model::TkUI>
is installed):

 config-edit -application ssh

=head2 command line

This command will add a C<Host Foo> section in C<~/.ssh/config>: 

 config-edit -application ssh -ui none Host:Foo ForwardX11=yes
 
=head2 programmatic

This code snippet will remove the C<Host Foo> section added above:

 use Config::Model ;
 use Log::Log4perl qw(:easy) ;
 my $model = Config::Model -> new ( ) ;
 my $inst = $model->instance (root_class_name => 'Ssh');
 $inst -> config_root ->load("Host~Foo") ;
 $inst->write_back() ;

=head1 DESCRIPTION

This calls provides a backend to read and write ssh client configuration files.

Once this module is installed, user root can edit C</etc/ssh/ssh_config> 
with :

 # config-edit -application ssh 

To edit F<~/.ssh/config>, run as a normal user:

 # config-edit -application ssh

=head1 user interfaces

As mentioned in L<config-edit>, several user interfaces are available:

=over

=item *

A graphical interface is proposed by default if L<Config::Model::TkUI> is installed.

=item *

A Curses interface with option C<-ui curses> if L<Config::Model::CursesUI> is installed.

=item *

A Shell like interface with option C<-ui term>.

=item *

A L<Fuse> virtual file system with option C<< -ui fuse -fuse_dir <mountpoint> >> 
if L<Fuse> is installed (Linux only)

=back

=head1 STOP

The documentation provides on the reader and writer of OpenSsh configuration files.
These details are not needed for the basic usages explained above.

=head1 Methods

These read/write functions are part of C<OpenSsh::Ssh> read/write backend. 
They are 
declared in Ssh configuration model and are called back when needed to read the 
configuration file and write it back.

=head2 read (object => <ssh_root>, config_dir => ...)

Read F<ssh_config> in C<config_dir> and load the data in the 
C<ssh_root> configuration tree.

=head2 write (object => <ssh_root>, config_dir => ...)

Write F<ssh_config> in C<config_dir> from the data stored in  
C<ssh_root> configuration tree.

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<config-edit>, L<Config::Model>,
