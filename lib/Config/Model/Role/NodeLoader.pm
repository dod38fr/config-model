package Config::Model::Role::NodeLoader;

# ABSTRACT: Load Node element in configuration tree

use Mouse::Role;
use strict;
use warnings;

use Mouse::Util;
use Log::Log4perl qw(get_logger :levels);

my $load_logger = get_logger("TreeLoad");

sub load_node {
    my ($self, %params) = @_ ;

    my $config_class_name = $params{config_class_name};
    my $config_class =  $self->config_model->get_model($config_class_name) ;
    my $node_class = $config_class->{class} || 'Config::Model::Node';
    $load_logger->info("Loading $config_class_name ". $self->location . " with $node_class");
    Mouse::Util::load_class($node_class);

    return $node_class->new(%params) ;
}

__END__

=head1 SYNOPSIS

 $self->load_node( config_class_name => "...", %other_args);

=head1 DESCRIPTION

Role used to load a node element using L<Config::Model::Node> (default behavior).

If the config class overrides the default implementation, ( C<class> parameter ), the
override class is loaded and used to create the node.

=head1 METHODS

=head2 load_node

Creates a node object using all the named parameters passed to load_node. One of these
parameter must be C<config_class_name>


=cut

