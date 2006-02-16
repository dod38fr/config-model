# -*- cperl -*-
# $Author: ddumont $
# $Date: 2006-02-16 13:09:43 $
# $Name: not supported by cvs2svn $
# $Revision: 1.3 $

use ExtUtils::testlib;
use Test::More tests => 6;
use Config::Model;

use warnings;
no warnings qw(once);

use strict;

use vars qw/$model/;

$model = Config::Model -> new ;

my $file = 't/big_model.pm';

my $return ;
unless ($return = do $file) {
    warn "couldn't parse $file: $@" if $@;
    warn "couldn't do $file: $!"    unless defined $return;
    warn "couldn't run $file"       unless $return;
}

my $arg = shift || '' ;
my $trace = $arg =~ /t/ ? 1 : 0 ;
$::verbose          = 1 if $arg =~ /v/;
$::debug            = 1 if $arg =~ /d/;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

ok(1,"compiled");

my $inst = $model->instance (root_class_name => 'Master', 
				 instance_name => 'test1');
ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;
ok($root,"Config root created") ;

my $step = 'std_id:ab X=Bv - std_id:bc X=Av - a_string="toto tata"';
ok( $root->load( step => $step, permission => 'intermediate' ),
  "set up data in tree with '$step'");

my $dts = $root->dump_tree;

print "dts string:\n$dts" if $trace ;

my $expect = <<'EOF' ;
std_id:ab
  X=Bv -
std_id:bc
  X=Av -
warp
  sub_slave
    sub_slave - - -
a_string="toto tata" -
EOF

is($dts,$expect,"check dump of only customized values ") ;

$dts = $root->dump_tree( full_dump => 1 );
print "dts string:\n$dts" if $trace  ;

$expect = <<'EOF' ;
std_id:ab
  X=Bv
  DX=Dv -
std_id:bc
  X=Av
  DX=Dv -
warp
  sub_slave
    sub_slave - - -
string_with_def="yada yada"
a_string="toto tata"
int_v=10 -
EOF

is($dts,$expect,"check dump of all values ") ;


