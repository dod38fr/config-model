package Config::Model::DumpAsYaml;

use Carp;
use strict;
use warnings;
use boolean;
use v5.20;

use YAML::PP 0.024;
use YAML::PP::Common qw/YAML_LITERAL_SCALAR_STYLE
                        YAML_FLOW_MAPPING_STYLE
                        YAML_FLOW_SEQUENCE_STYLE
                        PRESERVE_FLOW_STYLE
                        PRESERVE_ORDER
                        PRESERVE_SCALAR_STYLE/;

use Config::Model::Exception;
use Config::Model::ObjTreeScanner;

use feature qw/postderef signatures/;
no warnings qw/experimental::postderef experimental::signatures/;


sub new {
    bless {}, shift;
}

sub to_boolean ($v) {
    # do not change boolean written as yes/no or literal true/false
    return $v =~ /^[01]$/ ? boolean($v) : $v ;
}

sub dump_as_yaml {
    my $self = shift;

    my %args      = @_;
    my $dump_node = delete $args{node}
        || croak "dump_as_yaml: missing 'node' parameter";
    my $mode = delete $args{mode} // '';

    my $yp = YAML::PP->new(
        preserve => PRESERVE_ORDER | PRESERVE_SCALAR_STYLE,
        boolean => 'boolean',
    );

    my $fetch_mode = $mode // 'custom';

    my $std_cb = sub {
        my ( $scanner, $data_r, $obj, $element, $index, $value_obj ) = @_;
        my $v = $value_obj->fetch(mode => $fetch_mode);
        my $vt = $value_obj->value_type;

        if (not defined $v) {
            return;
        }

        if ($vt eq 'string' and $v =~ /\n/) {
            $$data_r = $yp->preserved_scalar($v, style => YAML_LITERAL_SCALAR_STYLE );
        }
        elsif ($vt eq 'integer' or $vt eq 'number') {
            $data_r->$* = $v + 0; # force number
        }
        elsif ($vt eq 'boolean') {
            # transform boolean type in boolean object
            $$data_r = to_boolean($v);
        }
        else {
            $$data_r = $v;
        }
    };

    my $check_list_element_cb = sub {
        my ( $scanner, $data_r, $node, $element_name, @check_items ) = @_;
        my $a_ref = $node->fetch_element($element_name)->get_checked_list;

        # don't store empty checklist
        $$data_r = $a_ref if @$a_ref;
    };

    my $hash_element_cb = sub {
        my ( $scanner, $data_ref, $node, $element_name, @keys ) = @_;

        my $force_write = $node->fetch_element($element_name)->write_empty_value;

        # resume exploration but pass a ref on $data_ref hash element
        # instead of data_ref
        my %h;
        my @res;
        foreach my $k (@keys) {
            my $v;
            $scanner->scan_hash( \$v, $node, $element_name, $k );

            # don't create the key if $v is undef
            if (defined $v or $force_write) {
                $h{$k} = $v;
                push @res , $k, $v;
            }
        } ;

        if (@res) {
            # use preserved mapping even for non-ordered hash, because
            # keys sorted. Using plain hash leads to random keys order
            # which is inconvenient for tests.
            $$data_ref = $yp->preserved_mapping({}, style => YAML_FLOW_MAPPING_STYLE);
            $data_ref->$*->%* = @res;
        }
    };

    my $list_element_cb = sub {
        my ( $scanner, $data_ref, $node, $element_name, @idx ) = @_;

        # resume exploration but pass a ref on $data_ref hash element
        # instead of data_ref
        my @a;
        foreach my $i (@idx) {
            my $v;
            $scanner->scan_hash( \$v, $node, $element_name, $i );
            push @a, $v if defined $v;
        }
        $$data_ref = \@a if scalar @a;
    };

    my $node_content_cb = sub {
        my ( $scanner, $data_ref, $node, @element ) = @_;
        my $h = $yp->preserved_mapping({}, style => YAML_FLOW_MAPPING_STYLE);

        foreach my $e (@element) {
            my $v;
            $scanner->scan_element( \$v, $node, $e );
            $h->{$e} = $v if defined $v;
        }
        $$data_ref = $h if scalar $h->%*;
    };

    my $node_element_cb = sub {
        my ( $scanner, $data_ref, $node, $element_name, $key, $next ) = @_;

        $scanner->scan_node( $data_ref, $next );
    };

    my @scan_args = (
        check      => delete $args{check}      || 'yes',
        fallback   => 'all',
        list_element_cb       => $list_element_cb,
        check_list_element_cb => $check_list_element_cb,
        hash_element_cb       => $hash_element_cb,
        leaf_cb               => $std_cb,
        node_element_cb       => $node_element_cb,
        node_content_cb       => $node_content_cb,
    );

    my @left = keys %args;
    croak "DumpAsYaml: unknown parameter:@left" if @left;

    # perform the scan
    my $view_scanner = Config::Model::ObjTreeScanner->new(@scan_args);

    my $obj_type = $dump_node->get_type;
    my $result = "---\n";
    my $p = $dump_node->parent;
    my $e = $dump_node->element_name;
    my $i = $dump_node->index_value;    # defined only for hash and list

    if ( $obj_type =~ /node/ ) {
        $view_scanner->scan_node( \$result, $dump_node );
    }
    elsif ( defined $i ) {
        $view_scanner->scan_hash( \$result, $p, $e, $i );
    }
    elsif ($obj_type eq 'list'
        or $obj_type eq 'hash'
        or $obj_type eq 'leaf'
        or $obj_type eq 'check_list' ) {
        $view_scanner->scan_element( \$result, $p, $e );
    }
    else {
        croak "dump_as_yaml: unexpected type: $obj_type";
    }

    return $yp->dump_string($result);
}

1;

# ABSTRACT: Dump configuration content as a yaml structure

__END__

=head1 SYNOPSIS

 use Config::Model ;

 # define configuration tree object
 my $model = Config::Model->new ;
 $model ->create_config_class (
    name => "MyClass",
    element => [
      foo => {
        type => 'leaf',
        value_type => 'string'
      },
      bar => '*foo',
      baz => {
        cargo => {
          type => 'leaf',
          value_type => 'string'
        },
        index_type => 'string',
        type => 'hash'
      }
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

 print $root->dump_as_yaml;
 # ---
 # foo: yada
 # bar: bla bla
 # baz:
 #   en: hello
 #   fr: bonjour
 #   hr: dobar dan

=head1 DESCRIPTION

This module is used directly by L<Config::Model::Node> to dump the content
of a configuration tree in YAML.

Note that
L<CheckList|Config::Model::CheckList> content is stored in a list.

Note that undefined values are skipped for list element. I.e. if a
list element contains C<('a',undef,'b')>, the YAML list then contains
C<'a','b'>.

=head1 CONSTRUCTOR

=head2 new

No parameter. The constructor should be used only by
L<Config::Model::Node>.

=head1 Methods

=head2 dump_as_yaml

Return a YAML string.

Parameters are:

=over

=item node

Reference to a L<Config::Model::Node> object. Mandatory

=item mode

Specify how to dump the configuration tree content, i.e. whether to
fetch default, custom, etc values. See L<Config::Model::Value/fetch> for
details on C<mode>.

=back

=head1 Methods

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>,L<Config::Model::Node>,L<Config::Model::ObjTreeScanner>, L<YAML::PP>

=cut
