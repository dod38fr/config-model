# $Author: ddumont $
# $Date: 2007-01-08 12:41:54 $
# $Name: not supported by cvs2svn $
# $Revision: 1.7 $

#    Copyright (c) 2005,2006 Dominique Dumont.
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

package Config::Model::Exception ;
use Error ;
use warnings ;
use strict;

use vars qw($VERSION) ;
$VERSION = sprintf "%d.%03d", q$Revision: 1.7 $ =~ /(\d+)\.(\d+)/;

push @Exception::Class::Base::ISA, 'Error';

use Exception::Class 
  (
   'Config::Model::Exception::Any' 
   => { description => 'config error' ,
	fields      =>  'object' ,
      },

   'Config::Model::Exception::User' 
   => { isa         => 'Config::Model::Exception::Any',
	description => 'user error' ,
      },

   'Config::Model::Exception::UnavailableElement'
   => { isa         => 'Config::Model::Exception::User',
	description => 'unavailable element',
	fields      => [qw/object element info/],
      },

   'Config::Model::Exception::ObsoleteElement'
   => { isa         => 'Config::Model::Exception::User',
	description => 'unavailable element',
	fields      => [qw/object element info/],
      },

   'Config::Model::Exception::RestrictedElement' 
   => { isa         => 'Config::Model::Exception::User',
	description => 'restricted element',
	fields      => [qw/object element level req_level info/],
      },

   'Config::Model::Exception::WrongType' 
   => { isa         => 'Config::Model::Exception::User',
	description => 'wrong element type',
	fields      => [qw/object function got_type expected_type info/],
      },

   'Config::Model::Exception::WrongValue'
   => { isa         => 'Config::Model::Exception::User',
	description => 'wrong value',
      },

   'Config::Model::Exception::Load' 
   => { isa         => 'Config::Model::Exception::User',
	description => 'Load command error',
	fields      => [qw/object command/],
      },

   'Config::Model::Exception::UnknownElement' 
   => { isa         => 'Config::Model::Exception::User',
	description => 'unknown element',
	fields      => [qw/object min_level element function where info/],
      },

   'Config::Model::Exception::UnknownId' 
   => { isa         => 'Config::Model::Exception::User',
	description => 'unknown identifier',
	fields => [qw/object min_level element id function where/],
      },

   'Config::Model::Exception::WarpError'
   => { isa         => 'Config::Model::Exception::User',
	description => 'warp error',
      },

   'Config::Model::Exception::Fatal'  
   => { isa         => 'Config::Model::Exception::Any',
	description => 'fatal error',
      },

   'Config::Model::Exception::Model' 
   => { isa         => 'Config::Model::Exception::Fatal',
	description => 'configuration model error',
      },

   'Config::Model::Exception::ModelDeclaration' 
   => { isa         => 'Config::Model::Exception::Fatal',
	description => 'configuration model declaration error',
      },

   'Config::Model::Exception::Xml' 
   => { isa         => 'Config::Model::Exception::User',
	description => 'error in XML data',
      },

   'Config::Model::Exception::Formula' 
   => { isa         => 'Config::Model::Exception::Model',
	description => 'error in computation formula of the '
	              .'configuration model',
      },

   'Config::Model::Exception::Internal' 
   => { isa         => 'Config::Model::Exception::Fatal',
	description => 'internal error' ,
      },

   'Config::Model::Exception::XmlTree'
   => { description => 'error while parsing XML dump of a tree' },

  );

Config::Model::Exception::Internal->Trace(1);

package Config::Model::Exception::Any ;

sub full_message {
    my $self = shift;

    my $obj = $self->object ;
    my $location = defined $obj ? $obj->name :'';
    my $msg = "Configuration item ";
    $msg .= "'$location' " if $location ;
    $msg .= "has a ".$self->description ;
    $msg .= ":\n\t". $self->message."\n";

    return $msg;
}

sub xpath_message {
    my $self = shift;

    my $location = defined $self->object ? $self->object->xpath :'';

    my $msg = "Configuration item ";
    $msg .= "'$location' " if $location ;
    $msg .= "has a ".$self->description ;
    $msg .= ":\n\t". $self->message."\n";

    return $msg;
}

package Config::Model::Exception::Model ;

sub full_message {
    my $self = shift;

    my $obj = $self->object ;
    my $msg ;
    if ($obj->isa('Config::Model::Node')) {
	$msg = "Node '".$obj->name."' ";
    }
    else {
	my $element = $obj->element_name ;
	$msg = "In config class '" . $obj->parent->config_class_name
	  . "', element '$element' ";
    }
    $msg .= "has a ".$self->description ;
    $msg .= ":\n\t". $self->message."\n";

    return $msg;
}

package Config::Model::Exception::Load ;

sub full_message {
    my $self = shift;

    my $location = defined $self->object ? $self->object->name :'';
    my $msg = $self->description;
    $msg .= " in node '$location'" if $location ;
    $msg .= ':';
    $msg .= "\n\tcommand: ".$self->command if $self->command ne '';
    $msg .= "\n\t". $self->message."\n";

    return $msg;
}

package Config::Model::Exception::RestrictedElement ;

sub full_message {
    my $self = shift;

    my $location = $self->object->name ;
    my $msg = $self->description;
    my $element = $self->element ;
    my $req = $self->object
      ->get_element_property(element => $element, property => 'permission') ;
    $msg .= " '$element' in node '$location':" ;
    $msg .= "\n\tNeed privilege '$req' instead of '".
      $self->level."'\n";
    $msg .= "\t".$self->info."\n" if defined $self->info ;
    return $msg;
}

package Config::Model::Exception::UnavailableElement ;

sub full_message {
    my $self = shift;

    my $obj = $self->object ;
    my $location = $obj->name ;
    my $msg = $self->description;
    my $element = $self->element ;
    $msg .= "'$element' in node '$location'.\n" ;
    my $tied = 'tied_'.$element ;

    $msg .= "\t".$obj->$tied->warp_error
      if $obj->can($tied) and $obj->$tied->can('warp_error');

    $msg .= "\t".$self->info."\n" if defined $self->info ;
    return $msg;
}


package Config::Model::Exception::UnknownElement ;
use Carp;

sub full_message {
    my $self = shift;

    my $obj = $self->object ;

    confess "Exception::UnknownElement: object is ",ref($obj),
      ". Expected a node" 
	unless $obj->isa('Config::Model::Node') 
	  || $obj->isa('Config::Model::WarpedNode');

    my $min_level = $self->min_level || 'master' ;
    # TBD use model instead of node
    my @elements = $obj -> config_model 
      -> get_element_name(class => $obj -> config_class_name,
			  for => $min_level) ;

    my $msg = '';
    $msg .= "In ". $self->where .": " if 
      defined $self->where;

    $msg .= "(function '". $self->function ."') " if 
      defined $self->function;

    $msg = "object '".$obj->name."' error: " unless $msg ;

    $msg .=
      $self->description. " '". $self->element. "'"
        . " (configuration class '".$obj -> config_class_name ."')\n"
          . "\tExpected: '". join("','",@elements)."'\n" ;

    # inform about available elements after a change of warp master value
    if (defined $obj->parent) {
	my $parent       = $obj->parent ;
	my $element_name = $obj->element_name ;

	if ($parent->element_type ( $element_name ) eq 'warped_node' ) {
	    $msg .= "\t". 
	      $parent -> fetch_element( $element_name ) -> warp_error ;
	}
    }

    $msg .= "\t".$self->info."\n" if (defined $self->info) ;

    return $msg;
}

package Config::Model::Exception::UnknownId ;

sub full_message {
    my $self = shift;

    my $obj = $self->object ;
    my $min_level = $self->min_level || 'master' ;

    my $element = $self->element ;
    my $id_str = "'".join("','",$obj->get_all_indexes())."'" ;

    my $msg = '';
    $msg .= "In function ". $self->function .": " if 
      defined $self->function;

    $msg .= "In ". $self->where .": " if 
      defined $self->where;

    $msg .=
      $self->description. " '". $self->id() . "'"
        . " for element '".$obj->location
          . "'\n\texpected: $id_str\n" ;

    return $msg;
}

package Config::Model::Exception::WrongType ;

sub full_message {
    my $self = shift;

    my $obj = $self->object ;

    my $msg = '';
    $msg .= "In function ". $self->function .": " if 
      defined $self->function;

    $msg .=
      $self->description
        . " for element '".$obj->location
          . "'\n\tgot type '".$self->got_type
	  . "', expected '". $self->expected_type
	    . "' ". $self->info. "\n" ;

    return $msg;
}

package Config::Model::Exception::Xml ;

sub full_message {
    my $self = shift;

    my $obj = $self->object ;
    my $msg = $self->message ;

    $msg .= "\n\t".
      join ("\n\t",
	    map ( $_->xpath_message,
		  $self->object->errors)) if defined $self->object;

    return $msg."\n";
}


1;

__END__

=head1 NAME

Config::Model::Exception - Exception mechanism for configuration model

=head1 SYNOPSIS

 # in module
 Config::Model::Exception::Model->throw
     (
       object => $self,
       error => "Oops in model"
     ) if $fail ;

 # in application
 try 
   { 
     function_that_may_fail() 
   }
 catch Config::Model::Exception::Model with
  {
    my $exception = shift;
    warn $ex->error ;
    # fix failure
  }

=head1 DESCRIPTION

You must read L<Exception::Class> and L<Error> before reading on.

This module creates all the exception class used by L<Config::Model>.

All expection class name begins with C<Config::Model::Exception::>

The exception classes are:

=over

=item C<Any>

Base class. It accepts an C<object> argument. The user must pass the
reference of the object where the exception occured. The object name
(or xpath) will be used to generate the error message.

=back

  TODO: list all exception classes and hierarchy. 

=head1 How to get trace

By default, most of the exceptions will not print out the stack
trace. For debug purpose, you can force a strack trace.

For instance, if you want a stack trace for an "unknown element"
error, you must add this line in your script:

  Config::Model::Exception::UnknownElement->Trace(1) ;

If you're not sure which class to trace, add this line in your
script:

  Config::Model::Exception::Any->Trace(1) ;

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model::Model>, 
L<Config::Model::Instance>, 
L<Config::Model::Node>,
L<Config::Model::Value>
L<Error>, 
L<Exception::Class>

=cut
