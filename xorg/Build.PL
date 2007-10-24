# $Author: ddumont $
# $Date: 2007-10-24 12:10:31 $
# $Name: not supported by cvs2svn $
# $Revision: 1.6 $

#    Copyright (c) 2007 Dominique Dumont.
#
#    This file is part of Config-Model-Xorg.
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
use Data::Dumper ;
use File::Copy ; # used when Xorg is not installed
use File::Path ;
use Config ;

require 5.006 ;

use warnings FATAL => qw(all) ;
use strict ;

use Data::Dumper ;
$Data::Dumper::Terse = 1 ;

use Config ;
use Cwd ;

sub generate {
    my $builder = shift ;
    my $out_file = shift ;
    my $data = shift ;
    print "Generating $out_file\n";
    open (KBDOPT, "> $out_file") || die "can't open $out_file to write:$!" ;
    print KBDOPT "# Generated file. Do not edit\n\n" ;
    print KBDOPT Dumper ( $data ) ;
    close KBDOPT ;
    $builder->add_to_cleanup($out_file) ;
}

sub my_copy {
    my $builder = shift ;
    my $from = shift ;
    my $to   = shift ;
    print cwd(),": copy from $from to $to\n";
    copy($from,$to) || die "Copy failed: $!";
    die "Not file $to" unless -r $to ;
    $builder->add_to_cleanup($to) ;
}


my $build = Module::Build->new
  (
   module_name   => 'Config::Model::Xorg',
   license       => 'lgpl',
   dist_version  => 0.505 ,
   dist_author   => "Dominique Dumont (ddumont at cpan dot org)",
   dist_abstract => "Configuration model for xorg.conf",
   requires      => {
		     'Config::Model'   => '0.614',
		     'Log::Log4perl'   => 0 ,
		    },
   recommends    => {
		     'Config::Model::CursesUI' => 0,
		    },
   add_to_cleanup => [qw/wr_test/] ,
  );


my $etc_xorg_dir 
  = $Config{osname} eq 'linux'   ? '/etc/X11' 
  : $Config{osname} eq 'freebsd' ? '/usr/X11/lib/X11'
  :                                undef ;

unless (defined $etc_xorg_dir) {
  $etc_xorg_dir = '/etc/X11' ;
  warn "Xorg model on ".$Config{osname}." will not work if ",
    "configuration files are not stored in /etc/X11/. ",
      "Contact the author in case of problems.\n";
}

unless (-d $etc_xorg_dir) {
    warn "Cannot find xorg conf in $etc_xorg_dir. Is Xorg installed ?\n",
      "Fallback action: Install some models for Linux. This may not work properly ";
    my $m_dir = "lib/Config/Model/models/Xorg" ;
    mkpath($m_dir, 1, 0755) unless -d $m_dir;
    my $opt_dir = "$m_dir/InputDevice/KeyboardOptModel" ;
    mkpath($opt_dir, 1, 0755) unless -d $opt_dir;
    my_copy($build,"fallback_models/ConfigDir.pl", "$m_dir/ConfigDir.pl");
    my_copy($build,"fallback_models/Sgi.pl",       "$opt_dir/Sgi.pl");
    my_copy($build,"fallback_models/Sun.pl",       "$opt_dir/Sun.pl");
    my_copy($build,"fallback_models/Xorg-it.pl",   "$opt_dir/Xorg-it.pl");
    my_copy($build,"fallback_models/Xorg.pl",      "$opt_dir/Xorg.pl");

    my $kopt_dir = "$m_dir/InputDevice";
    mkpath($kopt_dir, 1, 0755) unless -d $kopt_dir;
    my_copy($build,"fallback_models/KeyboardOptRules.pl",
	    "$kopt_dir/KeyboardOptRules.pl");

    $build->add_build_element('pl');
    $build->create_build_script;
    exit ;
}

print "Note: xorg.conf is expected to be located in $etc_xorg_dir\n";

my $generator = "Config::Model Build.PL" ;

my $model_dir = "lib/Config/Model/models";

my $xorg_config_file_model 
  = [ 
     [
      name => 'Xorg::ConfigDir',
      generated_by => $generator ,
      config_dir => $etc_xorg_dir ,
     ]
    ] ;

generate($build, "$model_dir/Xorg/ConfigDir.pl", $xorg_config_file_model) ;

my $out_dir = "$model_dir/Xorg/InputDevice" ;
my $out_model_dir = "$out_dir/KeyboardOptModel";

mkdir $out_model_dir, 0755 unless -d $out_model_dir ;

my %kbd_option_elt 
  = (
      'XkbRules'        => {
			    type => 'leaf',
			    value_type  => 'enum',
			    choice => [] ,
			    default => 'xorg',
			    help => { xfree86 => 'Deprecated in favor of xorg' },
			   },

     "XkbModel"  => {
		     type => 'leaf',
		     value_type  => 'enum',
		     warp => {
			      follow => '- XkbRules',
			      rules => {} ,
			     },
		    },

     # See /etc/X11/xkb/rules/xorg.lst

     "XkbLayout" => {
		     type => 'leaf',
		     value_type  => 'enum',
		     default => 'us',
		     warp => {
			      follow => '- XkbRules',
			      rules => {} ,
			     },
		    },

     "XkbVariant" => {
		      type => 'leaf',
		      value_type  => 'enum',
		      warp => { follow => [ '- XkbRules', '- XkbLayout' ] ,
				rules => [ ] ,
			      }
		     },
     # needs to be refined ...
     "XkbOptions" => {
		      type => 'warped_node',
		      follow => '- XkbRules',
		      rules => { } ,
		     }, 
    ) ;

my %defaults = (
		'model' => { xorg => 'pc105', 'xorg-it' => 'pc105' } ,
	       ) ;

foreach my $file (glob("$etc_xorg_dir/xkb/rules/*.lst")) {
    my ($rules_name) = ($file =~ m!/([\-\w]+)\.lst!) ;
    print "Scanning rule $rules_name from $file\n";
    push @{$kbd_option_elt{XkbRules}{choice}}, $rules_name ;

    if (-l $file) {
	my $link = readlink($file) ;
	my ($replace) =  ($link =~ m!([\-\w]+)\.lst!) ;
	print "Rules $rules_name is replaced by $replace ($link)\n";
	$kbd_option_elt{XkbRules}{help}{$rules_name} 
	  = 'Deprecated in favor of $replace' ;
	next ;
    } 


    open (LST,$file ) || die "can't open $file:$!";
    my %xkb_model_elt ;
    my %xkb_model_help ;
    my %variant_rules ;

    my $mode = '';
    while (<LST>) {
	chomp;
	s/^\s*// ;

	if (/^!\s+(\w+)/) {
	    $mode = $1;
	    #print "rules $rules_name, mode: $mode\n";
	}
	elsif (not /\w/ ){
	    # skip empty lines
	    next ;
	}
	elsif ($mode eq 'model') {
	    my ($item, $help) = split /\s+/,$_,2 ;
	    if (not defined $kbd_option_elt{XkbModel}{warp}{rules}{$rules_name}
		and defined $defaults{$mode} 
		and defined $defaults{$mode}{$rules_name}) {
		$kbd_option_elt{XkbModel}{warp}{rules}{$rules_name}
		  = { default =>  $defaults{$mode}{$rules_name} } ;
		#print "Adding default for $mode and $rules_name\n";
	    }
	    push @{ $kbd_option_elt{XkbModel}{warp}{rules}{$rules_name}{choice} }, $item ;
	    $kbd_option_elt{XkbModel}{warp}{rules}{$rules_name}{help}{$item} = $help ;
	}
	elsif ($mode eq 'layout') {
	    my ($item, $help) = split /\s+/,$_,2 ;
	    push @{$kbd_option_elt{XkbLayout}{warp}{rules}{$rules_name}{choice}}, $item ;
	    $kbd_option_elt{XkbLayout}{warp}{rules}{$rules_name}{help}{$item} = $help ;
	}
	elsif ($mode eq 'variant') {
	    my ($item, $layout, $help) = ( /([\-\w]+)(?:\s*(\w+):)?\s+(.*)/ ) ; #))
	    $layout = '__all__' unless defined $layout ;
	    push @{$variant_rules{$layout}{choice}}, $item ;
	    $variant_rules{$layout}{help}{$item} = $help ;
	}
	elsif ( $mode eq 'option' and /:/ ) {
	    my ($group, $option, $help) = (/([\w\-]+):(\w+)\s+(.*)/) ;
	    $xkb_model_elt{$group} = { type => 'leaf', value_type => 'enum' }
	      unless defined  $xkb_model_elt{$group} ;
	    push @{ $xkb_model_elt{$group}{choice} }, $option ;
	    $xkb_model_elt{$group}{help}{$option} = $help ;
        }
	elsif ( $mode eq 'option' ) {
	    my ($group, $help) = (/([\w\-]+)\s*(.*)/) ;
	    #$xkb_model_elt{$group} = { type => 'leaf', value_type => 'enum' } ;
	    #$xkb_model_help{$group} = $help  ;
	}
	else {
	    #print "skipped $_ \n";
	}
    }

    close LST;

    my @layouts = @{$kbd_option_elt{XkbLayout}{warp}{rules}{$rules_name}{choice}} ;

    my @rules = map { 
	my $layouts = $_ eq '__all__' ? \@layouts : $_ ;
	( [$rules_name, $layouts ] => $variant_rules{$_}) 
    } keys %variant_rules ;

    push @{ $kbd_option_elt{XkbVariant}{warp}{rules}} , @rules ;

    my $class_name
      = 'Xorg::InputDevice::KeyboardOptModel::'. ucfirst($rules_name) ;
    $kbd_option_elt{XkbOptions}{rules}{$rules_name}{config_class_name}
      = $class_name ;

    my $xkb_model 
      = [ 
	 [
	  name => $class_name,
	  generated_by => $generator ,
	  'element' => [ %xkb_model_elt ],
	  'description' => [ %xkb_model_help ],
	 ]
	] ;

    my $out_file = "$out_model_dir/" . ucfirst($rules_name) . ".pl" ;
    generate($build, $out_file, $xkb_model) ;
}

my $out_file = "$out_dir/KeyboardOptRules.pl" ;

my $kbd_option_rules_class =
  [
   [
    name => "Xorg::InputDevice::KeyboardOptRules",
    element => [ %kbd_option_elt ] ,
    generated_by => $generator ,
    'description'
    => [
	"XkbRules" => "specifies which XKB rules file to use for interpreting the XkbModel, XkbLayout,  XkbVariant,  and  XkbOptions settings.",

	"XkbModel" => "specifies the XKB keyboard model name.",

	"XkbLayout" => "specifies the XKB keyboard layout name. This is usually the country or language type of the keyboard.",

	"XkbVariant" => "specifies the XKB keyboard variant components. These can be used to enhance the keyboard layout details.",

	"XkbOptions" => "specifies the XKB keyboard option components. These can be used to enhance the keyboard behaviour.",
       ],
    ]
  ] ;

generate($build, $out_file, $kbd_option_rules_class) ;

$build->add_build_element('pl');
$build->create_build_script;
