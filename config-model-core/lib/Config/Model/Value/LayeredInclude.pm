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

sub store {
    my $self = shift ;
    my %args = @_ == 1 ? (value => $_[0]) 
             : @_ == 3 ? ( 'value' , @_ ) 
             : @_ ;

    my $old_data = $self->{data} ;
    
    my $new_data = $self->SUPER::store(%args) ; 
    
    {
        no warnings 'uninitialized' ;
        return $new_data if $new_data eq $old_data;   
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
        $logger->debug("Loading layered config from $new_data (old_data is $old_data)") ;
    }
    
    # load included file in layered mode
    $self->root->read_config_data(check => 'no', config_file => $new_data );

    if (not $already_in_layered) {
        $i->layered_stop ;
    }
    
    # test if already in layered mode -> if no, clear layered, 
    $logger->debug("Done loading layered config from $new_data") ;
    
    return $new_data ;
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
