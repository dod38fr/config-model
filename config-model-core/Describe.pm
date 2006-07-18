# $Author: ddumont $
# $Date: 2006-07-18 11:52:36 $
# $Name: not supported by cvs2svn $
# $Revision: 1.1 $

#    Copyright (c) 2006 Dominique Dumont.
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
use warnings ;

use Config::Model::Exception ;
use Config::Model::ObjTreeScanner ;

use vars qw($VERSION);
$VERSION = sprintf "%d.%03d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/;

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

=back

=cut

sub describe {
    my $self = shift ;

    my %args = @_;
    my $desc_node = delete $args{node} 
      || croak "describe: missing 'node' parameter";

    my $format = "%-12s %-12s %-12s %-35s\n" ;

    my $ret = sprintf($format, qw/name value type comment/);

    my $std_cb = sub {
        my ( $obj, $element, $index, $value_obj ) = @_;

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

	$ret .= sprintf($format, $name, $value, $type, 
			join(', ',@comment) ) ;
    };

    my $view_scanner;

    my $list_cb = sub {
        my ( $obj, $element, @keys ) = @_;

	#print "DEBUG: list_cb on $element, keys @keys\n";
	my $list_obj = $obj->fetch_element($element) ;
        my $elt_type = $list_obj->collected_type ;

        if ( $elt_type eq 'node' ) {
	    my $class_name = $list_obj->config_class_name ;
	    $ret .= sprintf($format, $element, "<$class_name>", 
			    'node list', 
			    @keys ? "keys: @keys" : 'empty list');
        }
        else {
            $ret .= sprintf($format,$element,
			    join( ',', $list_obj->fetch_all_values ),
			    'list',''
			   );
        }
    };

    my $hash_cb = sub {
        my ( $obj, $element, @keys ) = @_;

 	#print "DEBUG: hash_cb on $element, keys @keys\n";
	my $hash_obj = $obj->fetch_element($element) ;
	my $elt_type = $hash_obj->collected_type ;

        if ( $elt_type eq 'node' ) {
	    my $class_name = $hash_obj->config_class_name ;
	    $ret .= sprintf($format, $element, "<$class_name>", 
			    'node hash', "keys: @keys");
        }
        elsif (@keys) {
            map {$view_scanner->scan_hash($obj,$element,$_)} @keys ;
        }
	else {
	    $ret .= sprintf($format, $element, "[empty hash]", 
			    'value hash', "");
	}
    };

    my $node_cb = sub {
        my ( $obj, $element, $key ) = @_;

 	#print "DEBUG: elt_cb on $element, key $key\n";
        my $type = $obj -> element_type($element);
	my $next = $obj -> fetch_element($element) ;

        $next = $next ->fetch_with_id($key) if
              $type eq 'list' or $type eq 'hash';
	my $class_name = $next->config_class_name ;
        $ret .= sprintf($format,$element,"<$class_name>",'node','');
	#$ret .= ":$key" if $type eq 'list' or $type eq 'hash';

        #$view_scanner->scan_node($next);
    };

    my @scan_args = (
		     permission        => delete $args{permission} || 'master',
		     fallback    => 'all',
		     auto_vivify => 0,
		     list_cb     => $list_cb,
		     hash_cb     => $hash_cb,
		     leaf_cb     => $std_cb,
		     node_cb     => $node_cb,
		    );

    my @left = keys %args;
    croak "Describe: unknown parameter:@left" if @left;

    # perform the scan
    $view_scanner = Config::Model::ObjTreeScanner->new(@scan_args);

    $view_scanner->scan_node($desc_node);

    return $ret ;
}

1;

=head1 AUTHOR

Dominique Dumont, domi@komarr.grenoble.hp.com

=head1 SEE ALSO

L<Config::Model>,L<Config::Model::Node>,L<Config::Model::ObjTreeScanner>
