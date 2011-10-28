#    Copyright (c) 2007-2011 Dominique Dumont.
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

require 5.008 ;

use warnings FATAL => qw(all) ;
use strict ;

use Data::Dumper ;

use Config ;
use Cwd ;

sub generate {
    my $builder = shift ;
    my $out_file = shift ;
    my $data = shift ;
    my $pad = shift || '';
    print $pad,"Generating $out_file\n";
    open (KBDOPT, "> $out_file") || die "can't open $out_file to write:$!" ;
    print KBDOPT "# Generated file. Do not edit\n\n" ;

    # use local to avoid breaking Module::Build > 0.2808_01
    local $Data::Dumper::Terse = 1 ;
    # see http://groups.google.com/group/perl.module.build/browse_thread/thread/c8065052b2e0d741

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
   dist_author   => "Dominique Dumont (ddumont at cpan dot org)",
   dist_abstract => "Xorg configuration editor and validator",

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

   add_to_cleanup => [qw/wr_root/] 
  );


my $etc_xorg_dir ;
my @try_xorg_dir = qw!/etc/X11 /usr/X11/lib/X11 /usr/X11R6/lib/X11! ;
foreach my $x_conf_dir (@try_xorg_dir) {
    next unless -d $x_conf_dir ;
    $etc_xorg_dir = $x_conf_dir ;
    last;
}

unless (defined $etc_xorg_dir) {
    warn "Cannot find xorg conf in @try_xorg_dir. Is Xorg installed ?\n";
    goto FALLBACK ;
}

print "Note: xorg.conf is expected to be located in $etc_xorg_dir\n";

my $generator = "Config::Model Build.PL" ;

my $model_dir = "lib/Config/Model/models";

my $xorg_config_file_model = [ 
    [
        name => 'Xorg::ConfigDir',
        class_description => "Class used to tune location of xorg.conf which is not always in /etc/X11.",
        generated_by => $generator ,
        read_config => [ 
            { 
                backend => 'Xorg',
                file => 'xorg.conf',    
                config_dir => $etc_xorg_dir ,
                auto_create => 1,
            }
        ] ,
    ]
] ;

generate($build, "$model_dir/Xorg/ConfigDir.pl", $xorg_config_file_model) ;

my $out_dir = "$model_dir/Xorg/InputDevice" ;
my $out_model_dir = "$out_dir/KeyboardOptModel";

mkdir $out_model_dir, 0755 unless -d $out_model_dir ;

# how to choose a reasonable default value for XkbRules ? Does it
# depend on the OS or just on available model ?
my $xkb_rules_elt = {
		     type => 'leaf',
		     value_type  => 'enum',
		     choice => [] ,
		     # fails on OpenBSD
		     # default => 'base',
		     help => { xfree86 => 'Deprecated in favor of xorg' },
		    } ;

my $xkb_model_elt = {
		     type => 'leaf',
		     value_type  => 'enum',
		     warp => {
			      follow => { r => '- XkbRules' },
			      rules => [] ,
			     },
		    } ;

# See /etc/X11/xkb/rules/xorg.lst

my $xkb_layout_elt = {
		      type => 'leaf',
		      value_type  => 'enum',
		      default => 'us',
		      warp => {
			       follow => { r => '- XkbRules' },
			       rules => [] ,
			      },
		     };

my $xkb_variant_elt = {
		       type => 'leaf',
		       value_type  => 'enum',
		       warp => { follow => { r => '- XkbRules', 
					     l => '- XkbLayout' } ,
				 rules => [] ,
			       }
		      };

# needs to be refined ...
my $xkb_options_elt = {
		       type => 'warped_node',
		       follow => { r => '- XkbRules' },
		       rules => [ ] ,
		      };

# use a list to ensure the order of the options
my @kbd_option_elt 
  = (
     XkbRules   => $xkb_rules_elt,
     XkbModel   => $xkb_model_elt,
     XkbLayout  => $xkb_layout_elt,
     XkbVariant => $xkb_variant_elt ,
     XkbOptions => $xkb_options_elt, 
    ) ;

my @try_xkb_dirs = ( "/usr/share/X11/xkb/rules" ,   # Linux path
		     "/usr/X11/lib/X11/xkb/rules/", # tentative path for Solaris
		     "/usr/X11R6/lib/X11/xkb/rules/", # tentative path for Solaris
		     "$etc_xorg_dir/xkb/rules"      # old path (XFree86 ?)
		   ) ;

my $keyboard_conf_dir ;

foreach (@try_xkb_dirs) {
  if ( -d $_ ) {
    $keyboard_conf_dir = $_ ;
    last ;
  }
}

if (not defined $keyboard_conf_dir) {
    warn "Cannot find xorg keyboard conf directory. Is Xorg installed ?\n";
    goto FALLBACK ;
}

my @lst_files = glob("$keyboard_conf_dir/*.lst") ;

if (not scalar @lst_files) {
    warn "Cannot find xorg keyboard conf in @try_xkb_dirs. Is Xorg installed ?\n";
    goto FALLBACK ;
}

# scan lst file which are link and construct the relevant warp rules
print "\nStage 1: look for linked lst files\n";
my %warp_rule ;
foreach my $file (@lst_files) {
    my ($rules_name) = ($file =~ m!/([\-\w]+)\.lst!) ;
    print "  Pre-scan rule $rules_name from $file\n";

    if (-l $file) {
	my $link = readlink($file) ;
	my ($replace) =  ($link =~ m!([\-\w]+)\.lst!) ;
	print "    Rules $rules_name is replaced by $replace ",
	  "($rules_name.lst is symlinked to $link)\n";
	$warp_rule{$replace} = qq!\$r eq "$replace"! 
	  unless defined $warp_rule{$replace};
	$warp_rule{$replace} .= qq! or \$r eq "$rules_name"! ;
	$xkb_rules_elt->{help}{$rules_name} 
	  = 'Deprecated in favor of $replace' ;
	next ;
    } 
}

print "\nStage 2: scan non-linked lst files\n";
# now really scan non-link files
foreach my $file (@lst_files) {
    my ($rules_name) = ($file =~ m!/([\-\w]+)\.lst!) ;
    print "  Scanning rule $rules_name from $file\n";
    push @{$xkb_rules_elt->{choice}}, $rules_name ;

    if (-l $file) {
	print "    Rules $rules_name skipped (link)\n";
	next ;
    } 

    my $warp_rule = $warp_rule{$rules_name} || qq!\$r eq "$rules_name"! ;

    open (LST,$file ) || die "can't open $file:$!";
    my %xkb_model_elt ;
    my %xkb_model_help ;
    my %variant_rules ;

    my %xkb_model_warp_effect  ;
    my %xkb_layout_warp_effect  ;

    my $mode = '';
    while (<LST>) {
	chomp;
	s/^\s*// ;

	if (/^!\s+(\w+)/) {
	    $mode = $1;
	    #print "rules $rules_name, mode: $mode (warp_rule: $warp_rule)\n";
	}
	elsif (not /\w/ ){
	    # skip empty lines
	    next ;
	}
	elsif ($mode eq 'model') {
	    my ($item, $help) = split /\s+/,$_,2 ;
	    push @{ $xkb_model_warp_effect{choice} }, $item ;
	    $xkb_model_warp_effect{help}{$item} = $help ;
	}
	elsif ($mode eq 'layout') {
	    my ($item, $help) = split /\s+/,$_,2 ;
	    push @{$xkb_layout_warp_effect{choice}}, $item ;
	    $xkb_layout_warp_effect{help}{$item} = $help ;
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


    my $all_layout_rule = join ' and ', map { qq!\$l eq "$_"! } @{$xkb_layout_warp_effect{choice}} ;

    my @rules = map { 
	my $layout_rule = $_ eq '__all__' ? $all_layout_rule : qq!"\$l eq $_"! ;
	( qq!( $warp_rule ) and $layout_rule ! => $variant_rules{$_}) ;
    } keys %variant_rules ;

    push @{ $xkb_variant_elt->{warp}{rules}} , @rules ;
    my $class_name
      = 'Xorg::InputDevice::KeyboardOptModel::'. ucfirst($rules_name) ;

    push @{$xkb_options_elt->{rules} } ,
         $warp_rule => { config_class_name => $class_name } ;

    push @{$xkb_model_elt->{warp}{rules}},   $warp_rule, \%xkb_model_warp_effect ; 
    push @{$xkb_layout_elt->{warp}{rules}} , $warp_rule, \%xkb_layout_warp_effect ;

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
    generate($build, $out_file, $xkb_model,'    ') ;
}

my $out_file = "$out_dir/KeyboardOptRules.pl" ;

my $kbd_option_rules_class =
  [
   [
    name => "Xorg::InputDevice::KeyboardOptRules",
    element => \@kbd_option_elt ,
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

print "\nStage 3: generate Keyboart option rules\n";

generate($build, $out_file, $kbd_option_rules_class,'  ') ;

print "\n";

$build->add_build_element('pl');
$build->create_build_script;

exit ;

FALLBACK:

warn "Fallback: Installing some models for Linux. This may not work ",
  "properly on your system\n";

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
