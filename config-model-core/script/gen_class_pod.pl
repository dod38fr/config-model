#!/usr/bin/perl

#    Copyright (c) 2011 Dominique Dumont.
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
#    02110-1301 USA

use warnings FATAL => qw(all);
use strict;
use File::Slurp qw/slurp/;
use Config::Model ; # to generate doc
use Log::Log4perl qw(:easy) ;

Log::Log4perl->easy_init($WARN);


my %appli_files = map { ( $_, $_ ) } glob("lib/Config/Model/*.d/*");

my $model = Config::Model -> new(model_dir => "lib/Config/Model/models") ;

my @generated_pods ;
map {
    if (not $model->model_exists($_)) {
        print "Generating doc for model $_\n";
        $model->load($_) ;
        $model->generate_doc ($_,'lib') ;
    }
  }
  map { /model\s*=\s*([\w:-]+)/; $1; }
  grep { /^\s*model/; }
  map  { slurp($_); } glob("lib/Config/Model/*.d/*");

