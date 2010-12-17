package Config::Model::Debian::Dependency ;

use strict ;
use warnings ;

use base qw/Config::Model::Value/ ;

sub check {
    my $self = shift ;
    my %args = @_ > 1 ? @_ : (value => $_[0]) ;
    my $value = $args{value} ;
    my $quiet = $args{quiet} || 0 ;
    my $silent = $args{silent} || 0 ;

    
    my @error = $self->SUPER::check(%args) ;
    
    # value is one dependency, something like "perl ( >= 1.508 )"
    # or exim | mail-transport-agent or gnumach-dev [hurd-i386]
    $value =~ s/\[.*?\]//g; # remove arch conditions
    
    my @deps = split (/\s*\|\s*/,$value) ;
    foreach $dep (@deps) {
        
    }

    # see http://www.debian.org/doc/debian-policy/ch-relationships.html
    
    # errors and warnings are array ref
    
    # to get package list
    # wget -q -O - 'http://qa.debian.org/cgi-bin/madison.cgi?package=perl-doc&text=on'

    return wantarray ? @error : scalar @error ? 0 : 1 ;
}