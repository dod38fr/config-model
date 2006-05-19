# -*- cperl -*-
# $Author: ddumont $
# $Date: 2006-05-19 13:28:00 $
# $Name: not supported by cvs2svn $
# $Revision: 1.2 $

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

my $step = 'std_id:ab X=Bv - std_id:bc X=Av - a_string="toto tata" '
  .'lista=a,b,c,d olist:0 X=Av - olist:1 X=Bv - listb=b,c,d';
ok( $root->load( step => $step, permission => 'intermediate' ),
  "set up data in tree with '$step'");

my $report = $root->report;

print "report string:\n$report" if $trace ;

my $expect = <<'EOF' ;
std_id:ab X = Bv

std_id:ab DX = Dv

std_id:bc X = Av

std_id:bc DX = Dv

  lista:0 = a

  lista:1 = b

  lista:2 = c

  lista:3 = d

  listb:0 = b

  listb:1 = c

  listb:2 = d

olist:0 X = Av

olist:0 DX = Dv

olist:1 X = Bv

olist:1 DX = Dv

 string_with_def = "yada yada"

 a_string = "toto tata"

 int_v = 10
EOF

is($report,$expect,"check dump of only customized values ") ;

$report = $root->audit();
print "audit string:\n$report" if $trace  ;

$expect = <<'EOF' ;
std_id:ab X = Bv

std_id:bc X = Av

  lista:0 = a

  lista:1 = b

  lista:2 = c

  lista:3 = d

  listb:0 = b

  listb:1 = c

  listb:2 = d

olist:0 X = Av

olist:1 X = Bv

 a_string = "toto tata"
EOF

is($report,$expect,"check dump of all values ") ;


