# -*- cperl -*-
# $Author$
# $Date$
# $Revision$

use ExtUtils::testlib;
use Test::More tests => 8;
use Test::Memory::Cycle;
use Config::Model;

use warnings;
no warnings qw(once);

use strict;

use vars qw/$model/;

$model = Config::Model -> new (legacy => 'ignore',) ;

my $arg = shift || '' ;
my $trace = $arg =~ /t/ ? 1 : 0 ;
$::verbose          = 1 if $arg =~ /v/;
$::debug            = 1 if $arg =~ /d/;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

use Log::Log4perl qw(:easy) ;
Log::Log4perl->easy_init($arg =~ /l/ ? $TRACE: $WARN);

ok(1,"compiled");

my $inst = $model->instance (root_class_name => 'Master', 
			     model_file => 't/big_model.pm',
			     instance_name => 'test1');
ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;
ok($root,"Config root created") ;

my $step = 'std_id:ab X=Bv - std_id:bc X=Av - a_string="toto tata" '
  .'hash_a:toto=toto_value hash_a:titi=titi_value '
  .'lista=a,b,c,d olist:0 X=Av - olist:1 X=Bv - listb=b,c,d '
  .'my_check_list=toto my_reference="titi"';

ok( $root->load( step => $step, experience => 'advanced' ),
  "set up data in tree with '$step'");

my $description = $root->describe ;
$description =~ s/\s*\n/\n/g;
print "description string:\n$description" if $trace ;

my $expect = <<'EOF' ;
name         value        type         comment
std_id       <SlaveZ>     node hash    keys: "ab" "bc"
lista        a,b,c,d      list
listb        b,c,d        list
hash_a:titi  titi_value   string
hash_a:toto  toto_value   string
hash_b       [empty hash] value hash
ordered_hash [empty hash] value hash
olist        <SlaveZ>     node list    indexes: 0 1
tree_macro   [undef]      enum         choice: XY XZ mXY
warp         <SlaveY>     node
slave_y      <SlaveY>     node
string_with_def "yada yada"  string
a_uniline    "yada yada"  uniline
a_string     "toto tata"  string       mandatory
int_v        10           integer
my_check_list toto         check_list
my_reference titi         reference
EOF

is($description,$expect,"check root description ") ;

$description = $root->grab('std_id:ab')->describe();
$description =~ s/\s*\n/\n/g;
print "description string:\n$description" if $trace  ;

$expect = <<'EOF' ;
name         value        type         comment
Z            [undef]      enum         choice: Av Bv Cv
X            Bv           enum         choice: Av Bv Cv
DX           Dv           enum         choice: Av Bv Cv Dv
EOF

is($description,$expect,"check std_id:ab description ") ;

$expect = <<'EOF' ;
name         value        type         comment
std_id       <SlaveZ>     node hash    keys: "ab" "bc"
EOF


$description = $root->describe(element => 'std_id');
$description =~ s/\s*\n/\n/g;
print "description string:\n$description" if $trace  ;
is($description,$expect,"check root description of std_id") ;
memory_cycle_ok($model);
