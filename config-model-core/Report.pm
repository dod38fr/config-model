# $Author: ddumont $
# $Date: 2006-05-17 11:59:26 $
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

package Config::Model::Report;
use Carp;
use strict;
use warnings ;

use Config::Model::Exception ;
use Config::Model::ObjTreeScanner ;
use Text::Wrap ;

use vars qw($VERSION);
$VERSION = sprintf "%d.%03d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/;

=head1 NAME

Config::Model::Report - Serialize data of config tree

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

 # put some data in config tree
 my $step = 'std_id:ab X=Bv - std_id:bc X=Av - a_string="toto tata"';
 $root->walk( step => $step ) ;

 # dump only customized data (audit mode)
 print $root->dump_tree;

 # dump all data including default values
 print $root->dump_tree( full_dump => 1 ) ;

=head1 DESCRIPTION

This module is used directly by L<Config::Model::Node> to serialize 
configuration data in a compact (but readable) string.

The serialisation can be done in standard mode where only customized
values are dumped in the string. I.e. only data modified by the user
are dumped.

The other mode is C<full_dump> mode where all all data, including
default values, are dumped.

The serialized string can be used by L<Config::Model::Walker> to store
the data back into a configuration tree.

=head1 CONSTRUCTOR

=head2 new ( )

No parameter. The constructor should be used only by
L<Config::Model::Node>.

=cut

sub new {
    bless {}, shift ;
}

=head1 Methods

=head2 dump_tree

Return a string that contains a dump of the object tree with all the
values. This string follows the convention defined by
L<Config::Model::Walker>.

The serialized string can be used by L<Config::Model::Walker> to store
the data back into a configuration tree.

Parameters are:

=over

=item full_dump

Set to 1 to dump all configuration data including default
values. Default is 0, where the dump contains only data modified by
the user (i.e. data differ from default values).

=item node

Reference to the L<Config::Model::Node> object that is dumped. All
nodes and leaves attached to this node are also dumped.

=back

=cut

sub report {
    my $self = shift;

    my %args = @_;
    my $audit = delete $args{audit} || 0;
    my $node = delete $args{node} 
      || croak "dump_tree: missing 'node' parameter";

    my $ret = '';

    my $std_cb = sub {
        my ( $obj, $element, $index, $value_obj ) = @_;

	# if element is a collection, get the value pointed by $index
	$value_obj = $obj->fetch_element($element)->fetch_with_id($index) 
	  if defined $index ;

	# get value or only customized value
	my $value = $audit ? $value_obj->fetch_custom : $value_obj->fetch ;

        $value = '"' . $value . '"' if defined $value and $value =~ /\s/;

	if (defined $value) {
	    my $name = defined $index ? " $element:$index" : $element;
	    $ret .= "\n\n" . $obj->location." $name = $value";
	    my $desc = $obj->get_help($element) ;
	    if (defined $desc and $desc) {
		$ret .= "\n". wrap ("\t","\t\t", "DESCRIPION: $desc" ) ;
	    }
	    my $effect = $value_obj->get_help($value) ;
	    if (defined $effect and $effect) {
		$ret .= "\n". wrap ("\t","\t\t", "SELECTED: $effect" ) ;
	    }
	}
    };

    my @scan_args = (
		     permission  => delete $args{permission} || 'master',
		     fallback    => 'all',
		     auto_vivify => 0,
		     leaf_cb     => $std_cb,
		    );

    my @left = keys %args;
    croak "Report: unknown parameter:@left" if @left;

    # perform the scan
    my $view_scanner = Config::Model::ObjTreeScanner->new(@scan_args);

    $view_scanner->scan_node($node);

    substr( $ret, 0, 2, '' );    # remove leading \n\n
    return $ret . "\n";
}

1;

=head1 AUTHOR

Dominique Dumont, domi@komarr.grenoble.hp.com

=head1 SEE ALSO

L<Config::Model>,L<Config::Model::Node>,L<Config::Model::Walker>
