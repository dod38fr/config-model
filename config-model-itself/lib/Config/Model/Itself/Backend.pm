package Config::Model::Itself::Backend ;

use base qw/Config::Model::Value/ ;

use strict ;

use warnings ;

sub get_choice {
  my $self = shift ;

  my @choices = $self->SUPER::get_choice ;

  #find available backends

  my $path = $INC{"Config/Model.pm"} ;
  $path =~ s!\.pm!/Backend! ;

  return @choices unless -d $path ;

  opendir(BACK,$path) || die "Can't opendir $path:$!" ;
  foreach (readdir(BACK)) {
    next unless s/\.pm// ;
    next if /Any$/ ; # Virtual class
    s!/!::!g ;
    push @choices , $_ ;
  }
  print "over get_choice: @choices\n";
  return @choices ;
}

warn "Override get_help also ?" ;

1;
