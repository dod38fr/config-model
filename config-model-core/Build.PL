#    Copyright (c) 2005-2010 Dominique Dumont.
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

use Module::Build;

use warnings FATAL => qw(all) ;
use strict ;

require 5.008;

print "\nIf you want to use the TermUI interface, you should install\n",
  "Term::ReadLine::Perl or Term::ReadLine::Gnu\n\n";

# The code below will be fed to subclass method of Module::Build.
# This will create a new Module::Build class that can handle 
# config-edit.tmpl template file to generate scripts dedicated
# to models included within this distribution (e.g. config-edit-popcon ...)
# For more details see 
# http://search.cpan.org/~dagolden/Module-Build-0.3607/lib/Module/Build/Authoring.pod#SUBCLASSING

my $code = << 'EOF';

use Text::Template ;
my %models = ( popcon => [ 'PopCon', '/etc/popularity-contest.conf'],
               'dpkg-copyright'   => [ 'Debian::Dpkg::Copyright', 'debian/copyright'],
               'dpkg-control'     => [ 'Debian::Dpkg::Control'  , 'debian/control'],
             ) ;

sub process_tmpl_files {
  my $self = shift;
  print "process_tmpl_files called\n";
  my $template = Text::Template->new(SOURCE => 'config-edit.tmpl')
    or die "Couldn't construct template: $Text::Template::ERROR";

  foreach (keys %models) {
    my $v = $models{$_} ;
    my %vars = ( name => $_,  model => $v->[0], conf_file => $v->[1]) ;
    my $fout = "blib/script/config-edit-$_" ;
    print "Creating $fout\n";
    my $result = $template->fill_in( HASH => \%vars) ;
    if (defined $result) { 
      open (FOUT, "> $fout") || die "Can't open $fout:$!";
      print FOUT $result;
      close FOUT ;
      chmod 0755,$fout || die "Can't chmod $fout:$!";
    }
    else { die "Couldn't fill in template: $Text::Template::ERROR"  ; }
  }
}

EOF

my $class = Module::Build->subclass(code => $code);
my @version_info = @ARGV ? (dist_version => $ARGV[0]) : () ;


my $build = $class->new
  (
   module_name    => 'Config::Model',
   @version_info,
   license        => 'lgpl',
   script_files   => [ 'config-edit' ],
   dist_abstract  => 'Describe, edit and validate configuration data',
   dist_author    => 'Dominique Dumont (ddumont at cpan dot org)',

##{ $plugin->get_prereqs ##}

    meta_merge => {
                  resources => {
                    homepage => 'http://config-model.wiki.sourceforge.net',
                    MailingList => 'https://lists.sourceforge.net/lists/listinfo/config-model-users',
                    repository => 'http://config-model.hg.sourceforge.net:8000/hgroot/config-model/config-model',
                  },
  },
   # cleanup required by t/auto_read.t
   # PreGrammar.pm is created by t/value_computer.t
   add_to_cleanup => [qw/PreGrammar.pm wr_root r_root/],
  );

$build->add_build_element('tmpl');
$build->add_build_element('pl');
$build->create_build_script;
