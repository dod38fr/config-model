
#    Copyright (c) 2008 Dominique Dumont.
#
#    This file is part of Config-Model-Itself.
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

package Config::Model::Itself::TkEditUI ;

use strict;
use warnings ;
use Carp ;

use base qw/Config::Model::TkUI/;
# use vars qw/$VERSION/ ;


Construct Tk::Widget 'ConfigModelEditUI';

sub ClassInit {
    my ($class, $mw) = @_;
    # ClassInit is often used to define bindings and/or other
    # resources shared by all instances, e.g., images.


    # cw->Advertise(name=>$widget);
}

sub Populate { 
    my ($cw, $args) = @_;


    my $r_model_dir  = delete $args->{-read_model_dir} ;
    my $w_model_dir  = delete $args->{-write_model_dir} ;
    my $model_name   = delete $args->{-model_name} ;
    my $root_dir     = delete $args->{-root_dir} ;

    $args->{'-title'} ||= "config-model-edit $model_name" ;

    $cw->SUPER::Populate($args) ;

    my $items = [[ qw/command test -command/, sub{ $cw->test_model }],
		] ;

    my $model_menu = $cw->{my_menu}->cascade(-label => 'Model', -menuitems => $items) ;
    $cw->{read_model_dir} = $r_model_dir ;
    $cw->{write_model_dir} = $w_model_dir ;
    $cw->{model_name} = $model_name ;
    $cw->{root_dir} = $root_dir ;
}

sub test_model {
    my $cw = shift ;

    $cw->save_if_yes("save model data ?") ;

    my $testw =  $cw -> {test_widget} ;
    $testw->destroy if defined $testw and Tk::Exists($testw);

    # need to read test model from where it was written...
    my $model = Config::Model -> new(model_dir => $cw->{write_model_dir}) ;

    my $name = $cw->{model_name};
    my $inst = $model->instance (root_class_name => $name,
				 instance_name => "test $name model",
				 root_dir => $cw->{root_dir} ,
				);

    my $root = $inst -> config_root ;

    $cw -> {test_widget} = $cw->ConfigModelUI (-root => $root, -quit => 'soft') ;
}

1;
