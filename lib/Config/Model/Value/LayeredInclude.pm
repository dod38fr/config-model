package Config::Model::Value::LayeredInclude;


use 5.010;
use strict;
use warnings;
use Log::Log4perl qw(get_logger :levels);

use base qw/Config::Model::Value/ ;


my $logger = get_logger("Tree::Element::Value::LayeredInclude") ;

# should we clear all layered value when include value is changed ? 
# If yes, beware of recursive includes. Clear should only be done once.

sub store_cb {
    my $self = shift ;
    my %args = @_ ;

    my ($value, $check, $silent, $notify_change, $ok, $callback)
        = @args{qw/value check silent notify_change ok callback/} ;

    my $old_value = $self->_fetch_no_check;
    
    $self->SUPER::store_cb(%args) ;
    {
        no warnings 'uninitialized' ;
        return $value if $value eq $old_value;
    }
    
    my $i = $self->instance ;
    my $already_in_layered = $i->layered ;
    
    # layered stuff here
    if (not $already_in_layered) {
        $i->layered_clear ;
        $i->layered_start ;
    }
    
    {
        no warnings 'uninitialized';
        $logger->debug("Loading layered config from $value (old_data is $old_value)") ;
    }
    
    # load included file in layered mode
    $self->root->read_config_data(
        # check => 'no',
        config_file => $value ,
        auto_create => 0, # included file must exist
    );

    if (not $already_in_layered) {
        $i->layered_stop ;
    }
    
    # test if already in layered mode -> if no, clear layered, 
    $logger->debug("Done loading layered config from $value") ;
    
    return $value ;
}

sub _check_value {
    my $self = shift ;
    my %args = @_ > 1 ? @_ : (value => $_[0]) ;
    my $value = $args{value} ;
    my $quiet = $args{quiet} || 0 ;
    my $check = $args{check} || 'yes' ;
    my $apply_fix = $args{fix} || 0 ;
    my $mode = $args{mode} || '' ;
    
    $self->SUPER::check_value(@_) ;

    # need to test that prest config file is present as the model
    # may not enforce it (when read_config auto_create is 1)
    my $layered_file = $self->instance->read_root_dir ;
    $layered_file .= $value ;
    
    my $err = $self->{error_list} ;
    
    if (not -r $layered_file) {
        push @$err,"cannot read include file $$layered_file";
    }
    
    return wantarray ? @$err : scalar @$err ? 0 : 1 ;
}
1;

# ABSTRACT: Include a sub layer configuration

__END__

=head1 SYNOPSIS

    # in a model declaration:
    'element' => [
      'include' => {
        'class' => 'Config::Model::Value::LayeredInclude',

        # usual Config::Model::Value parameters
        'type' => 'leaf',
        'value_type' => 'uniline',
        'convert' => 'lc',
        'summary' => 'Include file for cascaded configuration',
        'description' => 'To support multiple variants of ...'
      },
    ]


=head1 DESCRIPTION

This class inherits from L<Config::Model::Value>. It overrides
L<store_cb> to trigger a refresh of layered value when value is actually
changed. I.e. changing this value will reload the refered configuration
file and use its values as default value. This class was designed to
cope with L<multistrap|http://wiki.debian.org/Multistrap> configuration.


=head2 CAUTION

A configuration file can support 2 kinds of include:

=over

=item *

Layered include which sets default values like multistrap or ssh. These includes are
read-only.

=item *

Real includes like C<apache>. In this cases modified configuration items can be written to
included files.

=back

This class works only with the first type

=head1 AUTHOR

Copyright 2011,2013 Dominique Dumont <ddumont at cpan.org>

=cut
