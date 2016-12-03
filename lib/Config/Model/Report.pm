package Config::Model::Report;

use Carp;
use strict;
use warnings;

use Config::Model::Exception;
use Config::Model::ObjTreeScanner;
use Text::Wrap;

sub new {
    bless {}, shift;
}

sub report {
    my $self = shift;

    my %args  = @_;
    my $audit = delete $args{audit} || 0;
    my $node  = delete $args{node}
        || croak "dump_tree: missing 'node' parameter";

    my $std_cb = sub {
        my ( $scanner, $data_r, $obj, $element, $index, $value_obj ) = @_;

        # if element is a collection, get the value pointed by $index
        $value_obj = $obj->fetch_element($element)->fetch_with_id($index)
            if defined $index;

        # get value or only customized value
        my $value = $audit ? $value_obj->fetch_custom : $value_obj->fetch;

        $value = '"' . $value . '"' if defined $value and $value =~ /\s/;

        if ( defined $value ) {
            my $name = defined $index ? " $element:$index" : $element;
            push @$data_r, $obj->location . " $name = $value";
            my $desc = $obj->get_help_as_text($element);
            if ( defined $desc and $desc ) {
                push @$data_r, wrap( "\t", "\t\t", "DESCRIPTION: $desc" );
            }
            my $effect = $value_obj->get_help_as_text($value);
            if ( defined $effect and $effect ) {
                push @$data_r, wrap( "\t", "\t\t", "SELECTED: $effect" );
            }
            push @$data_r, '';    # to get empty line in report
        }
    };

    my @scan_args = (
        fallback => 'all',
        auto_vivify => 0,
        leaf_cb     => $std_cb,
    );

    my @left = keys %args;
    croak "Report: unknown parameter:@left" if @left;

    # perform the scan
    my $view_scanner = Config::Model::ObjTreeScanner->new(@scan_args);

    my @ret;
    $view_scanner->scan_node( \@ret, $node );

    return join( "\n", @ret );
}

1;

# ABSTRACT: Reports data from config tree

__END__

=head1 SYNOPSIS

 use Config::Model;

 # define configuration tree object
 my $model = Config::Model->new;
 $model->create_config_class(
    name    => "Foo",
    element => [
        [qw/foo bar/] => {
            type       => 'leaf',
            value_type => 'string'
        },
    ],
    description => [
        foo => 'some foo explanation',
        bar => 'some bar explanation',
    ]
 );

 $model->create_config_class(
    name => "MyClass",

    element => [

        [qw/foo bar/] => {
            type       => 'leaf',
            value_type => 'string'
        },
        my_enum => {
            type       => 'leaf',
            value_type => 'enum',
            choice     => [qw/A B C/],
            help       => {
                A => 'first letter',
                B => 'second letter',
                C => 'third letter',
            },
            description => 'some letters',
        },
        hash_of_nodes => {
            type       => 'hash',     # hash id
            index_type => 'string',
            cargo      => {
                type              => 'node',
                config_class_name => 'Foo'
            },
        },
    ],
 );

 my $inst = $model->instance(root_class_name => 'MyClass' );

 my $root = $inst->config_root ;

 # put data
 my $steps = 'foo=FOO my_enum=B hash_of_nodes:fr foo=bonjour -
   hash_of_nodes:en foo=hello ';
 $root->load( steps => $steps );

 print $root->report ;
 #  foo = FOO
 # 
 #  my_enum = B
 #         DESCRIPTION: some letters
 #         SELECTED: second letter
 # 
 # hash_of_nodes:en foo = hello
 #         DESCRIPTION: some foo explanation
 # 
 # hash_of_nodes:fr foo = bonjour
 #         DESCRIPTION: some foo explanation

=head1 DESCRIPTION

This module is used directly by L<Config::Model::Node> to provide
a human readable report of the configuration. This report includes
the configuration values and (if provided by the model) the description
of the configuration item and their effect.

A C<report> shows C<all> configuration items. An C<audit>
shows only configuration items which are different from their default
value.

=head1 CONSTRUCTOR

=head2 new ( )

No parameter. The constructor should be used only by
L<Config::Model::Node>.

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

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>,L<Config::Model::Node>,L<Config::Model::Walker>

=cut
