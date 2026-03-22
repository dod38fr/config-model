use Module::Build;

use warnings FATAL => qw(all);
use strict;

require v5.20 ;

# check that pod docs are up-to-date. This is redundant with the work done by
# dzil, but enables re-building the docs downstream.
# Use $^X in there as requested in 
# https://rt.cpan.org/Public/Bug/Display.html?id=74891
my $class = Module::Build->subclass(
    class => "Module::Build::Custom",
    code => <<'SUBCLASS' );

sub ACTION_build {
    my $self = shift;
    # below requires Config::Model 2.062
    system ($^X, qw!-I lib -MConfig::Model::Utils::GenClassPod -e gen_class_pod();!) == 0
                    or die "gen-class-pod failed: $?";
    $self->SUPER::ACTION_build;
}
SUBCLASS


my @version_info = @ARGV ? ( dist_version => $ARGV[0] ) : ();

my %appli_files = map { ( $_, $_ ) } glob("lib/Config/Model/*.d/*");

my $build = $class->new(
    module_name => 'Config::Model',
    @version_info,
    license       => 'lgpl',
    appli_files   => \%appli_files,
    dist_abstract => 'Describe, edit and validate configuration data',
    dist_author   => 'Dominique Dumont (ddumont at cpan dot org)',

##{ $plugin->get_prereqs ##}

    add_to_cleanup => [ qw/wr_root wr_root_p/ ],
);

$build->add_build_element('pl');
$build->add_build_element('conf');
$build->add_build_element('appli');

$build->create_build_script;
