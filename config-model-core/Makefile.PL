# $Author: ddumont $
# $Date: 2006-01-02 12:48:05 $
# $Name: not supported by cvs2svn $
# $Revision: 1.2 $

#    Copyright (c) 2005 Dominique Dumont.
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

my $str = '';
my $clean = '';
foreach my $what (qw/ValueFormula/) {
    my $name = $what.'Parser' ;
    my $pname = $name.'.pm';
    my $gname = $what.'Grammar.txt';

    $str .= "\n$pname: $gname\n".
      "\t".'$(PERLRUN)'." -MParse::RecDescent - $gname Config::Model::$name\n".
          "\t".'echo "" >> '."$pname\n" ;
    push (@files, $pname) unless grep (/$name/, @files) ;
    $clean .= $pname.' ';
}

sub MY::postamble {
    $str ;
}

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
   NAME         => 'config-model',
   VERSION_FROM => 'Model.pm',
   dist         => {COMPRESS=>'gzip -9f', SUFFIX => 'gz'},
   PM           => \%PM ,
   MAN3PODS     => \%M3,
   ABSTRACT     => 'Configuration model for semantic validation of data',
   AUTHOR       => 'Dominique Dumont (domi@komarr.grenoble.hp.com)',
   PREREQ_PM    => {
		    'Struct::Compare'  => 0, # for test
		    'Test::More'       => 0, # for test
		    'Pod::Usage'       => 0,
		    'Log::Log4perl'    => 0,
		    'Scalar::Util'     => 0, # provided by perl 5.8.0
		    'Exception::Class' => 0,
		    'Error'            => 0
		   },
   clean => {FILES => $clean}
  );

