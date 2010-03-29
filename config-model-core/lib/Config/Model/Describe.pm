
#    Copyright (c) 2006-2007 Dominique Dumont.
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

package Config::Model::Describe;
use Carp;
use strict;
our $VERSION="1.201";
use warnings ;

use Config::Model::Exception ;
use Config::Model::ObjTreeScanner ;

# use vars qw($VERSION);

=head1 NAME

Config::Model::Describe - Provide a description of a node element

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

 print $root->describe ;

 # or

 print $root->describe(element => 'foo' ) ;

=head1 DESCRIPTION

This module is used directly by L<Config::Model::Node> to describe
a node element. This module returns a human readable string that 
shows the content of a configuration node.

For instance (as showns by C<fstab> example:

 name         value        type         comment
 fs_spec      [undef]      string       mandatory
 fs_vfstype   [undef]      enum         choice: auto davfs ext2 ext3 swap proc iso9660 vfat ignore, mandatory
 fs_file      [undef]      string       mandatory
 fs_freq      0            boolean
 fs_passno    0            integer

This module is also used by the C<ll> command of L<Config::Model::TermUI>.

=head1 CONSTRUCTOR

=head2 new ( )

No parameter. The constructor should be used only by
L<Config::Model::Node>.

=cut

sub new {
    bless {}, shift ;
}

=head1 Methods

=head2 describe(...)

Return a description string.

Parameters are:

=over

=item node

Reference to a L<Config::Model::Node> object. Mandatory

=item element

Describe only this element from the node. Optional. All elements are
described if omitted.

=back

=cut

sub describe {
    my $self = shift ;

    my %args = @_;
    my $desc_node = delete $args{node} 
      || croak "describe: missing 'node' parameter";
    my $element = delete $args{element} ; # optional

    my $std_cb = sub {
        my ( $scanner, $data_r, $obj, $element, $index, $value_obj ) = @_;

	my $value = $value_obj->fetch ;
        $value = '"' . $value . '"' if defined $value and $value =~ /\s/;

	#print "DEBUG: std_cb on $element, idx $index, value $value\n";

	my $name = defined $index ? "$element:$index" : $element;
        $value = defined $value ? $value : '[undef]' ;

	my $type = $value_obj->value_type ;
	my @comment ;
	push @comment, "choice: " . join(' ',@{$value_obj->choice}) 
	  if $type eq 'enum' ;
	push @comment, 'mandatory' if $value_obj->mandatory ;

	push @$data_r , [ $name, $value, $type, join(', ',@comment) ]  ;
    };

    my $list_element_cb = sub {
        my ( $scanner, $data_r, $obj, $element, @keys ) = @_;

	#print "DEBUG: list_element_cb on $element, keys @keys\n";
	my $list_obj = $obj->fetch_element($element) ;
        my $elt_type = $list_obj->cargo_type ;

        if ( $elt_type eq 'node' ) {
	    my $class_name = $list_obj->config_class_name ;
	    my @show_keys = @keys ? @keys : ('<empty>')  ;
	    push @$data_r , [ $element, "<$class_name>", 
			    'node list', "indexes: @show_keys" ];
        }
        else {
            push @$data_r , [ $element,
			    join( ',', $list_obj->fetch_all_values ),
			    'list','' ];
        }
    };

    my $check_list_element_cb = sub {
        my ( $scanner, $data_r, $obj, $element, @choices ) = @_;

	my $list_obj = $obj->fetch_element($element) ;
	push @$data_r , [ $element,
			  join( ',', $list_obj->get_checked_list ),
			  'check_list','' ];
    };

    my $hash_element_cb = sub {
        my ( $scanner, $data_r, $obj, $element, @keys ) = @_;

 	#print "DEBUG: hash_element_cb on $element, keys @keys\n";
	my $hash_obj = $obj->fetch_element($element) ;
	my $elt_type = $hash_obj->cargo_type ;

        if ( $elt_type eq 'node' ) {
	    my $class_name = $hash_obj->config_class_name ;
	    my @show_keys = @keys ? map { qq("$_") } @keys : ('<empty>')  ;
	    my $show_str = "keys: @show_keys";
	    push @$data_r , [ $element, "<$class_name>", 
			    'node hash', $show_str ];
        }
        elsif (@keys) {
            map {$scanner->scan_hash($data_r, $obj,$element,$_)} @keys ;
        }
	else {
	    push @$data_r, [ $element, "[empty hash]", 'value hash', "" ];
	}
    };

    my $node_element_cb = sub {
        my ( $scanner, $data_r, $obj, $element, $key, $next ) = @_;

 	#print "DEBUG: elt_cb on $element, key $key\n";
        my $type = $obj -> element_type($element);

	my $class_name = $next->config_class_name ;
        push @$data_r, [ $element,"<$class_name>",'node','' ];
	#$ret .= ":$key" if $type eq 'list' or $type eq 'hash';

        #$view_scanner->scan_node($next);
    };

    my @scan_args = (
		     experience            => delete $args{experience} || 'master',
		     fallback              => 'all',
		     auto_vivify           => 0,
		     list_element_cb       => $list_element_cb,
		     check_list_element_cb => $check_list_element_cb,
		     hash_element_cb       => $hash_element_cb,
		     leaf_cb               => $std_cb ,
		     node_element_cb       => $node_element_cb,
		    );

    my @left = keys %args;
    croak "Describe: unknown parameter:@left" if @left;

    # perform the scan
    my $view_scanner = Config::Model::ObjTreeScanner->new(@scan_args);

    my $format = "%-12s %-12s %-12s %-35s\n" ;

    my @ret = [ qw/name value type comment/ ];

    if (defined $element and $desc_node->has_element($element)) {
	$view_scanner->scan_element(\@ret ,$desc_node, $element);
    }
    elsif (defined $element) {
	Config::Model::Exception::UnknownElement
		->throw(
			object   => $desc_node,
			function => 'Describe',
			where    => $desc_node->location || 'configuration root',
			element     => $element,
		       ) ;
    }
    else {
	$view_scanner->scan_node(\@ret ,$desc_node);
    }

    return join '', map { sprintf($format, @$_) } @ret ; 
}

1;

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>,L<Config::Model::Node>,L<Config::Model::ObjTreeScanner>
