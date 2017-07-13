package Config::Model::Exception;

use warnings;
use strict;
use Data::Dumper;
use Mouse;
use 5.10.1;
use Carp;

@Carp::CARP_NOT=qw/Config::Model::Exception Config::Model::Exception::Any/;

our $trace = 0;


use Carp qw/longmess shortmess croak/;

use overload
    '""' => \&full_msg_and_trace,
    'bool' => \&is_error;

has description => (
    is => 'ro',
    isa => 'Str',
    lazy_build => 1
);

sub _build_description {
    my $self = shift;
    return $self->_desc;
}

sub _desc { 'config error' }

has  object => ( is => 'rw', isa => 'Ref') ;
has  info => (is => 'rw', isa =>'Str', default => '');
has  message => (is => 'rw', isa =>'Str', default => '');
has  error => (is => 'rw', isa =>'Str', default => '');
has  trace => (is => 'rw', isa =>'Str', default => '');

# without this overload, a test like if ($@) invokes '""' overload
sub is_error { return ref ($_[0])}


sub Trace {
    $trace = shift;
}

sub error_or_msg {
    my $self = shift;
    return $self->error  || $self->message;
}

sub throw {
    my $class = shift;
    my $self = $class->new(@_);
    # when an exception is thrown, caught and rethrown, the first full
    # trace (provided by longmess) is clobbered by a second, shorter
    # trace (also provided by longmess). To avoid that, the first
    # trace must be  stored.
    $self->trace($trace ? longmess : '') ;
    die $self;
}

sub rethrow {
    my $self = shift;
    die $self;
}

sub full_msg_and_trace {
    my $self = shift;
    my $msg = $self->full_message;
    $msg .= $self->trace;
    return $msg;
}

sub as_string {
    goto &full_msg_and_trace;
}

sub full_message {
    my $self = shift;

    my $obj      = $self->object;
    my $location = defined $obj ? $obj->name : '';
    my $msg      = "Configuration item ";
    $msg .= "'$location' "     if $location;
    $msg .= "has a " . $self->description;
    $msg .= ":\n\t" . ($self->error || $self->message) . "\n";
    $msg .= $self->info . "\n" if $self->info;
    return $msg;
}

package Config::Model::Exception::Any;

use Mouse;
extends 'Config::Model::Exception';

package Config::Model::Exception::ModelDeclaration;

use Mouse;
extends 'Config::Model::Exception::Fatal';

sub _desc {'configuration model declaration error' }

package Config::Model::Exception::User ;

use Mouse;
extends 'Config::Model::Exception::Any';
sub _desc {'user error' }


## old classes below
package Config::Model::Exception::Syntax;

use Mouse;
extends 'Config::Model::Exception::Any';

sub _desc { 'syntax error' }

has [qw/parsed_file parsed_line/] => (is => 'rw', isa => 'Str');

sub full_message {
    my $self = shift;

    my $fn   = $self->parsed_file || '?';
    my $line = $self->parsed_line || '?';
    my $msg  = "File $fn line $line ";
    $msg .= "has a " . $self->description;
    $msg .= ":\n\t" . $self->error_or_msg . "\n";

    return $msg;
}

package Config::Model::Exception::LoadData;

use Mouse;
extends 'Config::Model::Exception::User';

sub _desc { 'Load data structure (perl) error' };

has wrong_data => (is => 'rw');

sub full_message {
    my $self = shift;

    my $obj      = $self->object;
    my $location = defined $obj ? $obj->name : '';
    my $msg      = "Configuration item ";
    $msg .= "'$location' "                             if $location;
    $msg .= "(class " . $obj->config_class_name . ") " if $obj->get_type eq 'node';
    $msg .= "has a " . $self->description;
    $msg .= ":\n\t" . $self->error_or_msg . "\n";
    $msg .= Data::Dumper->Dump( [ $self->wrong_data ], ['wrong data'] );

    return $msg;
}

package Config::Model::Exception::Model;

use Mouse;
extends 'Config::Model::Exception::Fatal';

sub _desc { 'configuration model error'}


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
    $msg .= ":\n\t" . $self->error_or_msg . "\n";

    return $msg;
}

package Config::Model::Exception::Load;

use Mouse;
extends 'Config::Model::Exception::User';

sub _desc { 'Load command error'}

has command => (is => 'rw', isa => 'ArrayRef|Str');

sub full_message {
    my $self = shift;

    my $location = defined $self->object ? $self->object->name : '';
    my $msg      = $self->description;
    my $cmd      = $self->command;
    no warnings 'uninitialized';
    my $cmd_str =
           ref($cmd)   ? join('',@$cmd)
        : $cmd         ? "'$cmd'"
        : defined $cmd ? '<empty>'
        :                '<undef>';
    $msg .= " in node '$location' " if $location;
    $msg .= ':';
    $msg .= "\n\tcommand: $cmd_str";
    $msg .= "\n\t" . $self->error_or_msg . "\n";

    return $msg;
}

package Config::Model::Exception::UnavailableElement;

use Mouse;
extends 'Config::Model::Exception::User';

sub _desc { 'unavailable element'}

has [qw/element function/] => (is => 'rw', isa => 'Str');


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

package Config::Model::Exception::AncestorClass;

use Mouse;
extends 'Config::Model::Exception::User';

sub _desc { 'unknown ancestor class'}


package Config::Model::Exception::ObsoleteElement;

use Mouse;
extends 'Config::Model::Exception::User';

sub _desc { 'Obsolete element' }

has element => (is => 'rw', isa => 'Str');

sub full_message {
    my $self = shift;

    my $obj     = $self->object;
    my $element = $self->element;
    my $msg     = $self->description;

    my $location = $obj->name;
    my $help = $obj->get_help_as_text($element) || '';

    $msg .= " '$element' in node '$location'.\n";
    $msg .= "\t$help\n";
    $msg .= "\t" . $self->info . "\n" if defined $self->info;
    return $msg;
}

package Config::Model::Exception::UnknownElement;

use Carp;

use Mouse;
extends 'Config::Model::Exception::User';

sub _desc { 'unknown element' }

has [qw/element function where/] => (is => 'rw');

sub full_message {
    my $self = shift;

    my $obj = $self->object;

    confess "Exception::UnknownElement: object is ", ref($obj), ". Expected a node"
        unless ref($obj) && ($obj->isa('Config::Model::Node')
        || $obj->isa('Config::Model::WarpedNode'));

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

    # retrieve a support url from application info to guide user toward the right bug tracker
    my $info = $obj->instance->get_support_info // 'to https://github.com/dod38fr/config-model/issues';
    $msg .=
          " Either your file has an error or $class_name model is lagging behind. "
        . "In the latter case, please submit a bug report $info. See cme man "
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

package Config::Model::Exception::WarpError;

use Mouse;
extends 'Config::Model::Exception::User';

sub _desc { 'warp error'}

package Config::Model::Exception::Fatal;

use Mouse;
extends 'Config::Model::Exception::Any';

sub _desc { 'fatal error' }


package Config::Model::Exception::UnknownId;

use Mouse;
extends 'Config::Model::Exception::User';

sub _desc { 'unknown identifier'}

has [qw/element id function where/] => (is => 'rw', isa => 'Str');

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

package Config::Model::Exception::WrongValue;

use Mouse;
extends 'Config::Model::Exception::User';

sub _desc { 'wrong value'};


package Config::Model::Exception::WrongType;

use Mouse;
extends 'Config::Model::Exception::User';

sub _desc { 'wrong element type' };

has [qw/function got_type/] => (is => 'rw', isa => 'Str');
has [qw/expected_type/] => (is => 'rw');

sub full_message {
    my $self = shift;

    my $obj = $self->object;

    my $msg = '';
    $msg .= "In function " . $self->function . ": "
        if defined $self->function;

    my $type = $self->expected_type;

    $msg .=
          $self->description
        . " for element '"
        . $obj->location
        . "'\n\tgot type '"
        . $self->got_type
        . "', expected '"
        .  (ref $type ? join("' or '",@$type) : $type) . "' "
        . $self->info . "\n";

    return $msg;
}

package Config::Model::Exception::ConfigFile;

use Mouse;
extends 'Config::Model::Exception::User';

sub _desc { 'error in configuration file' }

package Config::Model::Exception::ConfigFile::Missing;

use Mouse;
extends 'Config::Model::Exception::ConfigFile';

sub _desc { 'missing configuration file'}

has tried_files => (is => 'rw', isa => 'ArrayRef');

sub full_message {
    my $self = shift;

    my $msg = "Error: cannot find configuration file " . join (' or ', @{ $self->tried_files });

    return $msg . "\n";
}

package Config::Model::Exception::Formula;

use Mouse;
extends 'Config::Model::Exception::Model';

sub _desc { 'error in computation formula of the configuration model'}

package Config::Model::Exception::Internal;

use Mouse;
extends 'Config::Model::Exception::Fatal';

sub _desc { 'internal error' }

1;

# ABSTRACT: Exception mechanism for configuration model

__END__

=head1 SYNOPSIS

  use  Config::Model::Exception;

  # later
  my $kaboom = 1;
  Config::Model::Exception::Model->throw(
      error  => "Went kaboom",
      object => $self
  ) if $kaboom;


=head1 DESCRIPTION

This module creates exception classes used by L<Config::Model>.

All exception class name begins with C<Config::Model::Exception>

The exception classes are:

=over

=item C<Config::Model::Exception>

Base class. It accepts an C<object> argument. The user must pass the
reference of the object where the exception occurred. The object name
is used to generate the error message.

=back

  TODO: list all exception classes and hierarchy. 

=head1 How to get trace

By default, most of the exceptions do not print out the stack
trace. For debug purpose, you can force a stack trace for all
exception classes:

  Config::Model::Exception->Trace(1) ;

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>, 
L<Config::Model::Instance>, 
L<Config::Model::Node>,
L<Config::Model::Value>

=cut
