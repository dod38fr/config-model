# $Author: ddumont $
# $Date: 2007-09-20 16:21:34 $
# $Name: not supported by cvs2svn $
# $Revision: 1.13 $

#    Copyright (c) 2005-2006 Dominique Dumont.
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

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my @files= grep {$_ ne "Model.pm"} <*.pm> ;

my %PM = map ( ( "$_" => '$(INST_LIB)'."/Config/Model/$_" ), @files ) ;

$PM{"Model.pm"} = '$(INST_LIB)'."/Config/Model.pm" ;

my %M3 = map {
    my $save = $_ ;
    s/\.pm$/.3pm/ ;
    ( $save => '$(INST_MAN3DIR)/Config::Model::'."$_" )
} @files  ;

$M3{"Model.pm"}= '$(INST_MAN3DIR)/Config::Model.3pm' ;

#print join("\n", values %M3),"\n"; exit ;

WriteMakefile 
  (
   NAME         => 'Config-Model',
   VERSION_FROM => 'Model.pm',
   dist         => {COMPRESS=>'gzip -9f', SUFFIX => 'gz'},
   PM           => \%PM ,
   MAN3PODS     => \%M3,
   'EXE_FILES'  => [ 'config-edit' ],
   ABSTRACT     => 'Describe and edit configuration data',
   AUTHOR       => 'Dominique Dumont (ddumont at cpan dot org)',
   PREREQ_PM    => {
		    'Test::More'        => 0, # for test
		    'Term::ReadLine'    => 0,
		    # not tested with Term::ReadLine::Perl
		    'Term::ReadLine::Gnu' => 0,
		    'Log::Log4perl'     => 0,
		    'Parse::RecDescent' => '1.90',
		    'Scalar::Util'      => 0, # provided by perl 5.8.0
		    'Exception::Class'  => 0,
		    'Carp::Assert::More' => 0,
		    'Error'             => 0
		   },
   # cleanup required by t/auto_read.t
   # PreGrammar.pm is create by t/value_computer.t
   clean => {FILES => "PreGrammar.pm wr_test zero_test"}
  );

