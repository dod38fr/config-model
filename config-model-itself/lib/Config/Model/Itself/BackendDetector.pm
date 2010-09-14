#    Copyright (c) 2010 Dominique Dumont.
#
#    This file is part of Config-Model-Itself.
#
#    Config-Model-Itself is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser Public License as
#    published by the Free Software Foundation; either version 2.1 of
#    the License, or (at your option) any later version.
#
#    Config-Xorg is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser Public License for more details.
#
#    You should have received a copy of the GNU Lesser Public License
#    along with Config-Model; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA

package Config::Model::Itself::BackendDetector ;

use Pod::POM ;
use File::Find ;

use base qw/Config::Model::Value/ ;

use strict ;
use warnings ;

our $VERSION="1.001";

sub setup_enum_choice {
    my $self = shift ;
    my @choices = ref $_[0] ? @{$_[0]} : @_ ;

    #find available backends

    my $path = $INC{"Config/Model.pm"} ;
    $path =~ s!\.pm!/Backend! ;

    my $wanted = sub { 
        my $n = $File::Find::name ;
        if (-f $_ and $n =~ s/\.pm$// and $n !~ /Any$/) {
	    $n =~ s!.*Backend/!! ;
	    $n =~ s!/!::!g ;
	    push @choices , $n ;
        }
    } ;
    find ($wanted, $path ) ;
    
    $self->SUPER::setup_enum_choice(@choices) ;
}

sub set_help {
    my ($self,$args) = @_ ;

    my $help = delete $args->{help} || {} ;

    my $path = $INC{"Config/Model.pm"} ;
    $path =~ s!\.pm!/Backend! ;

    my $parser = Pod::POM->new();

    my $wanted = sub { 
        my $n = $File::Find::name ;
	
        return unless (-f $n and $n !~ /Any\.pm$/) ;
        my $file = $n ;
	$n =~ s/\.pm$//;
	$n =~ s!/!::!g ;
	my $perl_name = $n ;
	$n =~ s!.*Backend::!! ;
	$perl_name =~ s!.*Config!Config! ;

	my $pom = $parser->parse_file($file)|| die $parser->error();

	foreach my $head1 ($pom->head1()) {
	    if ($head1->title() eq 'NAME') {
		my $c = $head1->content();
		$c =~ s/.*?-\s*//;
		$c =~ s/\n//g;
		$help->{$n} = $c . " provided by $perl_name"."::".$n;
		last;
	    }
	}
    };

    find ($wanted, $path ) ;

    $self->{help} =  $help;
}

1;

__END__

=head1 NAME

Config::Model::Itself::BackendDetector - Detect available read/write backends

=head1 SYNOPSIS

 # this class should be referenced in a configuration model and
 # created only by Config::Model::Node

 my $model = Config::Model->new() ;

 $model ->create_config_class
  (
   name => "Test",
   'element'
   => [ 
       'backend' => { type => 'leaf',
                      class => 'Config::Model::Itself::BackendDetector' ,
                      value_type => 'enum',
                      # specify backends built in Config::Model
                      choice => [qw/cds_file perl_file ini_file augeas custom/],

                      help => {
                               cds_file => "file ...",
                               ini_file => "Ini file ...",
                               perl_file => "file  perl",
                               custom => "Custom format",
                               augeas => "Experimental backend",
                              }
                    }
      ],
  );

  my $root = $model->instance(root_class_name => 'Test') -> config_root ;

  my $backend = $root->fetch_element('backend') ;

  my @choices = $backend->get_choice ;


=head1 DESCRIPTION

This class is derived from L<Config::Model::Value>. It is designed to
be used in a 'enum' value where the choice (the available backends)
are the backend built in L<Config::Model> and all the plugin backends. The
plugin backends are all the C<Config::Model::Backend::*> classes.

This module will detect available plugin backend and query their pod
documentation to provide a contextual help for config-model graphical
editor.

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>, L<Config::Model::Node>, L<Config::Model::Value>

=cut

