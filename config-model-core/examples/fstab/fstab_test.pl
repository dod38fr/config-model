#    Copyright (c) 2005,2006,2010 Dominique Dumont.
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
use File::Path ;

use vars qw/$model/ ;


my $use_etc = 0;
GetOptions ("use_etc" => \$use_etc);

my $fstab_file = $use_etc ?  '/etc/fstab' : 'fstab.sample'  ;

$model = Config::Model -> new(model_dir => '.') ;

my $instance = $model -> instance( root_class_name => 'Fstab',
				   instance_name => 'test',
				 ) ;

my $root= $instance -> config_root ;

print "
The first part of this example program will read a sample fstab file. You
can run this program with -use_etc to load /etc/fstab.
Just bear in mind that the Fstab model provided in this example is far from
being complete and may fail to read your file.

";

sub stop {
    print "Hit <return> to continue\n";
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

while (<FSTAB>) {
    s/#.*//;
    next if /^\s*$/;
    my ($device,$mount_point,$type,$options, $dump, $pass) = split;

    my ($dev_name) = ($device =~ /(\w+)$/) ;
    my $label = $type eq 'swap' ? "swap-on-$dev_name" : $mount_point; 

    my $fs_obj 
      = $root->fetch_element('fs')->fetch_with_id($label) ;

    my $load_line = "fs_vfstype=$type fs_spec=$device fs_file=$mount_point "
      ."fs_freq=$dump fs_passno=$pass" ;
    #print "loading with '$load_line'\n";
    $fs_obj->load($load_line) ;

    # now load options
    #print "fs_type $type options is $options\n";
    my @options = split /,/,$options ;
    map {
	$_ = $opt_r_translate{$_} if defined $opt_r_translate{$_};
	s/no(.*)/$1=0/ ;
	$_ .= '=1' unless /=/ ;
    } @options ;
    #print "load @options\n";
    $fs_obj->fetch_element('fs_mntopts')->load (\@options) ;
}

print "
ok. I could read $fstab_file.

The second part of this program will produce a report that shows the
settings contained in $fstab_file and shows the on-line help provided
with Fstab model (feel free to modify the model (Fstab.pm) to provide
more help).

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
       rw              => { 0 => 'ro', 1 => 'rw' },
       statfs_behavior => { bsddf => 'bsddf', minixdf => 'minixdf'},
       user            => { 0 => '' , 1 => 'user'},
       user_xattr      => { 0 => '' , 1 => 'user_xattr'},
       sw              => { 0 => '' , 1 => 'sw'},
       defaults        => { 0 => '' , 1 => 'defaults'},
       auto            => { 0 => 'noauto' , 1 => 'auto'},
      );

    my @new_fstab ;
    foreach my $fs_obj ($root->fetch_element('fs')->fetch_all) {
	my $opt_container = $fs_obj->fetch_element('fs_mntopts');
	my $fs_type = $fs_obj->fetch_element_value('fs_vfstype');

	if ($with_help) {
	    my $fs_help = $fs_obj->fetch_element('fs_vfstype')
	      ->get_help($fs_type);
	    push @new_fstab, 
	      "# fs label: ".$fs_obj->index_value ,
	      wrap("# '$fs_type' file system: ",
		   '#    ', $fs_help) if $fs_help;
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
				 $fs_obj->fetch_element_value('fs_spec'),
				 $fs_obj->fetch_element_value('fs_file'),
				 $fs_type ,
				 join(',',@opt_arg),
				 $fs_obj->fetch_element_value('fs_freq'),
				 $fs_obj->fetch_element_value('fs_passno'),
				) ;
	push @new_fstab, "" if $with_help ;
    }

    return @new_fstab
}


print join ("\n",produce_fstab()),"\n";

print "

To help newbie admin to understand their configuration files, this
program can also produce a fstab file with the help and descriptions
provided in fstab model.

";

stop ;

print join ("\n",produce_fstab(1)),"\n";

print "

Now you can enter in an interactive shell to explore or modify the
fstab data (do not fear to play in the pseudo-shell provided by this
program as the modified data will not be written back to /etc/fstab).

Exit the pseudo-shell by typing CTRL-D. 

The first command you might want to type is 'help'. You can also hit
TAB twice to get the list of available commands.

" ;

stop ;

my $store = sub { 
    my $dir = shift ;
    mkpath ($dir,0, 0755) unless -d $dir ;
    open(FILE,"> $dir/fstab") || die "Cannot open $dir/fstab: $!";
    print FILE join ("\n",produce_fstab()),"\n";
    close FILE ;
    return "Written $dir/fstab";
};

require Config::Model::TermUI;
my $term_ui = Config::Model::TermUI
  -> new( root => $root ,
	  title => $fstab_file.' configuration',
	  prompt => ' >',
	  store_sub => $store,
	);

# engage in user interaction
$term_ui -> run_loop ;

eval {require Config::Model::TkUI} ;

if ($@) {
    print "

If you want to try the Perl/Tk graphical interface, you must install 
Config::Model::TkUI and re-run this test.

" ;
}
else {
    print "

Now you can enter in a Tk graphical interface to check fstab
data. Like before, data are not written back to /etc/fstab, so feel
free to experiment

" ;

    stop ;

    use Log::Log4perl qw(:easy) ;
    Log::Log4perl->easy_init($WARN);

    require Tk;
    require Tk::ErrorDialog;
    Tk->import ;

    my $mw = MainWindow-> new ;
    $mw->withdraw ;

    $mw->ConfigModelUI (-root => $root,) ;

    &MainLoop ; # Tk's
}

eval {require Config::Model::CursesUI} ;

if ($@) {
    print "

If you want to try the curses interface, you must install 
Config::Model::CursesUI and re-run this test.

" ;
}
else {
    my $err_file = '/tmp/config-model-error.log' ;

    print "

Now you can enter in a curses interface to check fstab data. Like
before, data are not written back to /etc/fstab, so feel free to
experiment

In case of error, check $err_file

" ;

    stop ;

    open (FH,"> $err_file") || die "Can't open $err_file: $!" ;
    open STDERR, ">&FH";

    my $dialog = Config::Model::CursesUI-> new
      (
       permission => 'advanced',
      ) ;

    # engage in user interaction
    # eval is required to trap the exit done in Curses
    eval{ $dialog->start( $model ) } ;

    close FH ;
}


print "\n$0 done. Feel free to send feedback to the author ",
  "(ddumont at cpan dot org)\n\n";
