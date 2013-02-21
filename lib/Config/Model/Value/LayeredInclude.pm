package Config::Model::Value::LayeredInclude;


use 5.010;
use strict;
use warnings;
use Log::Log4perl qw(get_logger :levels);

use base qw/Config::Model::Value/ ;

# override store to trigger a refresh of layered value when value is actually
# changed. 

# should we clear all layered value when include value is changed ? 
# If yes, beware of recursive includes. Clear should only be done once.

# beware: 2 kind of includes: shadow include (set default values like 
# multistrap or ssh, i.e. read-only includes) and real includes (apache,
# i.e. may write back in included files)

# this class deals only with the first type

my $logger = get_logger("Tree::Element::Value::LayeredInclude") ;

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


__END__

=pod

=head1 NAME

Config::Model::Value::LayeredInclude - Include a sub layer configuration

=head1 SYNOPSIS

  my $object = Config::Model::Value::Include->new(
      foo  => 'bar',
      flag => 1,
  );
  
  $object->dummy;

=head1 DESCRIPTION

The author was too lazy to write a description.

=head1 METHODS

=head2 new

  my $object = Config::Model::Value::Include->new(
      foo => 'bar',
  );

The C<new> constructor lets you create a new B<Config::Model::Value::Include> object.

So no big surprises there...

Returns a new B<Config::Model::Value::Include> or dies on error.

=head2 dummy

This method does something... apparently.

=head1 SUPPORT

No support is available

=head1 AUTHOR

Copyright 2011 Anonymous.

=cut
