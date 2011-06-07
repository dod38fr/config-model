#!/usr/bin/perl

use strict;
use warnings;

use Config::Model;
use Config::Model::Itself;
use Config::Model::Backend::IniFile;
use IO::File;
use IO::String;
use Log::Log4perl qw(:easy);
use 5.10.0;

my $log4perl_user_conf_file = $ENV{HOME} . '/.log4config-model';

Log::Log4perl::init($log4perl_user_conf_file);

my $model = Config::Model->new();

# load LCDd.conf in a dummy model to benefit from INI parser.
$model->create_config_class(
    name   => 'Dummy::Class',
    accept => [ '.*' => {qw/type leaf value_type uniline/}, ],
);

$model->create_config_class(
    name   => 'Dummy',
    accept => [ '.*' => {qw/type node config_class_name Dummy::Class/}, ],
);

my $dummy_inst = $model->instance(
    instance_name   => 'dummy',
    root_class_name => 'Dummy',
);

my $dummy = $dummy_inst->config_root;

$dummy->init;

# read file myself as some pre-process is required
my $ini_backend = Config::Model::Backend::IniFile->new( node => $dummy );

my $lcd_file = IO::File->new('examples/lcdproc/LCDd.conf');
my @lines    = $lcd_file->getlines;

# restore commented lines
foreach (@lines) { s/^#(\w+=)/$1/ }
my $ioh = IO::String->new( join( '', @lines ) );

$ini_backend->read( io_handle => $ioh );

# load Config::Model model
my $meta_inst = $model->instance(
    root_class_name => 'Itself::Model',
    instance_name   => 'meta_model',
);

my $meta_root = $meta_inst->config_root;

# read dummy file to create model_object
my $extra_description = "Model information extracted from template /etc/LCDd.conf"
    ."\n\n=head1 BUGS\n\nThis model does not support to load several drivers. Loading "
    ."several drivers is probably a marginal case. Please complain to the author if this "
    ."assumption is false" ;
    

$meta_root->grab("class:LCDd class_description")->store( $dummy->annotation );
$meta_root->load( qq!class:LCDd class_description.="\n\n$extra_description"! );

$meta_root->load(
qq!class:LCDd 
    copyright:0="2011, Dominique Dumont" 
    copyright:1="1999-2011, William Ferrell and others" 
    license="GPL-2"
    element:server -
    element:menu -
    read_config:0 
       backend=ini_file 
       config_dir="/etc" 
       file="LCDd.conf"
!
);

my @ini_classes = $dummy->get_element_name;
print "LCDd ini_classes: @ini_classes\n";

my %def;
%def = (
    "LCDd::server" => {
        Driver => sub {
            my ( $class, $elt, $info, $ini_v ) = @_;
            my $load = qq!class:"$class" element:$elt type=leaf value_type=enum !;
            my @drivers = split /\W+/, $info;
            while ( @drivers and ( shift @drivers ) !~ /supported/ ) { }
            $load .= 'choice=' . join( ',', @drivers ) . ' ';

            #print $load; exit;
            return $load;
        },
        DriverPath => sub {
            my ( $class, $elt, $info, $ini_v ) = @_;
            return $def{_default_}->(@_) . q! match="/$" !;
        },
        WaitTime    => $def{LCDd}{Port},
        ReportLevel => $def{LCDd}{Port},
        Port        => sub {
            my ( $class, $elt, $info, $ini_v ) = @_;
            return $def{_default_}->( @_, 'integer' );
        },
        GoodBye => $def{LCDd}{Hello},
        Hello   => sub {
            my ( $class, $elt, $info, $ini_v ) = @_;
            return qq(class:"$class" element:$elt type=list 
               cargo type=leaf value_type=uniline - 
               default_with_init:0="    $elt" default_with_init:1="    LCDproc!" );
        },
    },
    _default_ => sub {
        my ( $class, $elt, $ini_note, $ini_v, $value_type ) = @_;
        my $load = qq!class:"$class" element:$elt type=leaf !;
        $value_type ||= 'uniline';

        my $info = $ini_note =~ /\[(.*)\]/ ? $1 : '';
        $info =~ s/\s+//g;
        $load .=
            $info =~ /legal:(\d+)-(\d+)/ ? " value_type=integer min=$1 max=$2"
          : $info =~ /legal:([\w\,]+)/   ? " value_type=enum choice=$1"
          :                                " value_type=$value_type";
        if ( $info =~ /default:(\w+)/ ) {
            $load .= qq! upstream_default="$1"! if length($1);
        }
        else {
            $ini_v =~ s/^"//g;
            $ini_v =~ s/"$//g;
            $load .= qq! default="$ini_v"! if length($ini_v);
        }
        return $load;
    }
);

# handle server and menu elements
foreach my $item (@ini_classes) {
    my $ini_obj = $dummy->grab($item);
    my $class = "LCDd::$item";
    
    # create config class in case there's no parameter in INI file
    $meta_root->load(qq!class:"LCDd::$item"!);
    
    foreach my $elt ( $ini_obj->get_element_name ) {
        my $ini_v    = $ini_obj->grab_value($elt);
        my $ini_note = $ini_obj->grab($elt)->annotation;
        $ini_note =~ s/"/'/g;
        $ini_v    =~ s/^"//g;
        $ini_v    =~ s/"$//g;

        my $sub = $def{$class}{$elt} || $def{_default_};
        my $load = $sub->( $class, $elt, $ini_note, $ini_v );

        $load .= qq! description="$ini_note"! if length($ini_note);
        print "Class load:$load\n";
        $meta_root->load($load);
    }
    
    if ($item ne 'server' and $item ne 'menu') {
        my $load = qq!class:LCDd element:$item type=warped_node
            config_class_name="LCDd::$item" level=hidden
            follow:selected="- server Driver"
            rules:"\$selected eq '$item'" level=normal! ;
        print "Class load:$load\n";
        $meta_root->load($load) ;
    }
}

say "Creating LCDs root elements (server and menu)";

$meta_root->load(qq!
  class:LCDd  
    element:server  type=node config_class_name="LCDd::server" -
    element:menu    type=node config_class_name="LCDd::menu" -
!);

#print $meta_root->dump_tree ;

# Itself constructor returns an object to read or write the data
# structure containing the model to be edited
my $rw_obj = Config::Model::Itself->new( model_object => $meta_root );
$rw_obj->write_all( model_dir => 'lib/Config/Model/models/' );
say "Done";
