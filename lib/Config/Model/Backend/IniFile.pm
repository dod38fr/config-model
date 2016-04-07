package Config::Model::Backend::IniFile;

use Carp;
use Mouse;
use 5.10.0;
use Config::Model::Exception;
use File::Path;
use Log::Log4perl qw(get_logger :levels);

use base qw/Config::Model::Backend::Any/;

my $logger = get_logger("Backend::IniFile");

sub suffix { return '.ini'; }

sub annotation { return 1; }

sub read {
    my $self = shift;
    my %args = @_;

    # args is:
    # object     => $obj,         # Config::Model::Node object
    # root       => './my_test',  # fake root directory, userd for tests
    # config_dir => /etc/foo',    # absolute path
    # file       => 'foo.conf',   # file name
    # file_path  => './my_test/etc/foo/foo.conf'
    # io_handle  => $io           # IO::File object
    # check      => yes|no|skip

    return 0 unless defined $args{io_handle};    # no file to read

    my $section = '<top>';                       # dumb value used for logging

    my $delimiter   = $args{comment_delimiter}   || '#';
    my $hash_class  = $args{store_class_in_hash} || '';
    my $section_map = $args{section_map}         || {};
    my $split_reg   = $args{split_list_value};
    my $check       = $args{check}               || 'yes';
    my $obj         = $self->node;

    my %force_lc;
    map { $force_lc{$_} = $args{"force_lc_$_"} ? 1 : 0; } qw/section key value/;

    #FIXME: Is it possible to store the comments with their location
    #in the file?  It would be nice if comments that are after values
    #in input file, would be written in the same way in the output
    #file.  Also, comments at the end of file are being ignored now.

    my @lines = $args{io_handle}->getlines;

    # try to get global comments (comments before a blank line)
    $self->read_global_comments( \@lines, $delimiter );

    my @assoc = $self->associates_comments_with_data( \@lines, $delimiter );

    # store INI data in a structure:
    # {
    #   name => value         leaf
    #   name => [  value ]     list
    #   name => { key =>  value , ... }    hash
    #   name => { ... }                   node
    #   name => [ { ... }, ... ]        list of nodes
    #   name => { key =>   { ... } , ... }        hash of nodes
    # }

    my $ini_data = {};
    my %ini_comment;
    my $section_ref  = $ini_data;
    my $section_path = '';

    foreach my $item (@assoc) {
        my ( $vdata, $comment ) = @$item;
        $logger->debug("ini read: reading '$vdata'");
        my $comment_path;

        # Update section name
        if ( $vdata =~ /^\s*\[(.*)\]/ ) {
            $section = $force_lc{section} ? lc($1) : $1;
            my $remap = $section_map->{$section} || '';
            if ( $remap eq '!' ) {
                $section_ref = $ini_data;
                $comment_path = $section_path = '';
                $logger->debug("step 1: found node <top> [$section]");
            }
            elsif ($remap) {
                $section_ref = {};
                $logger->debug("step 1: found node $remap [$section]");
                $section_path = $comment_path =
                    $self->set_or_push( $ini_data, $remap, $section_ref );
            }
            elsif ($hash_class) {
                $ini_data->{$hash_class}{$section} = $section_ref = {};
                $comment_path = $section_path = "$hash_class:$section";
                $logger->debug("step 1: found node $hash_class and path $comment_path [$section]");
            }
            else {
                $section_ref = {};
                $logger->debug("step 1: found node $section [$section]");
                $section_path = $comment_path =
                    $self->set_or_push( $ini_data, $section, $section_ref );
            }

            # for write later, need to store the obj if section map was used
            if ( defined $section_map->{$section} ) {
                $logger->debug("store section_map loc '$section_path' section '$section'");
                $self->{reverse_section_map}{$section_path} = $section;
            }
        }
        else {
            my ( $name, $val ) = split( /\s*=\s*/, $vdata, 2 );
            $name = lc($name) if $force_lc{key};
            $val  = lc($val)  if $force_lc{value};
            $comment_path = $section_path . ' ' . $self->set_or_push( $section_ref, $name, $val );
            $logger->debug("step 1: found node $comment_path name $name in [$section]");
        }

        $ini_comment{$comment_path} = $comment if $comment;
    }

    my @load_args = ( data => $ini_data, check => $check );
    push @load_args, split_reg => qr/$split_reg/ if $split_reg;
    $self->load_data(@load_args);

    while ( my ( $k, $v ) = each %ini_comment ) {
        my $item = $obj->grab( step => $k, mode => 'loose' ) or next;
        $item = $item->fetch_with_id(0) if $item->get_type eq 'list';
        $item->annotation($v);
    }

    return 1;
}

sub load_data {
    my $self = shift;
    say "calling load_data on ". ref($self);
    $self->node->load_data(@_);
}

sub set_or_push {
    my ( $self, $ref, $name, $val ) = @_;
    my $cell = $ref->{$name};
    my $path;
    if ( defined $cell and ref($cell) eq 'ARRAY' ) {
        push @$cell, $val;
        $path = $name . ':' . $#$cell;
    }
    elsif ( defined $cell ) {
        $ref->{$name} = [ $cell, $val ];
        $path = $name . ':1';
    }
    else {
        $ref->{$name} = $val;
        $path = $name;    # no way to distinguish between leaf and first value of list
    }
    return $path;
}

sub write {
    my $self = shift;
    my %args = @_;

    # args is:
    # object     => $obj,         # Config::Model::Node object
    # root       => './my_test',  # fake root directory, userd for tests
    # config_dir => /etc/foo',    # absolute path
    # file       => 'foo.conf',   # file name
    # file_path  => './my_test/etc/foo/foo.conf'
    # io_handle  => $io           # IO::File object
    # check      => yes|no|skip

    my $ioh       = $args{io_handle};
    my $node      = $args{object};
    my $delimiter = $args{comment_delimiter} || '#';

    croak "Undefined file handle to write" unless defined $ioh;

    $self->write_global_comment( $ioh, $delimiter );

    # some INI file have a 'General' section mapped in root node
    my $top_class_name = $self->{reverse_section_map}{''};
    if ( defined $top_class_name ) {
        $logger->debug("writing class $top_class_name from reverse_section_map");
        $self->write_data_and_comments( $ioh, $delimiter, "[$top_class_name]" );
    }

    my $res = $self->_write(@_);
    $ioh->print($res);
}

sub _write_list{
    my ($self, $args, $node, $elt)  = @_ ;
    my $res = '';

    my $join_list = $args->{join_list_value};
    my $delimiter = $args->{comment_delimiter} || '#';
    my $obj = $node->fetch_element($elt);

    my $obj_note = $obj->annotation;

    if ( $join_list ) {
        my @v = grep { length } $obj->fetch_all_values();
        my $v = join( $join_list, @v );
        if ( length($v) ) {
            $logger->debug("writing joined list elt $elt -> $v");
            $res .= $self->write_data_and_comments( undef, $delimiter, "$elt=$v", $obj_note );
        }
    }
    else {
        foreach my $item ( $obj->fetch_all('custom') ) {
            my $note = $item->annotation;
            my $v    = $item->fetch;
            if ( length $v ) {
                $logger->debug("writing list elt $elt -> $v");
                $res .=
                    $self->write_data_and_comments( undef, $delimiter, "$elt=$v",
                                                    $obj_note . $note );
            }
            else {
                $logger->debug("NOT writing undef or empty list elt");
            }
        }
    }
    return $res;
}

sub _write_check_list{
    my ($self, $args, $node, $elt)  = @_ ;
    my $res = '';

    my $join_check_list = $args->{join_check_list_value};
    my $delimiter = $args->{comment_delimiter} || '#';
    my $obj = $node->fetch_element($elt);

    my $obj_note = $obj->annotation;

    if ($join_check_list ) {
        my $v = join( $join_check_list, $obj->get_checked_list() );
        if ( length($v) ) {
            $logger->debug("writing check_list elt $elt -> $v");
            $res .= $self->write_data_and_comments( undef, $delimiter, "$elt=$v", $obj_note );
        }
    }
    else {
        foreach my $v ( $obj->get_checked_list() ) {
            $logger->debug("writing joined check_list elt $elt -> $v");
            $res .= $self->write_data_and_comments( undef, $delimiter, "$elt=$v", $obj_note );
        }
    }
    return $res;
}

sub _write_leaf{
    my ($self, $args, $node, $elt)  = @_ ;
    my $res = '';

    my $write_bool_as = $args->{write_boolean_as};
    my $delimiter = $args->{comment_delimiter} || '#';
    my $obj = $node->fetch_element($elt);

    my $obj_note = $obj->annotation;

    my $v = $obj->fetch;
    if ( $write_bool_as and defined($v) and length($v) and $obj->value_type eq 'boolean' ) {
        $v = $write_bool_as->[$v];
    }
    if ( defined $v and length $v ) {
        $logger->debug("writing leaf elt $elt -> $v");
        $res .= $self->write_data_and_comments( undef, $delimiter, "$elt=$v", $obj_note );
    }
    else {
        $logger->debug("NOT writing undef or empty leaf elt");
    }
    return $res;
}

sub _write_hash {
    my ($self, $args, $node, $elt)  = @_ ;
    my $res = '';

    my $delimiter = $args->{comment_delimiter} || '#';
    my $obj = $node->fetch_element($elt);
    my $obj_note = $obj->annotation;

    foreach my $key ( $obj->fetch_all_indexes ) {
        my $hash_obj = $obj->fetch_with_id($key);
        my $note     = $hash_obj->annotation;
        $logger->debug("writing hash elt $elt key $key");
        my $subres = $self->_write( %$args, object => $hash_obj );
        if ($subres) {
            $res .= "\n"
                . $self->write_data_and_comments( undef, $delimiter, "[$key]",
                                                  $obj_note . $note )
                . $subres;
        }
    }
    return $res;
}

sub _write_node {
    my ($self, $args, $node, $elt)  = @_ ;
    my $res = '';

    my $delimiter = $args->{comment_delimiter} || '#';
    my $obj = $node->fetch_element($elt);
    my $obj_note = $obj->annotation;

    $logger->debug("writing class $elt");
    my $subres = $self->_write( %$args, object => $obj );
    if ($subres) {

        # some INI file may have a section mapped to a node as exception to mapped in a hash
        my $exception_name = $self->{reverse_section_map}{ $obj->location };
        if ( defined $exception_name ) {
            $logger->debug("writing class $exception_name from reverse_section_map");
        }
        my $c_name = $exception_name || $elt;
        $res .= "\n"
            . $self->write_data_and_comments( undef, $delimiter, "[$c_name]", $obj_note )
            . $subres;
    }
    return $res;
}

sub _write {
    my $self = shift;
    my %args = @_;

    my $node          = $args{object};
    my $delimiter     = $args{comment_delimiter} || '#';

    $logger->debug( "called on ", $node->name );
    my $res = '';

    # Using Config::Model::ObjTreeScanner would be overkill
    # first write list and element, then classes
    foreach my $elt ( $node->get_element_name ) {
        my $type = $node->element_type($elt);
        $logger->debug("first loop on elt $elt type $type");
        next if $type =~ /node/ or $type eq 'hash';

        if ( $type eq 'list' ) {
            $res .= $self->_write_list (\%args, $node, $elt) ;
        }
        elsif ( $type eq 'check_list') {
            $res .= $self->_write_check_list (\%args, $node, $elt) ;
        }
        elsif ( $type eq 'leaf' ) {
            $res .= $self->_write_leaf (\%args, $node, $elt) ;
        }
        else {
            Config::Model::Exception::Model->throw(
                error  => "unexpected type $type for leaf elt $elt",
                object => $node
            );
        }
    }

    foreach my $elt ( $node->get_element_name ) {
        my $type = $node->element_type($elt);
        $logger->debug("second loop on elt $elt type $type");
        next unless $type =~ /node/ or $type eq 'hash';
        my $obj = $node->fetch_element($elt);

        my $obj_note = $obj->annotation;

        if ( $type eq 'hash' ) {
            $res .= $self->_write_hash (\%args, $node, $elt) ;
        }
        else {
            $res .= $self->_write_node (\%args, $node, $elt) ;
        }
    }

    $logger->debug( "done on ", $node->name );

    return $res;
}

no Mouse;
__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Read and write config as a INI file

__END__

=head1 SYNOPSIS

 use Config::Model;

 my $model = Config::Model->new;
 $model->create_config_class (
    name    => "IniClass",
    element => [ 
        [qw/foo bar/] => {
            type => 'list',
            cargo => {qw/type leaf value_type string/}
        } 
    ]
 );

 # model for free INI class name and constrained class parameters
 $model->create_config_class(
    name => "MyClass",

    element => [
        'ini_class' => {
            type   => 'hash',
	    index_type => 'string',
	    cargo => { 
		type => 'node',
		config_class_name => 'IniClass' 
		},
	    },
    ],

   read_config  => [
        { 
            backend => 'IniFile',
            config_dir => '/tmp',
            file  => 'foo.conf',
            store_class_in_hash => 'ini_class',
            auto_create => 1,
        }
    ],
 );

 my $inst = $model->instance(root_class_name => 'MyClass' );
 my $root = $inst->config_root ;

 $root->load('ini_class:ONE foo=FOO1 bar=BAR1 - 
              ini_class:TWO foo=FOO2' );

 $inst->write_back ;

Now C</tmp/foo.conf> will contain:

 ## file written by Config::Model
 [ONE]
 foo=FOO1

 bar=BAR1

 [TWO]
 foo=FOO2

=head1 DESCRIPTION

This module is used directly by L<Config::Model> to read or write the
content of a configuration tree written with INI syntax in
C<Config::Model> configuration tree.

This INI file can have arbitrary comment delimiter. See the example 
in the SYNOPSIS that sets a semi-column as comment delimiter. 
By default the comment delimiter is '#' like in Shell or Perl.

Note that undefined values are skipped for list element. I.e. if a
list element contains C<('a',undef,'b')>, the data structure will
contain C<'a','b'>.

=head1 Comments

This backend tries to read and write comments from configuration file. The
comments are stored as annotation within the configuration tree. Bear in mind
that comments extraction is based on best estimation as to which parameter the 
comment may apply. Wrong estimations are possible.

=head1 CONSTRUCTOR

=head2 new ( node => $node_obj, name => 'inifile' ) ;

Inherited from L<Config::Model::Backend::Any>. The constructor will be
called by L<Config::Model::BackendMgr>.

=head1 Parameters

Optional parameters declared in the model:

=over

=item comment_delimiter

Change the character that starts comments in the INI file. Default is 'C<#>'.

=item store_class_in_hash

See L</"Arbitrary class name">

=item section_map

Is a kind of exception of the above rule. See also L</"Arbitrary class name">

=item force_lc_section

Boolean. When set, sections names are converted to lowercase.

=item force_lc_key

Idem for key name 

=item force_lc_value

Idem for all values.

=item split_list_value

Some INI values are in fact a list of items separated by a space or a comma.
This parameter specifies the regex  to use to split the value into a list. This
applies only to C<list> elements.

=item join_list_value

Conversely, the list element split with C<split_list_value> needs to be written
back with a string to join them. Specify this string (usually ' ' or ', ')
with C<join_list_value>.

=item split_check_list_value

Some INI values are in fact a check list of items separated by a space or a comma.
This parameter specifies the regex to use to split the value read from the file
into a list of items to check. This applies only to C<check_list> elements.

=item join_check_list_value

Conversely, the check_list element split with C<split_list_value> needs to be written
back with a string to join them. Specify this string (usually ' ' or ', ')
with C<join_check_list_value>.

=item write_boolean_as

Array ref. Reserved for boolean value. Specify how to write a boolean value. 
Default is C<[0,1]> which may not be the most readable. C<write_boolean_as> can be 
specified as C<['false','true']> or C<['no','yes']>. 

=back

=head1 Mapping between INI structure and model

INI file typically have the same structure with 2 different conventions. 
The class names can be imposed by the application or may be chosen by user.

=head2 Imposed class name

In this case, the class names must match what is expected by the application. 
The elements of each class can be different. For instance:

  foo = foo_v
  [ A ]
  bar = bar_v
  [ B ]
  baz = baz_v

In this case, class C<A> and class C<B> will not use the same configuration class.

The model will have this structure:
   
 Root class 
 |- leaf element foo
 |- node element A of class_A
 |  \- leaf element bar
 \- node element B of class_B
    \-  leaf element baz
    
=head2 Arbitrary class name

In this case, the class names can be chosen by the end user. Each class will have the same 
elements. For instance:

  foo = foo_v
  [ A ]
  bar = bar_v1
  [ B ]
  bar = bar_v2

In this case, class C<A> and class C<B> will not use the same configuration class.
The model will have this structure:
   
 Root class 
 |- leaf foo
 \- hash element my_class_holder
    |- key A (value is node of class_A)
    |  \- element-bar
    \- key B (value is node of class_A)
       \- element-bar

In this case, the C<my_class_holder> name is specified in C<read_config> with C<store_class_in_hash> 
parameter:

    read_config  => [
        { 
            backend => 'IniFile',
            config_dir => '/tmp',
            file  => 'foo.ini',
            store_class_in_hash => 'my_class_holder',
        }
    ],
    
Of course they are exceptions. For instance, in C<Multistrap>, the C<[General]> 
INI class must be mapped to a specific node object. This can be specified
with the C<section_map> parameter: 

    read_config  => [
        { 
            backend => 'IniFile',
            config_dir => '/tmp',
            file  => 'foo.ini',
            store_class_in_hash => 'my_class_holder',
            section_map => { 
                General => 'general_node',
            }
        }
    ],

C<section_map> can also map an INI class to the root node:

    read_config => [
        {
            backend => 'ini_file',
            store_class_in_hash => 'sections',
            section_map => {
                General => '!'
            },
        }
    ],


=head1 Methods

=head2 read ( io_handle => ... )

Of all parameters passed to this read call-back, only C<io_handle> is
used. This parameter must be L<IO::File> object already opened for
read. 

It can also be undef. In this case, C<read()> will return 0.

When a file is read,  C<read()> will return 1.

=head2 write ( io_handle => ... )

Of all parameters passed to this write call-back, only C<io_handle> is
used. This parameter must be L<IO::File> object already opened for
write. 

C<write()> will return 1.

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org); 
Krzysztof Tyszecki, (krzysztof.tyszecki at gmail dot com)

=head1 SEE ALSO

L<Config::Model>, 
L<Config::Model::BackendMgr>, 
L<Config::Model::Backend::Any>, 

=cut
