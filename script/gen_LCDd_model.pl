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
use lib qw/lib/ ;
use strict;

my $target = "lib/Config/Model/models/LCDd.pl";
my $script = "examples/lcdproc/lcdconf2model.pl";
my $source = "examples/lcdproc/LCDd.conf" ;

exit if -e $target and -M $target < -M $script and -M $target < -M $source ;

eval { require Config::Model::Itself ;} ;
if ( $@ ) {
    print "Config::Model::Itself is not available, skipping LCDd model generation\n";
    exit ;
}

unless (my $return = do $script) {
    warn "couldn't parse $script: $@" if $@;
    warn "couldn't do $script: $!"    unless defined $return;
    warn "couldn't run $script"       unless $return;
}


