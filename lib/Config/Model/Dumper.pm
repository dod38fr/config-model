package Config::Model::Dumper;

use Carp;
use strict;
use warnings;

use Config::Model::Exception;
use Config::Model::ObjTreeScanner;

sub new {
    bless {}, shift;
}

sub quote {
    _quote( qr/[\s"#*]/, @_ );
}

sub id_quote {
    _quote( qr/[\s"@*<>.=#]/, @_ );
}

sub _quote {
    my ( $re, @res ) = @_;
    foreach (@res) {
        if ( defined $_ and ( /$re/ or $_ eq '' ) ) {
            s/"/\\"/g;    # escape present quotes
            $_ = '"' . $_ . '"';    # add my quotes
        }
    }
    return wantarray ? @res : $res[0];
}

sub note_quote {
    my @res = @_;
    foreach (@res) {
        if ( defined $_ and $_ and (/(\s|"|\*)/) ) {
            s/"/\\"/g;              # escape present quotes
            $_ = '"' . $_ . '"';    # add my quotes
        }
    }
    return wantarray ? @res : $res[0];
}

sub dump_tree {
    my $self = shift;

    my %args    = @_;
    my $full    = delete $args{full_dump} || 0;
    my $skip_aw = delete $args{skip_auto_write} || '';
    my $auto_v  = delete $args{auto_vivify} || 0;
    my $mode    = delete $args{mode} || '';

    if ( $mode and $mode !~ /full|preset|custom|non_upstream_default/ ) {
        croak "dump_tree: unexpected 'mode' value: $mode";
    }

    my $check = delete $args{check} || 'yes';
    if ( $check !~ /yes|no|skip/ ) {
        croak "dump_tree: unexpected 'check' value: $check";
    }

    # mode parameter is slightly different from fetch's mode
    my $fetch_mode =
          $full           ? ''
        : $mode eq 'full' ? ''
        : $mode           ? $mode
        :                   'custom';

    my $node = delete $args{node}
        || croak "dump_tree: missing 'node' parameter";

    my $compute_pad = sub {
        my $depth = 0;
        my $obj   = shift;
        while ( defined $obj->parent ) {
            $depth++;
            $obj = $obj->parent;
        }
        return '  ' x $depth;
    };

    my $leaf_cb = sub {
        my ( $scanner, $data_r, $node, $element, $index, $value_obj ) = @_;

        # get value or only customized value
        my $value = quote( $value_obj->fetch( mode => $fetch_mode, check => $check ) );
        $index = id_quote($index);

        my $pad = $compute_pad->($node);

        my $name =
            defined $index
            ? "$element:$index"
            : $element;

        # add annotation for obj contained in hash or list
        my $note = note_quote( $value_obj->annotation );
        $$data_r .= "\n" . $pad . $name if defined $value or $note;
        if (defined $value) {
            $value =~ s/\\n/\\\\n/g;
            $$data_r .= '=' . $value;
        }
        $$data_r .= '#' . $note         if $note;
    };

    my $check_list_cb = sub {
        my ( $scanner, $data_r, $node, $element, $index, $value_obj ) = @_;

        # get value or only customized value
        my $value = $value_obj->fetch( mode => $fetch_mode, check => $check );
        my $qvalue = quote($value);
        $index = id_quote($index);
        my $pad = $compute_pad->($node);

        my $name =
            defined $index
            ? "$element:$index"
            : $element;

        # add annotation for obj contained in hash or list
        my $note = note_quote( $value_obj->annotation );
        $$data_r .= "\n" . $pad . $name if $value or $note;
        $$data_r .= '=' . $qvalue       if $value;
        $$data_r .= '#' . $note         if $note;
    };

    my $list_element_cb = sub {
        my ( $scanner, $data_r, $node, $element, @keys ) = @_;

        my $pad      = $compute_pad->($node);
        my $list_obj = $node->fetch_element($element);

        # add annotation for list element
        my $list_note = note_quote( $list_obj->annotation );
        $$data_r .= "\n$pad$element#$list_note" if $list_note;

        if ( $list_obj->cargo_type eq 'node' ) {
            foreach my $k (@keys) {
                $scanner->scan_list( $data_r, $node, $element, $k );
            }
        }
        else {
            # write value comments
            foreach my $idx ( $list_obj->fetch_all_indexes ) {
                my $note = $list_obj->fetch_with_id($idx)->annotation;
                $$data_r .= "\n$pad$element:$idx#" . note_quote($note) if $note;
            }

            # skip undef values
            my @val = id_quote(
                grep ( defined $_,
                    $list_obj->fetch_all_values(
                        mode  => $fetch_mode,
                        check => $check
                    ) ) );
            $$data_r .= "\n$pad$element:=" . join( ',', @val ) if @val;
        }
    };

    my $hash_element_cb = sub {
        my ( $scanner, $data_r, $node, $element, @keys ) = @_;

        my $pad      = $compute_pad->($node);
        my $hash_obj = $node->fetch_element($element);

        # add annotation for list or hash element
        my $note = note_quote( $hash_obj->annotation );
        $$data_r .= "\n$pad$element#$note" if $note;

        # resume exploration
        map { $scanner->scan_hash( $data_r, $node, $element, $_ ); } @keys;
    };

    # called for nodes contained in nodes (not root).
    # This node can be held by a plain element or a hash element or a list element
    my $node_element_cb = sub {
        my ( $scanner, $data_r, $node, $element, $key, $contained_node ) = @_;

        my $type = $node->element_type($element);

        return if $skip_aw and $contained_node->is_auto_write_for_type($skip_aw);

        my $pad = $compute_pad->($node);
        my $elt = $node->fetch_element($element);

        # load string can feature only one comment per element_type
        # ie foo#comment foo:bar#comment foo:bar=val#comment are fine
        # but foo#comment:bar if not valid -> foo#commaent foo:bar

        my $head      = "\n$pad$element";
        my $node_note = note_quote( $contained_node->annotation );

        if ( $type eq 'list' or $type eq 'hash' ) {
            $head .= ':' . id_quote($key);
            $head .= '#' . $node_note if $node_note;
            my $sub_data = '';
            $scanner->scan_node( \$sub_data, $contained_node );
            $$data_r .= $head . $sub_data . ' -';
        }
        else {
            $head .= '#' . $node_note if $node_note;
            my $sub_data = '';
            $scanner->scan_node( \$sub_data, $contained_node );

            # skip simple nodes that do not bring data
            $$data_r .= $head . $sub_data . ' -' if $sub_data;
        }
    };

    my @scan_args = (
        fallback => 'all',
        auto_vivify           => $auto_v,
        list_element_cb       => $list_element_cb,
        hash_element_cb       => $hash_element_cb,
        leaf_cb               => $leaf_cb,
        node_element_cb       => $node_element_cb,
        check_list_element_cb => $check_list_cb,
        check                 => $check,
    );

    my @left = keys %args;
    croak "Dumper: unknown parameter:@left" if @left;

    # perform the scan
    my $view_scanner = Config::Model::ObjTreeScanner->new(@scan_args);

    my $ret       = '';
    my $root_note = note_quote( $node->annotation );
    $ret .= "\n#$root_note" if $root_note;
    $view_scanner->scan_node( \$ret, $node );

    substr( $ret, 0, 1, '' );    # remove leading \n
    $ret .= ' -' if $ret;
    return $ret . "\n";
}

1;

# ABSTRACT: Serialize data of config tree

__END__

=head1 SYNOPSIS

 use Config::Model ;

 # define configuration tree object
 my $model = Config::Model->new ;
 $model ->create_config_class (
    name => "MyClass",
    element => [
        [qw/foo bar/] => {
            type => 'leaf',
            value_type => 'string'
        },
        baz => {
            type => 'hash',
            index_type => 'string' ,
            cargo => {
                type => 'leaf',
                value_type => 'string',
            },
        },

    ],
 ) ;

 my $inst = $model->instance(root_class_name => 'MyClass' );

 my $root = $inst->config_root ;

 # put some data in config tree the hard way
 $root->fetch_element('foo')->store('yada') ;
 $root->fetch_element('bar')->store('bla bla') ;
 $root->fetch_element('baz')->fetch_with_id('en')->store('hello') ;

 # put more data the easy way
 my $steps = 'baz:fr=bonjour baz:hr="dobar dan"';
 $root->load( steps => $steps ) ;

 # dump only customized data
 print $root->dump_tree;


=head1 DESCRIPTION

This module is used directly by L<Config::Model::Node> to serialize
configuration data in a compact (but readable) string.

The serialization can be done in standard mode where only customized
values are dumped in the string. I.e. only data modified by the user
are dumped.

The other mode is C<full_dump> mode where all all data, including
default values, are dumped.

The serialized string can be used by L<Config::Model::Loader> to store
the data back into a configuration tree.

Note that undefined values are skipped for list element. I.e. if a list
element contains C<('a',undef,'b')>, the dump then contains C<'a','b'>.

=head1 CONSTRUCTOR

=head2 new

No parameter. The constructor should be used only by
L<Config::Model::Node>.

=head1 Methods

=head2 dump_tree

Return a string that contains a dump of the object tree with all the
values. This string follows the convention defined by
L<Config::Model::Loader>.

The serialized string can be used by L<Config::Model::Loader> to store
the data back into a configuration tree.

Parameters are:

=over

=item mode ( full | preset | custom | non_upstream_default )

C<full> dumps all configuration data including default
values.

C<preset> dumps only value entered in preset mode.

By default, the dump contains only data modified by the user
(i.e. C<custom> data that differ from default or preset values).

=item node

Reference to the L<Config::Model::Node> object that is dumped. All
nodes and leaves attached to this node are also dumped.

=item skip_auto_write ( <backend_name> )

Skip node that have a write capability matching C<backend_name> in
their model. See L<Config::Model::BackendMgr>.

This option must be used when using Dumper to write back configuration
data. When a configuration model contains several backends (one at the
tree root and others in tree nodes), setting this option ensure that
the "root" configuration file does not contain data duplicated in
configuration file of others tree nodes.

=item auto_vivify

Scan and create data for nodes elements even if no actual data was
stored in them. This may be useful to trap missing mandatory values.
(default: 0)

=item check

Check value before dumping. Valid check are 'yes', 'no' and 'skip'.

=back

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>,L<Config::Model::Node>,L<Config::Model::Loader>

=cut
