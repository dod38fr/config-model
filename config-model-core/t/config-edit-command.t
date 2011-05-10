use strict ;
use warnings ;
use File::Path ;
use Probe::Perl ;

use Test::Command tests => 8;

## testing exit status

# pseudo root where config files are written by config-model
my $wr_root = 'wr_root';

# cleanup before tests
rmtree($wr_root);

my $test1 = 'popcon1' ;
my $wr_dir = $wr_root.'/'.$test1 ;
my $conf_file = "$wr_dir/etc/popularity-contest.conf" ;

my $path = Probe::Perl->find_perl_interpreter();

my $perl_cmd = $path . ' -Ilib ' .join(' ',map { "-I$_" } Probe::Perl->perl_inc());

my $oops = Test::Command->new( cmd => "$perl_cmd config-edit -root_dir $wr_dir -appli popcon -ui none PARITICIPATE=yes");

exit_cmp_ok($oops, '>',0,'missing config file detected');
stderr_like($oops, qr/unknown element/, 'check auto_read_error') ;

# put popcon data in place
my @orig = <DATA> ;


mkpath($wr_dir.'/etc', { mode => 0755 }) 
  || die "can't mkpath: $!";
open(CONF,"> $conf_file" ) || die "can't open $conf_file: $!";
print CONF @orig ;
close CONF ;

$oops = Test::Command->new( cmd => "$perl_cmd config-edit -root_dir $wr_dir -appli popcon -ui none PARITICIPATE=yes");
exit_is_num($oops, 2,'wrong parameter detected');
stderr_like($oops, qr/unknown element/, 'check unknown element') ;


my $ok = Test::Command->new( cmd => "$perl_cmd config-edit -root_dir $wr_dir -ui none -appli popcon PARTICIPATE=yes");
exit_is_num($ok, 0,'all went well');

my $search = Test::Command->new( cmd => "$perl_cmd config-edit -root_dir $wr_dir -ui none -appli popcon -search y -narrow value");
exit_is_num($search, 0,'search went well');
stdout_like($search,qr/PARTICIPATE/,"got PARTICIPATE");
stdout_like($search,qr/USEHTTP/,"got USEHTTP");

__END__
# Config file for Debian's popularity-contest package.
#
# To change this file, use:
#        dpkg-reconfigure popularity-contest

## should be removed

MY_HOSTID="aaaaaaaaaaaaaaaaaaaa"
# we participate
PARTICIPATE="yes"
USEHTTP="yes" # always http
DAY="6"

