# $Author: ddumont $
# $Date: 2009-04-07 13:16:38 +0200 (mar 07 avr 2009) $
# $Revision: 920 $

#    Copyright (c) 2007,2009 Dominique Dumont.
#
#    This file is part of Config-Model-DebconfUI.
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

package Debconf::Client::ConfModule ':all';
version('2.0');

use strict;
use warnings ;
use Carp ;

use vars qw/$VERSION/ ;
use Scalar::Util qw/weaken/;
use Log::Log4perl;

sub new {
  my $class = shift ;

  my $self = {} ;

  bless $self,$type ;

}
