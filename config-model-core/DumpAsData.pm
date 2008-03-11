# $Author: ddumont $
# $Date: 2007-12-04 12:32:06 $
# $Revision: 1.3 $

#    Copyright (c) 2007 Dominique Dumont.
#
#    This file is part of Config-Model.
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

package Config::Model::DumpAsData;
use Carp;
use strict;
use warnings ;

use Config::Model::Exception ;
use Config::Model::ObjTreeScanner ;

use vars qw($VERSION);
$VERSION = sprintf "1.%04d", q$Revision: 1.3 $ =~ /(\d+)/;

=head1 NAME

Config::Model::DumpAsData - Dump configuration content as a perl data structure

=head1 SYNOPSIS

 use Config::Model ;

 # create your config model
 my $model = Config::Model -> new ;
 $model->create_config_class( ... ) ;

 # create instance
 my $inst = $model->instance (root_class_name => 'FooBar', 
			      instance_name => 'test1');

 # create root of config
 my $root = $inst -> config_root ;

 my $data =  $root->dump_as_data ;

=head1 DESCRIPTION

This module is used directly by L<Config::Model::Node> to dump the content
of a configuration tree in perl data structure.

The perl data structure is a hash of hash. Only
L<CheckList|Config::Model::CheckList> content will be stored in an array ref.

=head1 CONSTRUCTOR

=head2 new ( )

No parameter. The constructor should be used only by
L<Config::Model::Node>.

=cut

sub new {
    bless {}, shift ;
}

=head1 Methods

=head2 dump_as_data(...)

Return a perl data structure

Parameters are:

=over

=item node

Reference to a L<Config::Model::Node> object. Mandatory

=item full_dump

Also dump default values in the data structure. Useful if the dumped
configuration data will be used by the application.

=item skip_auto_write

Skip node that have a C<perl write> capabality in their model. See
L<Config::Model::AutoRead>.

=back

=cut

sub dump_as_data {
    my $self = shift ;

    my %args = @_;
    my $dump_node = delete $args{node} 
      || croak "dumpribe: missing 'node' parameter";
    my $full = delete $args{full_dump} || 0;
    my $skip_aw = delete $args{skip_auto_write} || 0 ;

    my $std_cb = sub {
        my ( $scanner, $data_r, $obj, $element, $index, $value_obj ) = @_;

	$$data_r =  $full ? $value_obj->fetch : $value_obj->fetch_custom ;
    };

    my $check_list_element_cb = sub {
        my ( $scanner, $data_r, $node, $element_name, @check_items ) = @_;
	$$data_r = $node->fetch_element($element_name)->get_checked_list;
    };

    my $hash_element_cb = sub {
	my ($scanner, $data_ref,$node,$element_name,@keys) = @_ ;

	# resume exploration but pass a ref on $data_ref hash element
	# instead of data_ref
	my %h ;
	my @res = map { 
	    my $v ;
	    $scanner->scan_hash(\$v,$node,$element_name,$_);
	    $h{$_} = $v if defined $v ;
	    defined $v ? ( $_ , $v ) : () ;
	} @keys ;
	if ($node->fetch_element($element_name)->ordered) {
	    $$data_ref = \@res if @res ;
	}
	else {
	    $$data_ref = \%h if scalar %h ;
	}
    };

    my $list_element_cb = sub {
	my ($scanner, $data_ref,$node,$element_name,@idx) = @_ ;

	# resume exploration but pass a ref on $data_ref hash element
	# instead of data_ref
	my @a ;
	map { 
	    my $v ;
	    $scanner->scan_hash(\$v,$node,$element_name,$_);
	    push @a ,$v if defined $v ;
	} @idx ;
	$$data_ref = \@a if scalar @a ;
    };

    my $node_content_cb = sub {
	my ($scanner, $data_ref,$node,@element) = @_ ;
	my %h ;
	map { 
	    my $v ;
	    $scanner->scan_element(\$v, $node,$_) ;
	    $h{$_} = $v if defined $v ;
	} @element ;
	$$data_ref = \%h  if scalar %h ;
    };

    my $node_element_cb = sub {
	my ($scanner, $data_ref,$node,$element_name,$key, $next) = @_ ;

	return if $skip_aw and $next->is_auto_write_for_type('perl') ;

	$scanner->scan_node($data_ref,$next);
    } ;

    my @scan_args = (
		     permission            => delete $args{permission} || 'master',
		     fallback              => 'all',
		     auto_vivify           => 0,
		     list_element_cb       => $list_element_cb,
		     check_list_element_cb => $check_list_element_cb,
		     hash_element_cb       => $hash_element_cb,
		     leaf_cb               => $std_cb ,
		     node_element_cb       => $node_element_cb,
		     node_content_cb       => $node_content_cb,
		    );

    my @left = keys %args;
    croak "DumpAsData: unknown parameter:@left" if @left;

    # perform the scan
    my $view_scanner = Config::Model::ObjTreeScanner->new(@scan_args);

    my $result = {};

    $view_scanner->scan_node(\$result ,$dump_node);

    return $result ;
}

1;

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>,L<Config::Model::Node>,L<Config::Model::ObjTreeScanner>
