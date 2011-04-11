package Config::Model::Backend::OpenSsh::Sshd ;

use Any::Moose ;
extends "Config::Model::Backend::OpenSsh" ;

use Carp ;
use IO::File ;
use Log::Log4perl;
use File::Copy ;
use File::Path ;

my $logger = Log::Log4perl::get_logger("Backend::OpenSsh");

sub suffix {return } 

sub read {
    my $self = shift ;
    $self->read_ssh_file( @_,  file => 'sshd_config',) ;
}

sub _host {
    my ($self,$root,$patterns,$comment)  = @_;
    $logger->debug("host: pattern @$patterns # $comment");
    my $hash_obj = $root->fetch_element('Host');

    $logger->info("ssh: load host patterns '".join("','", @$patterns)."'");

    $self->current_node = $hash_obj->fetch_with_id("@$patterns");
}

sub _forward {
    my ($self,$root,$key,$args,$comment)  = @_;
    $logger->debug("forward: $key @$args # $comment");
    $self->current_node($root) unless defined $self->current_node ;

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

    $load_str .= "$key:$size ";

    $load_str .= 'ipv6=1 ' if $v6 ;

    $load_str .= "bind_address=$bind_adr " if defined $bind_adr ;
    $load_str .= "port=$port host=$host hostport=$host_port";

    $self->current_node -> load($load_str) ;
}

sub match {
    my ($self,$root, $key, $pairs,$comment) = @_ ;
    $logger->debug("match: @$pairs # $comment");
    my $list_obj = $root->fetch_element('Match');

    # create new match block
    my $nb_of_elt = $list_obj->fetch_size;
    my $block_obj = $list_obj->fetch_with_id($nb_of_elt) ;
    $block_obj->annotation($comment) ;

    while (@$pairs) {
       my $criteria = shift @$pairs;
       my $pattern  = shift @$pairs;
       $block_obj->load(qq!Condition $criteria="$pattern"!);
    }

    $self->current_node( $block_obj->fetch_element('Settings') );
}


# now the write part

sub write {
    my $self = shift ;
    my %args = @_ ;
    my $config_root = $args{object}
      || croak __PACKAGE__," sshd_write: undefined config root object";
    my $dir = $args{root}.$args{config_dir} ;

    mkpath($dir, {mode => 0755} )  unless -d $dir ;

    my $file = "$dir/sshd_config" ;
    if (-r "$file") {
	my $backup = "$file.".time.".bak" ;
	$logger->info("Backing up file $file in $backup");
	copy($file,$backup);
    }

    $logger->info("writing config file $file");

    my $ioh = IO::File->new ;
    $ioh-> open($file,">") || die "cannot open $file:$!";
    $self->write_global_comment($ioh,'#') ;

    my $result = $self->write_node_content($config_root);

    #print $result ;
    $ioh->print ($result);
    $ioh -> close ;

    return 1;
}

sub _write_line {
    return sprintf("%-20s %s\n",@_) ;
}

sub _write_node_content {
    my $self = shift ;
    my $node = shift ;
    my $mode = shift || '';

    my $result = '' ;
    my $match  = '' ;

    foreach my $name ($node->get_element_name(for => 'master') ) {
	next unless $node->is_element_defined($name) ;
	my $elt = $node->fetch_element($name) ;
	my $type = $elt->get_type;

	#print "got $key type $type and ",join('+',@arg),"\n";
	if    ($name eq 'Match') { 
	    $match .= write_all_match_block($elt,$mode) ;
	}
	elsif    ($name eq 'Host') { 
	    $match .= write_all_host_block($elt,$mode) ;
	}
	elsif    ($name =~ /^(Local|Remote)Forward$/) { 
	    map { $result .= write_forward($_,$mode) ;} $elt->fetch_all() ;
	}
	elsif    ($type eq 'leaf') { 
	    my $v = $elt->fetch($mode) ;
	    if (defined $v and $elt->value_type eq 'boolean') {
		$v = $v == 1 ? 'yes':'no' ;
	    }
	    $result .= write_line($name,$v) if defined $v;
	}
	elsif    ($type eq 'check_list') { 
	    my $v = $elt->fetch($mode) ;
	    $result .= write_line($name,$v) if defined $v and $v;
	}
	elsif ($type eq 'list') { 
	    map { $result .= write_line($name,$_) ;} $elt->fetch_all_values($mode) ;
	}
	elsif ($type eq 'hash') {
	    foreach my $k ( $elt->get_all_indexes ) {
		my $v = $elt->fetch_with_id($k)->fetch($mode) ;
		$result .=  write_line($name,"$k $v") ;
	    }
	}
	else {
	    die "OpenSsh::write did not expect $type for $name\n";
	}
    }

    return $result.$match ;
}

sub write_all_match_block {
    my $self = shift ;
    my $match_elt = shift ;
    my $mode = shift || '';

    my $result = '';
    foreach my $elt ($match_elt->fetch_all($mode) ) {
	$result .= $self->write_match_block($elt,$mode) ;
    }

    return $result ;
}

sub write_match_block {
    my $self = shift ;
    my $match_elt = shift ;
    my $mode = shift || '';

    my $match_line ;
    my $match_body ;

    foreach my $name ($match_elt->get_element_name(for => 'master') ) {
	my $elt = $match_elt->fetch_element($name) ;

	if ($name eq 'Settings') {
	    $match_body .= $self->write_node_content($elt,$mode)."\n" ;
	}
	elsif ($name eq 'Condition') {
	    $match_line = $self->write_line( 
                Match => $self->write_match_condition($elt,$mode) ,
                $match_elt -> annotation
            ) ;
	}
	else {
	    die "write_match_block: unexpected element: $name";
	}
    }

    return $match_line.$match_body ;
}

sub write_match_condition {
    my $self = shift ;
    my $cond_elt = shift ;
    my $mode = shift || '';

    my $result = '' ;

    foreach my $name ($cond_elt->get_element_name(for => 'master') ) {
	my $elt = $cond_elt->fetch_element($name) ;
	my $v = $elt->fetch($mode) ;
	$result .= " $name $v" if defined $v;
    }

    return $result ;
}

no Any::Moose;

1;

=head1 NAME

Config::Model::Backend::OpenSsh::sshd - Backend for sshd configuration files

=head1 SYNOPSIS

=head2 invoke editor

The following will launch a graphical editor (if L<Config::Model::TkUI>
is installed):

 config-edit -application sshd

=head2 command line

This command will add a C<Match> section in C<~/.ssh/config>: 

 config-edit -application sshd -ui none \
 "Match:0 Condition User=foo - Settings ForwardX11=yes"
 
=head2 programmatic

This code snippet will remove the C<Host Foo> section added above:

 use Config::Model ;
 use Log::Log4perl qw(:easy) ;
 my $model = Config::Model -> new ( ) ;
 my $inst = $model->instance (root_class_name => 'sshd');
 $inst -> config_root ->load("Match:0 Condition User=foo - Settings ForwardX11=yes") ;
 $inst->write_back() ;

=head1 DESCRIPTION

This calls provides a backend to read and write sshd client configuration files.

Once this module is installed, user root can edit C</etc/ssh/sshd_config> 
with :

 # config-edit -application sshd 

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

These read/write functions are part of C<OpenSsh::Sshd> read/write backend. 
They are 
declared in sshd configuration model and are called back when needed to read the 
configuration file and write it back.

=head2 read (object => <sshd_root>, config_dir => ...)

Read F<sshd_config> in C<config_dir> and load the data in the 
C<sshd_root> configuration tree.

=head2 write (object => <sshd_root>, config_dir => ...)

Write F<sshd_config> in C<config_dir> from the data stored in  
C<sshd_root> configuration tree.

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<config-edit>, L<Config::Model>,
