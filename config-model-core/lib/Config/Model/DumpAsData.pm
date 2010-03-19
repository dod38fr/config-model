
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

# use vars qw($VERSION);

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

Note that undefined values are skipped for list element. I.e. if a
list element contains C<('a',undef,'b')>, the data structure will
contain C<'a','b'>.

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
configuration data will be used by the application. (default is yes)

=item skip_auto_write

Skip node that have a C<perl write> capabality in their model. See
L<Config::Model::AutoRead>.

=item auto_vivify

Scan and create data for nodes elements even if no actual data was
stored in them. This may be useful to trap missing mandatory values.

=item ordered_hash_as_list

By default, ordered hash (i.e. the order of the keys are important)
are dumped as Perl list. This is the faster way to dump such hashed
while keeping the key order. But it's the less readable way. 

When this parmeter is 1 (default), the ordered hash is dumped as a
list:

  [ A => 'foo', B => 'bar', C => 'baz' ]

When this parameter is set as 0, the ordered hash is dumped with a
special key that specifies the order of keys. E.g.:

  { __order => [ 'A', 'B', 'C' ] ,
    B => 'bar', A => 'foo', C => 'baz' 
  }

=back

=cut

sub dump_as_data {
    my $self = shift ;

    my %args = @_;
    my $dump_node = delete $args{node} 
      || croak "dumpribe: missing 'node' parameter";
    my $full = delete $args{full_dump} ;
    $full = 1 unless defined $full ;
    my $skip_aw = delete $args{skip_auto_write} || '' ;
    my $auto_v  = delete $args{auto_vivify}     || 0 ;
    my $ordered_hash_as_list = delete $args{ordered_hash_as_list} ;
    $ordered_hash_as_list = 1 unless defined $ordered_hash_as_list ;

    my $std_cb = sub {
        my ( $scanner, $data_r, $obj, $element, $index, $value_obj ) = @_;

	$$data_r =  $full ? $value_obj->fetch ('non_upstream_default')
                 :          $value_obj->fetch_custom ;
    };

    my $check_list_element_cb = sub {
        my ( $scanner, $data_r, $node, $element_name, @check_items ) = @_;
	my $a_ref = $node->fetch_element($element_name)->get_checked_list;
	# don't store empty checklist
	$$data_r = $a_ref if @$a_ref;
    };

    my $hash_element_cb = sub {
	my ($scanner, $data_ref,$node,$element_name,@keys) = @_ ;

	# resume exploration but pass a ref on $data_ref hash element
	# instead of data_ref
	my %h ;
	my @res = map { 
	    my $v ;
	    $scanner->scan_hash(\$v,$node,$element_name,$_);
	    # create the key even if $v is undef 
	    $h{$_} = $v ;
	    ( $_ , $v ) ;
	} @keys ;

	my $ordered_hash = $node->fetch_element($element_name)->ordered ;

	if ( $ordered_hash and $ordered_hash_as_list ) {
	    $$data_ref = \@res if @res ;
	}
	else {
	    $h{__order} = \@keys if $ordered_hash and @keys;
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

	return if $skip_aw and $next->is_auto_write_for_type($skip_aw) ;

	$scanner->scan_node($data_ref,$next);
    } ;

    my @scan_args = (
		     experience            => delete $args{experience} || 'master',
		     fallback              => 'all',
		     auto_vivify           => $auto_v,
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

    my $obj_type = $dump_node->get_type ;
    my $result ;
    my $p = $dump_node->parent;
    my $e = $dump_node->element_name ;
    my $i = $dump_node->index_value ; # defined only for hash and list

    if ($obj_type =~ /node/) {
	$view_scanner->scan_node(\$result ,$dump_node);
    }
    elsif ( defined $i ) {
	$view_scanner->scan_hash(\$result ,$p,$e,$i);
    }
    elsif (   $obj_type eq 'list' or $obj_type eq 'hash' 
	   or $obj_type eq 'leaf' or $obj_type eq 'check_list') {
	$view_scanner->scan_element(\$result ,$p,$e);
    }
    else {
	croak "dump_as_data: unexpected type: $obj_type";
    }

    return $result ;
}

1;

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>,L<Config::Model::Node>,L<Config::Model::ObjTreeScanner>
