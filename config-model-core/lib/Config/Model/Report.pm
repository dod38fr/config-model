
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

package Config::Model::Report;
use Carp;
use strict;
use warnings ;

use Config::Model::Exception ;
use Config::Model::ObjTreeScanner ;
use Text::Wrap ;

# use vars qw($VERSION);

=head1 NAME

Config::Model::Report - Reports data from config tree

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

 # report only customized data (audit mode)
 print $root->audit;

 # report all data including default values
 print $root->report ;

=head1 DESCRIPTION

This module is used directly by L<Config::Model::Node> to provide
a human readable report of the configuration. This report includes
the configuration values and (if provided by the model) the description
of the configuration item and their effect.

A C<report> will show C<all> configuration items. An C<audit> will
show only configuration items which are different from their default
value.

=head1 CONSTRUCTOR

=head2 new ( )

No parameter. The constructor should be used only by
L<Config::Model::Node>.

=cut

sub new {
    bless {}, shift ;
}

=head1 Methods

=head2 report

Returns a string containing the configuration values and (if provided
by the model) the description of the configuration item and their
effect.

Parameters are:

=over

=item audit

Set to 1 to report only configuration data different from default
values. Default is 0.

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

    my $std_cb = sub {
        my ( $scanner, $data_r, $obj, $element, $index, $value_obj ) = @_;

	# if element is a collection, get the value pointed by $index
	$value_obj = $obj->fetch_element($element)->fetch_with_id($index) 
	  if defined $index ;

	# get value or only customized value
	my $value = $audit ? $value_obj->fetch_custom : $value_obj->fetch ;

        $value = '"' . $value . '"' if defined $value and $value =~ /\s/;

	if (defined $value) {
	    my $name = defined $index ? " $element:$index" : $element;
	    push @$data_r , $obj->location." $name = $value";
	    my $desc = $obj->get_help($element) ;
	    if (defined $desc and $desc) {
		push @$data_r , wrap ("\t","\t\t", "DESCRIPTION: $desc" ) ;
	    }
	    my $effect = $value_obj->get_help($value) ;
	    if (defined $effect and $effect) {
		push @$data_r, wrap ("\t","\t\t", "SELECTED: $effect" ) ;
	    }
	    push @$data_r , '' ; # to get empty line in report
	}
    };

    my @scan_args = (
		     experience  => delete $args{experience} || 'master',
		     fallback    => 'all',
		     auto_vivify => 0,
		     leaf_cb     => $std_cb,
		    );

    my @left = keys %args;
    croak "Report: unknown parameter:@left" if @left;

    # perform the scan
    my $view_scanner = Config::Model::ObjTreeScanner->new(@scan_args);

    my @ret ;
    $view_scanner->scan_node(\@ret ,$node);

    return join ("\n", @ret);
}

1;

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>,L<Config::Model::Node>,L<Config::Model::Walker>
