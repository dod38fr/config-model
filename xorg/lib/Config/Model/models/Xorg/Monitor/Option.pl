# $Author: ddumont $
# $Date: 2006-12-07 13:13:23 $
# $Name: not supported by cvs2svn $
# $Revision: 1.1 $

#    Copyright (c) 2005,2006 Dominique Dumont.
#
#    This file is part of Config-Xorg.
#
#    Config-Xorg is free software; you can redistribute it and/or
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


# This model was created from xorg.conf(5x) man page from xorg
# project (http://www.x.org/).

# Model for Mode line (used by Monitor and Modes section)
# see xorg.conf

[
 [
  name => "Xorg::Monitor::Option",
  'element'
  => [ [qw/DPMS SyncOnGreen/ ]
       => {type       => 'leaf', value_type => 'boolean' },
     ]
 ],
];
