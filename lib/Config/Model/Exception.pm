package Config::Model::Exception;

use warnings;
use strict;
use Data::Dumper;

use Exception::Class (
    'Config::Model::Exception::Syntax' => {
        isa         => 'Config::Model::Exception::Any',
        description => 'config error',
        fields      => [qw/object parsed_file parsed_line/],
        description => 'syntax error',
    },

    'Config::Model::Exception::Any' => {
        description => 'config error',
        fields      => [qw/object info/],
    },

    'Config::Model::Exception::User' => {
        isa         => 'Config::Model::Exception::Any',
        description => 'user error',
    },

    'Config::Model::Exception::LoadData' => {
        isa         => 'Config::Model::Exception::User',
        description => 'Load data structure (perl) error',
        fields      => [qw/wrong_data/],
    },

    'Config::Model::Exception::UnavailableElement' => {
        isa         => 'Config::Model::Exception::User',
        description => 'unavailable element',
        fields      => [qw/object element info function/],
    },

    'Config::Model::Exception::ObsoleteElement' => {
        isa         => 'Config::Model::Exception::User',
        description => 'Obsolete element',
        fields      => [qw/object element info/],
    },

    'Config::Model::Exception::WrongType' => {
        isa         => 'Config::Model::Exception::User',
        description => 'wrong element type',
        fields      => [qw/object function got_type expected_type info/],
    },

    'Config::Model::Exception::WrongValue' => {
        isa         => 'Config::Model::Exception::User',
        description => 'wrong value',
    },

    'Config::Model::Exception::Load' => {
        isa         => 'Config::Model::Exception::User',
        description => 'Load command error',
        fields      => [qw/object command/],
    },

    'Config::Model::Exception::UnknownElement' => {
        isa         => 'Config::Model::Exception::User',
        description => 'unknown element',
        fields      => [qw/object element function where info/],
    },

    'Config::Model::Exception::AncestorClass' => {
        isa         => 'Config::Model::Exception::User',
        description => 'unknown ancestor class',
    },

    'Config::Model::Exception::UnknownId' => {
        isa         => 'Config::Model::Exception::User',
        description => 'unknown identifier',
        fields      => [qw/object element id function where/],
    },

    'Config::Model::Exception::WarpError' => {
        isa         => 'Config::Model::Exception::User',
        description => 'warp error',
    },

    'Config::Model::Exception::Fatal' => {
        isa         => 'Config::Model::Exception::Any',
        description => 'fatal error',
    },

    'Config::Model::Exception::Model' => {
        isa         => 'Config::Model::Exception::Fatal',
        description => 'configuration model error',
    },

    'Config::Model::Exception::ModelDeclaration' => {
        isa         => 'Config::Model::Exception::Fatal',
        description => 'configuration model declaration error',
    },

    'Config::Model::Exception::ConfigFile' => {
        isa         => 'Config::Model::Exception::User',
        description => 'error in configuration file',
    },

    'Config::Model::Exception::ConfigFile::Missing' => {
        isa         => 'Config::Model::Exception::ConfigFile',
        description => 'missing configuration file',
        fields      => [qw/tried_files/]
    },

    'Config::Model::Exception::Xml' => {
        isa         => 'Config::Model::Exception::User',
        description => 'error in XML data',
    },

    'Config::Model::Exception::Formula' => {
        isa         => 'Config::Model::Exception::Model',
        description => 'error in computation formula of the ' . 'configuration model',
    },

    'Config::Model::Exception::Internal' => {
        isa         => 'Config::Model::Exception::Fatal',
        description => 'internal error',
    },

    'Config::Model::Exception::XmlTree' =>
        { description => 'error while parsing XML dump of a tree' },

);

Config::Model::Exception::Internal->Trace(1);

package Config::Model::Exception::Syntax;

sub full_message {
    my $self = shift;

    my $fn   = $self->parsed_file || '?';
    my $line = $self->parsed_line || '?';
    my $msg  = "File $fn line $line ";
    $msg .= "has a " . $self->description;
    $msg .= ":\n\t" . $self->message . "\n";

    return $msg;
}

package Config::Model::Exception::Any;

sub full_message {
    my $self = shift;

    my $obj      = $self->object;
    my $location = defined $obj ? $obj->name : '';
    my $msg      = "Configuration item ";
    $msg .= "'$location' "     if $location;
    $msg .= "has a " . $self->description;
    $msg .= ":\n\t" . $self->message . "\n";
    $msg .= $self->info . "\n" if defined $self->info;

    return $msg;
}

sub xpath_message {
    my $self = shift;

    my $location = defined $self->object ? $self->object->xpath : '';

    my $msg = "Configuration item ";
    $msg .= "'$location' " if $location;
    $msg .= "has a " . $self->description;
    $msg .= ":\n\t" . $self->message . "\n";

    return $msg;
}

package Config::Model::Exception::LoadData;

sub full_message {
    my $self = shift;

    my $obj      = $self->object;
    my $location = defined $obj ? $obj->name : '';
    my $msg      = "Configuration item ";
    $msg .= "'$location' "                             if $location;
    $msg .= "(class " . $obj->config_class_name . ") " if $obj->get_type eq 'node';
    $msg .= "has a " . $self->description;
    $msg .= ":\n\t" . $self->message . "\n";
    $msg .= Data::Dumper->Dump( [ $self->wrong_data ], ['wrong data'] );

    return $msg;
}

package Config::Model::Exception::Model;

sub full_message {
    my $self = shift;

    my $obj = $self->object;
    my $msg;
    if ( $obj->isa('Config::Model::Node') ) {
        $msg = "Node '" . $obj->name . "' of class " . $obj->config_class_name . ' ';
    }
    else {
        my $element = $obj->element_name;
        my $level   = $obj->parent->get_element_property(
            element  => $element,
            property => 'level'
        );
        $msg =
              "In config class '"
            . $obj->parent->config_class_name
            . "', element '$element' (level $level) ";
    }
    $msg .= "has a " . $self->description;
    $msg .= ":\n\t" . $self->message . "\n";

    return $msg;
}

package Config::Model::Exception::Load;

sub full_message {
    my $self = shift;

    my $location = defined $self->object ? $self->object->name : '';
    my $msg      = $self->description;
    my $cmd      = $self->command;
    my $cmd_str =
           ref($cmd)   ? join('',@$cmd)
        : $cmd         ? "'$cmd'"
        : defined $cmd ? '<empty>'
        :                '<undef>';
    $msg .= " in node '$location' ".ref($cmd) if $location;
    $msg .= ':';
    $msg .= "\n\tcommand: $cmd_str";
    $msg .= "\n\t" . $self->message . "\n";

    return $msg;
}

package Config::Model::Exception::UnavailableElement;

sub full_message {
    my $self = shift;

    my $obj      = $self->object;
    my $location = $obj->name;
    my $msg      = $self->description;
    my $element  = $self->element;
    my $function = $self->function;
    my $unavail  = $obj->fetch_element(
        name          => $element,
        check         => 'no',
        accept_hidden => 1
    );
    $msg .= " '$element' in node '$location'.\n";
    $msg .= "\tError occurred when calling $function.\n" if defined $function;
    $msg .= "\t" . $unavail->warp_error if $unavail->can('warp_error');

    $msg .= "\t" . $self->info . "\n" if defined $self->info;
    return $msg;
}

package Config::Model::Exception::ObsoleteElement;

sub full_message {
    my $self = shift;

    my $obj     = $self->object;
    my $element = $self->element;
    my $msg     = $self->description;

    my $location = $obj->name;
    my $help = $obj->get_help($element) || '';

    $msg .= " '$element' in node '$location'.\n";
    $msg .= "\t$help\n";
    $msg .= "\t" . $self->info . "\n" if defined $self->info;
    return $msg;
}

package Config::Model::Exception::UnknownElement;

use Carp;

sub full_message {
    my $self = shift;

    my $obj = $self->object;

    confess "Exception::UnknownElement: object is ", ref($obj), ". Expected a node"
        unless $obj->isa('Config::Model::Node')
        || $obj->isa('Config::Model::WarpedNode');

    my $class_name = $obj->config_class_name;

    # class_name is undef if the warped_node is warped out
    my @elements;
    @elements = $obj->get_element_name(
        class => $class_name,
    ) if defined $class_name;

    my $msg = '';
    $msg .= "In " . $self->where . ": "
        if defined $self->where;

    $msg .= "(function '" . $self->function . "') "
        if defined $self->function;

    $msg = "object '" . $obj->name . "' error: " unless $msg;

    $msg .= $self->description . " '" . $self->element . "'.";

    $msg .=
          " Either your file has an error or $class_name model is lagging behind. "
        . "In the latter case, please submit a bug report or fix the model. See cme man "
        . "page for details.\n";

    if (@elements) {
        $msg .= "\tExpected elements: '" . join( "','", @elements ) . "'\n";
    }
    else {
        $msg .= " (node is warped out)\n";
    }

    my @match_keys = $obj->can('accept_regexp') ? $obj->accept_regexp() : ();
    if (@match_keys) {
        $msg .= "\tor an acceptable parameter matching '" . join( "','", @match_keys ) . "'\n";
    }

    # inform about available elements after a change of warp master value
    if ( defined $obj->parent ) {
        my $parent       = $obj->parent;
        my $element_name = $obj->element_name;

        if ( $parent->element_type($element_name) eq 'warped_node' ) {
            $msg .= "\t"
                . $parent->fetch_element(
                name => $element_name,
                qw/master check no accept_hidden 1/
                )->warp_error;
        }
    }

    $msg .= "\t" . $self->info . "\n" if ( defined $self->info );

    return $msg;
}

package Config::Model::Exception::UnknownId;

sub full_message {
    my $self = shift;

    my $obj = $self->object;

    my $element = $self->element;
    my $id_str = "'" . join( "','", $obj->fetch_all_indexes() ) . "'";

    my $msg = '';
    $msg .= "In function " . $self->function . ": "
        if defined $self->function;

    $msg .= "In " . $self->where . ": "
        if defined $self->where;

    $msg .=
          $self->description . " '"
        . $self->id() . "'"
        . " for element '"
        . $obj->location
        . "'\n\texpected: $id_str\n";

    return $msg;
}

package Config::Model::Exception::WrongType;

sub full_message {
    my $self = shift;

    my $obj = $self->object;

    my $msg = '';
    $msg .= "In function " . $self->function . ": "
        if defined $self->function;

    $msg .=
          $self->description
        . " for element '"
        . $obj->location
        . "'\n\tgot type '"
        . $self->got_type
        . "', expected '"
        . $self->expected_type . "' "
        . $self->info . "\n";

    return $msg;
}

package Config::Model::Exception::ConfigFile::Missing;

sub full_message {
    my $self = shift;

    my $msg = "Error: cannot find configuration file " . join ' or ', @{ $self->tried_files };

    return $msg . "\n";
}

package Config::Model::Exception::Xml;

sub full_message {
    my $self = shift;

    my $obj = $self->object;
    my $msg = $self->message;

    $msg .= "\n\t" . join( "\n\t", map ( $_->xpath_message, $self->object->errors ) )
        if defined $self->object;

    return $msg . "\n";
}

1;

# ABSTRACT: Exception mechanism for configuration model

__END__

=head1 SYNOPSIS

 # internal

=head1 DESCRIPTION

You must read L<Exception::Class> before reading on.

This module creates all the exception class used by L<Config::Model>.

All exception class name begins with C<Config::Model::Exception::>

The exception classes are:

=over

=item C<Any>

Base class. It accepts an C<object> argument. The user must pass the
reference of the object where the exception occurred. The object name
will be used to generate the error message.

=back

  TODO: list all exception classes and hierarchy. 

=head1 How to get trace

By default, most of the exceptions will not print out the stack
trace. For debug purpose, you can force a stack trace.

For instance, if you want a stack trace for an "unknown element"
error, you must add this line in your script:

  Config::Model::Exception::UnknownElement->Trace(1) ;

If you're not sure which class to trace, add this line in your
script:

  Config::Model::Exception::Any->Trace(1) ;

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>, 
L<Config::Model::Instance>, 
L<Config::Model::Node>,
L<Config::Model::Value>
L<Exception::Class>

=cut
