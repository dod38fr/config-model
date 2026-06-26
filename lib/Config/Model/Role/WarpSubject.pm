package Config::Model::Role::WarpSubject;

# ABSTRACT: common methods for a warped element

use Mouse::Role;
use Mouse::Util;

use feature qw/postderef signatures/;
no warnings qw/experimental::postderef experimental::signatures/;

requires 'backup', 'allowed_warp_params';

use Log::Log4perl qw(get_logger :levels);

my $logger = get_logger("WarpSubject");

sub merge_properties($self, %raw_args) {
    my %args = %{ $self->backup // {} };
    for my $p ( $self->allowed_warp_params() ) {
        # cleanup all parameters that are handled by warp
        delete $self->{$p};

        next unless exists $raw_args{$p};

        my $new = $raw_args{$p};

        if (defined $args{$p} and ref $args{$p} eq 'HASH') {
            if (ref $new eq 'HASH') {
                for my $sub_p (keys $new->%*) {
                    $args{$p}{$sub_p} = $new->{$sub_p};
                }
            }
            else {
                Config::Model::Exception::Model->throw(
                    object => $self,
                    error  => "property $p is not a HASH ref"
                );
            }
        }
        else {
            $args{$p} = $new;
        }
    }

    return %args;
}

1;

__END__

=head1 SYNOPSIS

 package Config::Model::SomeStuff;
 use Mouse;
 with Config::Model::Role::WarpSubject

=head1 DESCRIPTION

This role enable a configuration element to become a warp master, i.e. a parameter
whose value can change the features of the configuration tree (by controlling a
warped_node) or the feature of various elements like leaf, hash ...

This roles requires C<backup> and C<allowed_warp_params> methods.

=head1 METHODS

=head2 merge_properties

Parameters: C<< ( %arguments_to_merge ) >>

Returns a hash containing a first level merge of the constructor
arguments (returned by C<backup> method) and the arguments to merge.

The merge is done only at first level where hash ref are merged (not a
deep merge), scalar and arrays are clobbered.

=cut

