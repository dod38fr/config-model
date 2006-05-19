# $Author: ddumont $
# $Date: 2006-05-19 12:35:21 $
# $Name: not supported by cvs2svn $
# $Revision: 1.1 $

#    Copyright (c) 2005,2006 Dominique Dumont.
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

use strict ;
use warnings ;

# this line is necessary to run the example without installing
# Config::Model
use lib ('../../blib/lib') ;

use Config::Model ;
use Getopt::Long ;
use Text::Wrap ;

use vars qw/$model/ ;


my $use_sample = 0;
GetOptions ("use_sample" => \$use_sample);

my $fstab_file = $use_sample ? 'fstab.sample' : '/etc/fstab' ;

$model = Config::Model -> new ;

do "FstabModel.pl" || die "compile error: $@";

my $instance = $model -> instance( root_class_name => 'Fstab',
				   instance_name => 'test'
				 ) ;

my $root= $instance -> config_root ;

print "
The first part of this example program will read your $fstab_file.
Bear in mind that the current Fstab model is far from being complete.
If this program fails to read your /etc/fstab, please re-run it with
'-use_sample' option.

";

sub stop {
    print "Hit any key to continue\n";
    my $read = <STDIN> ;
}

stop() ;

open(FSTAB, $fstab_file) || die "Can't open $fstab_file:$!";

my %opt_r_translate 
  = (
     ro => 'rw=0',
     rw => 'rw=1',
     bsddf => 'statfs_behavior=bsddf',
     minixdf => 'statfs_behavior=minixdf',
    ) ;

my $nb = 0;
while (<FSTAB>) {
    s/#.*//;
    next if /^\s*$/;
    my ($device,$mount_point,$type,$options, $dump, $pass) = split;

    my $line_obj 
      = $root->fetch_element('line')->fetch_with_id($nb++) ;

    my $load_line = "fs_vfstype=$type fs_spec=$device fs_file=$mount_point "
      ."fs_freq=$dump fs_passno=$pass" ;
    #print "loading with '$load_line'\n";
    $line_obj->load($load_line) ;

    # now load options
    #print "fs_type $type options is $options\n";
    my @options = split /,/,$options ;
    map {
	$_ = $opt_r_translate{$_} if defined $opt_r_translate{$_};
	s/no(.*)/$1=0/ ;
	$_ .= '=1' unless /=/ ;
    } @options ;
    #print "load @options\n";
    $line_obj->fetch_element('fs_mntopts')->load (\@options) ;
}

print "

The second part of this program will produce a report that shows the
settings contained in $fstab_file and shows the on-line help provided
with Fstab model (feel free to modify FstabModel.pm to provide more
help).

";

stop ;

print $root->report() ;

print "

The third part of this program will produce a minimal fstab file
without any comment:

";

stop ;
# now write back a valid fstab file

sub produce_fstab {
    my $with_help = shift || 0 ;

    my %opt_w_translate = 
      (
       rw => { 0 => 'ro', 1 => 'rw' },
       statfs_behavior => { bsddf => 'bsddf', minixdf => 'minixdf'},
       user => { 0 => '' , 1 => 'user'},
       sw => { 0 => '' , 1 => 'sw'},
       defaults => { 0 => '' , 1 => 'defaults'},
       auto => { 0 => 'noauto' , 1 => 'auto'},
      );

    my @new_fstab ;
    foreach my $line_obj ($root->fetch_element('line')->fetch_all) {
	my $opt_container = $line_obj->fetch_element('fs_mntopts');
	my $fs_type = $line_obj->fetch_element_value('fs_vfstype');

	if ($with_help) {
	    my $line_help = $line_obj->fetch_element('fs_vfstype')
	      ->get_help($fs_type);
	    push @new_fstab, wrap("# '$fs_type' file system: ",
				  '#    ', $line_help) if $line_help;
	}

	my @opt_arg;
	foreach my $opt_name ($opt_container -> get_element_name) {
	    my $opt_value = $opt_container->fetch_element_value($opt_name) ;
	    next unless defined $opt_value;

	    my $show_value = '';;
	    if (defined $opt_w_translate{$opt_name} &&
		defined $opt_w_translate{$opt_name}{$opt_value} ) {
		$show_value = $opt_w_translate{$opt_name}{$opt_value} ;
	    }
	    elsif (defined $opt_w_translate{$opt_name}) {
		$show_value = $opt_value ;
	    }
	    else {
		$show_value = "$opt_name=$opt_value" ;
	    }

	    if ($with_help) {
		my $opt_help = $opt_container->fetch_element($opt_name)
		  -> get_help($opt_value) ;
		push @new_fstab, wrap("#    * option '$show_value' effect: ",
				      '#        ', $opt_help) if $opt_help;
	    }

	    push @opt_arg, $show_value if $show_value ;
	}

	push @new_fstab, sprintf("%-10s %-20s %-15s %-15s %d %d",
				 $line_obj->fetch_element_value('fs_spec'),
				 $line_obj->fetch_element_value('fs_file'),
				 $fs_type ,
				 join(',',@opt_arg),
				 $line_obj->fetch_element_value('fs_freq'),
				 $line_obj->fetch_element_value('fs_passno'),
				) ;
	push @new_fstab, "" if $with_help ;
    }

    return @new_fstab
}


print join ("\n",produce_fstab()),"\n";

print "

To help newbie to understand their configuration files, we can also
produce a fstab file with the help and descriptions provided in fstab
model.

";

stop ;

print join ("\n",produce_fstab(1)),"\n";
