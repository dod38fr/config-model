#    Copyright (c) 2005-2011 Dominique Dumont.
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

use warnings FATAL => qw(all);
use strict;
use File::Slurp qw/slurp/;
use Config::Model ; # to generate doc
use Log::Log4perl qw(:easy) ;

Log::Log4perl->easy_init($WARN);

require 5.008;

print "\nIf you want to use the TermUI interface, you should install\n",
  "Term::ReadLine::Perl or Term::ReadLine::Gnu\n\n";

my @version_info = @ARGV ? ( dist_version => $ARGV[0] ) : ();

my %appli_files = map { ( $_, $_ ) } glob("lib/Config/Model/*.d/*");

my $model = Config::Model -> new(model_dir => "lib/Config/Model/models") ;

my @generated_pods ;
# map {
    # if (not $model->model_exists($_)) {
        # print "Generating doc for model $_\n";
        # $model->load($_) ;
        # $model->generate_doc ($_,'lib') ;
    # }
  # }
  # map { /model\s*=\s*([\w:-]+)/; $1; }
  # grep { /^\s*model/; }
  #map  { slurp($_); } glob("lib/Config/Model/*.d/*");

my $build = Module::Build->new(
    module_name => 'Config::Model',
    @version_info,
    license       => 'lgpl',
    script_files  => ['config-edit'],
    appli_files   => \%appli_files,
    dist_abstract => 'Describe, edit and validate configuration data',
    dist_author   => 'Dominique Dumont (ddumont at cpan dot org)',

##{ $plugin->get_prereqs ##}

    meta_merge => {
        resources => {
            homepage => 'http://config-model.wiki.sourceforge.net',
            MailingList =>
              'https://lists.sourceforge.net/lists/listinfo/config-model-users',
            repository =>
              'http://config-model.hg.sourceforge.net:8000/hgroot/config-model/config-model',
        },
    },

    # cleanup required by t/auto_read.t
    # PreGrammar.pm is created by t/value_computer.t
    add_to_cleanup => [qw/PreGrammar.pm wr_root r_root/, @generated_pods],
);

$build->add_build_element('pl');
$build->add_build_element('appli');

$build->create_build_script;
