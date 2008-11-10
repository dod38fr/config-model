# $Author: ddumont $
# $Date: 2008-11-10 10:12:20 +0100 (Mon, 10 Nov 2008) $
# $Revision: 788 $

#    Copyright (c) 2008 Dominique Dumont.
#
#    This file is part of Config-Model-Backend-Augeas.
#
#    Config-Model is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser Public License as
#    published by the Free Software Foundation; either version 2.1 of
#    the License, or (at your option) any later version.
#
#    Config-Model is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser Public License for more details.
#
#    You should have received a copy of the GNU Lesser Public License
#    along with Config-Model; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA

package Config::Model::Backend::Augeas ;
use Carp;
use strict;
use warnings ;
use Config::Model::Exception ;
use UNIVERSAL ;

my $has_augeas = 1;
eval { require Config::Augeas ;} ;
$has_augeas = 0 if $@ ;

our $VERSION = '0.101';

=head1 NAME

Config::Model::Backend::Augeas - Read and write config data through Augeas

=head1 SYNOPSIS

  # use with Augeas
  $model->create_config_class 
  (
   config_class_name => 'OpenSsh::Sshd',

   # try Augeas and fall-back with custom method
   read_config  => [ { backend => 'augeas' , 
                       config_file => '/etc/ssh/sshd_config',
                       # declare "seq" Augeas elements 
                       lens_with_seq => [/AcceptEnv AllowGroups [etc]/],
                     },
                     { backend => 'custom' , # dir hardcoded in custom class
                       class => 'Config::Model::Sshd' 
                     }
                   ],
   # write_config will be written using read_config specifications


   element => ...
  ) ;

=head1 DESCRIPTION

This class provides a way to load or store configuration data through
L<Config::Augeas>. This way, the structure and commments of the
original configuration file will preserved.

To use Augeas as a backend, you must specify the following
C<read_config> parameters:

=over

=item backend

Use C<augeas> (or C<Augeas>)in this case.

=item save

Either C<backup> or C<newfile>. See L<Config::Augeas/Constructor> for
details.

=item config_file

Name of the config_file.

=item lens_with_seq

This one is tricky. When an Augeas lens use the C<seq> keywords in a
lens, a special type of list element is created (See
L<http://augeas.net/docs/lenses.html> for details on lenses). This
special list element must be declared so that Config::Model can use
the correct Augeas call to write this list values. C<lens_with_seq>
must be passed a list ref of all lens names that contains a C<seq>
statement.

=back

For instance:

   read_config  => [ { backend => 'augeas' , 
                       save   => 'backup',
                       config_file => '/etc/ssh/sshd_config',
                       # declare "seq" Augeas elements 
                       lens_with_seq => [/AcceptEnv AllowGroups/],
                     },
                   ],


=head2 Augeas backend limitation

The structure and element names of the Config::Model tree must match the
structure defined in Augeas lenses.

Sometimes, the structure of a file loaded by Augeas starts directly
with a list of items. For instance C</etc/hosts> structure starts with
a list of lines that specify hosts and IP adresses. The C<set_in>
parameter specifies an element name in Config::Model root class that
will hold the configuration data retrieved by Augeas.

=cut

sub new {
    my $type = shift ;
    my %args = @_ ;
    my $node = $args{node} || croak "write: missing node parameter";
    my $self = { node => $node } ;
    bless $self,$type ;
}

# for tests only
sub _augeas_object {return shift->{augeas_obj} ; } ;

sub read
  {
    my $self = shift;
    my %args = @_ ; # contains root and config_dir
    return 0 unless $has_augeas ;

    print "Read config data from Augeas\n" if $::verbose;

    $self->{augeas_obj} ||= Config::Augeas->new(root => $args{root}, 
						save => $args{save} ) ;

    if (not defined $args{config_file}) {
	Config::Model::Exception::Model -> throw
	    (
	     error=> "read_augeas error: model "
	     . "does not specify 'config_file' for Augeas ",
	     object => $self->{node}
	    ) ;
    }

    my $mainpath = '/files'.$args{config_file} ;

    my @result =  $self->augeas_deep_match($mainpath) ;
    my @cm_path = @result ;

    # cleanup resulting path to remove Augeas '/files', remove the
    # file path and plug the remaining path where it is consistent in
    # the model. I.e if the file "root" matches a list element (like
    # for /etc/hosts), get this element name from "set_in" parameter
    my $set_in = $args{set_in} || '';
    map {
	s!$mainpath!! ;
	$_ = "/$set_in/$_" if $set_in;
	s!/+!/!g;
    } @cm_path ;

    # Create a hash of lens that contain a seq lens
    my %has_seq = map { ( $_ => 1 ) ;} @{$args{lens_with_seq} || []} ;

    my $augeas_obj = $self->{augeas_obj} ;

    # this may break as data will be written in the tree in an order
    # decided by Augeas. This may break complex model with warping as 
    # the best writing order is indicated by the model and not Augeas.
    while (@result) {
	my $aug_p = shift @result;
	my $cm_p  = shift @cm_path;
	my $v = $augeas_obj->get($aug_p) ;
	next unless defined $v ;

	print "read-augeas read $aug_p, set $cm_p with $v\n" if $::debug ;
	$cm_p =~ s!^/!! ;
	# With 'seq' type list, we can get
	# /files/etc/ssh/sshd_config/AcceptEnv[1]/1/ =  LC_PAPER
	# /files/etc/ssh/sshd_config/AcceptEnv[1]/2/ =  LC_NAME
	# /files/etc/ssh/sshd_config/AcceptEnv[2]/3/ =  LC_ADDRESS
	# /files/etc/ssh/sshd_config/AcceptEnv[2]/4/ =  LC_TELEPHONE
	my @cm_steps = split m!/+!, $cm_p ;
	my $obj = $self->{node};

	while (my $step = shift @cm_steps) {
	    my ($label,$idx) = ( $step =~ /(\w+)(?:\[(\d+)\])?/ ) ;

	    # idx will be treated next iteration if needed
	    if (    $obj->get_type eq 'node' 
		and $obj->element_type($label) eq 'list') {
		$idx = 1 unless defined $idx ;
		unshift @cm_steps , $idx unless $has_seq{$label} ;
	    }

	    # augeas list begin at 1 not 0
	    $label -= 1 if $obj->get_type eq 'list';
	    if (@cm_steps) {
		print "read-augeas: get $label ", 
		  ( $has_seq{$label} ? 'seq' : '' ),"\n" if $::debug;
		$obj = $obj->get($label) ;
	    }
	    else {
		# last step
		$obj->set($label,$v) ;
	    }
	}
    }

    return 1 ;
  }

sub augeas_deep_match {
    my ($self,$mainpath) = @_ ;

    # work around Augeas feature where '*' matches only one hierarchy
    # level 
    # See https://www.redhat.com/archives/augeas-devel/2008-July/msg00016.html
    my @worklist = ( $mainpath );
    print "read-augeas on @worklist\n" if $::debug ;

    my $augeas_obj = $self->{augeas_obj} ;
    my @result ;
    while (@worklist) {
	my $p = pop @worklist ;
	my @newpath = $augeas_obj -> match($p . "/*") ;
	print "read-augeas $p/* matches paths: @newpath\n" if $::debug ;
	push @worklist, @newpath ;
	push @result,   @newpath ;
    }

    return @result ;
}

sub write {
    my $self = shift;
    my %args = @_ ; # contains root and config_dir
    return 0 unless $has_augeas ;

    print "Write config data through Augeas\n" if $::verbose;

    if (not defined $args{config_file}) {
	Config::Model::Exception::Model -> throw
	    (
	     error=> "write_augeas error: model "
	     . "does not specify 'config_file' for Augeas ",
	     object => $self->{node}
	    ) ;
    }

    my $set_in = $args{set_in} || '';
    my $mainpath = '/files'.$args{config_file} ;
    my $augeas_obj = $self->{augeas_obj} ;

    my %to_set = $self->copy_in_augeas($augeas_obj,$mainpath,$set_in,
				       $args{lens_with_seq}) ;

    # foreach my $path (keys %to_set) {
    # 	my $aug_path = "$mainpath$path" ;
    # 	my $v = $to_set{$path} ;
    # 	print "write-augeas $path, set $aug_path with $v\n" if $::debug ;
    # 	# remove all Augeas paths that are included in the path found in
    # 	# config-model
    # 	map {delete $old_path{$_} if index($aug_path,$_,0) == 0} keys %old_path ;
    # 	$augeas_obj->set($aug_path,$v) ;
    # }

    # remove path no longer present in config-model
    #map { print "deleting aug path $_\n" if $::debug;
    # $augeas_obj->remove($_) } reverse sort keys %old_path ;

    $augeas_obj->save || warn "Augeas save failed";;
}

sub copy_in_augeas {
    my $self = shift ;
    my $augeas_obj = shift ;
    my $mainpath = shift ;
    my $set_in = shift ;
    my $seq_list = shift || [];
    my %has_seq = map { ( $_ => 1 ) ;} @$seq_list ;

    # cleanup the tree. This is not subtle and may be improved when the
    # following bugs are fixed:
    # https://fedorahosted.org/augeas/ticket/23
    # https://fedorahosted.org/augeas/ticket/24

    $augeas_obj->remove("$mainpath/*") ;

    # data_ref = ( current_path ) 
    my $std_cb = sub {
        my ( $scanner, $data_ref, $obj, $element, $index, $value_obj ) = @_;
	my $p = $data_ref->[0] ;
	my $v = $value_obj->fetch () ; 
	if (defined $v) {
	    $augeas_obj->set($p , $v) ;
	    print "copy_in_augeas: set $p = '$v'\n" if $::debug;
	}
    };

    my $hash_element_cb = sub {
	my ($scanner, $data_ref,$node,$element_name,@keys) = @_ ;
	my $p = $data_ref->[0] ;

	map {$scanner->scan_hash([$p."/$_"],$node,$element_name,$_)} @keys ;
    };

    my $list_element_cb = sub {
	my ($scanner, $data_ref,$node,$element_name,@idx) = @_ ;
	my $p = $data_ref->[0] ;

	my $seq_item = $has_seq{$element_name} || 0 ;
	map { my $aug_idx = $_ + 1 ; # Augeas lists begin at 1 not 0
	      my $subpath =  $seq_item ? "[last()]/$aug_idx" : "[$aug_idx]" ;
	      $scanner->scan_list([$p.$subpath], $node,$element_name,$_);
	  } @idx ;
    };

    my $node_content_cb = sub {
	my ($scanner, $data_ref,$node,@element) = @_ ;
	my $p = $data_ref->[0] ;
	map {
	    # Deal with the fact that Augeas tree can start directly into
	    # a list element
	    my $np = (defined $set_in and $set_in eq $_) ? $p : $p."/$_" ;
	    $scanner->scan_element([$np], $node,$_)
	} @element ;
    };

    my @scan_args = (
		     experience            => 'master',
		     fallback              => 'all',
		     auto_vivify           => 0,
		     list_element_cb       => $list_element_cb,
		     check_list_element_cb => $std_cb,
		     hash_element_cb       => $hash_element_cb,
		     leaf_cb               => $std_cb ,
		     node_content_cb       => $node_content_cb,
		    );

    # perform the scan
    my $view_scanner = Config::Model::ObjTreeScanner->new(@scan_args);

    $view_scanner->scan_node([$mainpath] ,$self->{node});
}

1;
