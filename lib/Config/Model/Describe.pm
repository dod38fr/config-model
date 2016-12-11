
package Config::Model::Describe;

use Carp;
use strict;
use warnings;

use Config::Model::Exception;
use Config::Model::ObjTreeScanner;
use List::Util qw/max/;
use utf8;

sub new {
    bless {}, shift;
}

sub describe {
    my $self = shift;

    my %args      = @_;
    my $desc_node = delete $args{node}
        || croak "describe: missing 'node' parameter";
    my $check = delete $args{check} || 'yes';

    my $element    = delete $args{element} ;        # optional
    my $pattern    = delete $args{pattern} ;        # optional
    my $hide_empty = delete $args{hide_empty} // 0 ; # optional
    my $verbose    = delete $args{verbose}    // 0 ; # optional

    my $show_empty = ! $hide_empty ;

    my $tag_name = sub {
        $_[1] .= ' ⚠' if $_[0]->has_warning;
    };

    my $my_content_cb = sub {
        my ( $scanner, $data_ref, $node, @element ) = @_;
        # filter elements according to pattern
        my @scan = $pattern ? grep { $_ =~ $pattern } @element : @element;
        map { $scanner->scan_element( $data_ref, $node, $_ ) } @scan;
    };

    my $std_cb = sub {
        my ( $scanner, $data_r, $obj, $element, $index, $value_obj ) = @_;

        my $value = $value_obj->fetch( check => $check );

        return unless $show_empty or (defined $value and length($value));

        $value = '"' . $value . '"' if defined $value and $value =~ /\s/;

        #print "DEBUG: std_cb on $element, idx $index, value $value\n";

        my $name = defined $index ? "$element:$index" : $element;
        $value = defined $value ? $value : '[undef]';

        my $type = $value_obj->value_type;
        my @comment;
        push @comment, "choice: " . join( ' ', @{ $value_obj->choice } )
            if $type eq 'enum';
        push @comment, 'mandatory' if $value_obj->mandatory;

        $tag_name->($value_obj,$element);
        push @$data_r, [ $name, $type, $value, join( ', ', @comment ) ];
    };

    my $list_element_cb = sub {
        my ( $scanner, $data_r, $obj, $element, @keys ) = @_;

        #print "DEBUG: list_element_cb on $element, keys @keys\n";
        my $list_obj = $obj->fetch_element($element);
        my $elt_type = $list_obj->cargo_type;

        $tag_name->($list_obj,$element);
        if ( $elt_type eq 'node' ) {
            my $class_name = $list_obj->config_class_name;
            my @show_keys = @keys ? @keys : ('<empty>');
            push @$data_r, [ $element, "<$class_name>", 'node list', "indexes: @show_keys" ];
        }
        else {
            my @values = grep {  $show_empty or length } $list_obj->fetch_all_values( check => 'no' ) ;
            push @$data_r,
                [ $element, 'list', join( ',', @values ), '' ] if ($show_empty or @values);
        }
    };

    my $check_list_element_cb = sub {
        my ( $scanner, $data_r, $obj, $element, @choices ) = @_;

        my $list_obj = $obj->fetch_element($element);
        $tag_name->($list_obj,$element);
        my @checked = $list_obj->get_checked_list;
        push @$data_r, [ $element, 'check_list', join( ',', @checked ), '' ] if $show_empty or @checked;
    };

    my $hash_element_cb = sub {
        my ( $scanner, $data_r, $obj, $element, @keys ) = @_;

        #print "DEBUG: hash_element_cb on $element, keys @keys\n";
        my $hash_obj = $obj->fetch_element($element);
        my $elt_type = $hash_obj->cargo_type;

        $tag_name->($hash_obj,$element);
        if ( $elt_type eq 'node' ) {
            my $class_name = $hash_obj->config_class_name;
            my @show_keys  = @keys ? map { qq("$_") } @keys : ('<empty>');
            my $show_str   = "keys: @show_keys";
            push @$data_r, [ $element, 'node hash', "<$class_name>", $show_str ];
        }
        elsif (@keys) {
            map { $scanner->scan_hash( $data_r, $obj, $element, $_ ) } @keys;
        }
        else {
            push @$data_r, [ $element, 'value hash', "[empty hash]",  "" ] if $show_empty;
        }
    };

    my $node_element_cb = sub {
        my ( $scanner, $data_r, $obj, $element, $key, $next ) = @_;

        #print "DEBUG: elt_cb on $element, key $key\n";
        my $type = $obj->element_type($element);

        my $class_name = $next->config_class_name;
        push @$data_r, [ $element, 'node', "<$class_name>", '' ];

        #$ret .= ":$key" if $type eq 'list' or $type eq 'hash';

        #$view_scanner->scan_node($next);
    };

    my @scan_args = (
        fallback => 'all',
        auto_vivify           => 0,
        list_element_cb       => $list_element_cb,
        check_list_element_cb => $check_list_element_cb,
        hash_element_cb       => $hash_element_cb,
        leaf_cb               => $std_cb,
        node_element_cb       => $node_element_cb,
        node_content_cb       => $my_content_cb,
    );

    my @left = keys %args;
    croak "Describe: unknown parameter:@left" if @left;

    # perform the scan
    my $view_scanner = Config::Model::ObjTreeScanner->new(@scan_args);

    my @ret;
    if ( defined $element and $desc_node->has_element($element) ) {
        $view_scanner->scan_element( \@ret, $desc_node, $element );
    }
    elsif ( defined $element ) {
        Config::Model::Exception::UnknownElement->throw(
            object   => $desc_node,
            function => 'Describe',
            where    => $desc_node->location || 'configuration root',
            element  => $element,
        );
    }
    else {
        $view_scanner->scan_node( \@ret, $desc_node );
    }

    my @header = qw/name type value/;
    my $name_length  = max map { length($_->[0]) } (@ret, \@header );
    my $type_length  = max map { length($_->[1]) } (@ret, \@header );
    my $value_length = max map { length($_->[2]) } (@ret, \@header );
    my $sep_length = $name_length + $type_length + $value_length + 4 ;
    my @format = ("%-${name_length}s", "%-${type_length}s", "%-${value_length}s") ;

    my @show ;
    if ($verbose) {
        push @format, "%-35s";
        @show = (
            sprintf( join(" │ ", @format)."\n", qw/name type value comment/) ,
            sprintf( join("─┼─", @format)."\n", '─' x $name_length,'─' x $type_length,'─' x $value_length,'─' x 20, ) ,
            map { sprintf( join(" │ ", @format)."\n", @$_ ) } @ret
        );
    }
    else {
        @show = (
            sprintf( join(" │ ", @format)."\n", qw/name type value/) ,
            sprintf( join("─┼─", @format)."\n", '─' x $name_length,'─' x $type_length,'─' x $value_length ) ,
            map { sprintf( join(" │ ", @format)."\n", @$_[0,1,2] ) } @ret
        );
    }

    return join ('', @show );
}

1;

# ABSTRACT: Provide a description of a node element

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
    ]
 );
 $model ->create_config_class (
    name => "MyClass",

    element => [

        [qw/foo bar/] => {
            type       => 'leaf',
            value_type => 'string'
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
 ) ;

 my $inst = $model->instance(root_class_name => 'MyClass' );

 my $root = $inst->config_root ;

 # put data
 my $steps = 'foo=FOO hash_of_nodes:fr foo=bonjour -
   hash_of_nodes:en foo=hello ';
 $root->load( steps => $steps );

 print $root->describe ;

 ### prints
 # name          type       value          comment
 # foo           string     FOO
 # bar           string     [undef]
 # hash_of_nodes node hash  <Foo>          keys: "en" "fr"

=head1 DESCRIPTION

This module is used directly by L<Config::Model::Node> to describe
a node element. This module returns a human readable string that
shows the content of a configuration node.

For instance (as shown by C<fstab> example:

 name         type         value        comment
 fs_spec      string       [undef]      mandatory
 fs_vfstype   enum         [undef]      choice: auto davfs ext2 ext3 swap proc iso9660 vfat ignore, mandatory
 fs_file      string       [undef]      mandatory
 fs_freq      boolean      0
 fs_passno    integer      0

This module is also used by the C<ll> command of L<Config::Model::TermUI>.

=head1 CONSTRUCTOR

=head2 new ( )

No parameter. The constructor should be used only by
L<Config::Model::Node>.

=head1 Methods

=head2 describe

Return a description string.

Parameters are:

=over

=item node

Reference to a L<Config::Model::Node> object. Mandatory

=item element

Describe only this element from the node. Optional. All elements are
described if omitted.

=item pattern

Describe the element matching the regexp ref. Example:

 describe => ( pattern => qr/^foo/ )

=item hide_empty

Boolean. Whether to hide empty value (i.e. C<undef> or C<''>) or not. Default is false.

=item verbose

Boolean. Display more information with each element. Default is false.

=back

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>,L<Config::Model::Node>,L<Config::Model::ObjTreeScanner>

=cut
