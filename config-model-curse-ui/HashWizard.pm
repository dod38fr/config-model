# $Author: ddumont $
# $Date: 2007-05-09 12:19:10 $
# $Name: not supported by cvs2svn $
# $Revision: 1.1 $

package HPOC::Config::HashWizard ;
require Exporter;
use strict ;
use HPOC::Config::Exception ;
use Carp;
use warnings ;
use Error qw(:try);

use Curses::UI ;
use base qw/Curses::UI::Common Curses::UI::Window/;

sub new ()
{
  my $class = shift;
 
  my $self = $class->SUPER::new(%args);
 
  return bless $self, $class;
}
