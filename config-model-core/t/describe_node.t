# -*- cperl -*-
# $Author: ddumont $
# $Date: 2006-07-19 12:25:23 $
# $Name: not supported by cvs2svn $
# $Revision: 1.1 $

use ExtUtils::testlib;
use Test::More tests => 6;
use Config::Model;

use warnings;
no warnings qw(once);

use strict;

use vars qw/$model/;

$model = Config::Model -> new ;

my $arg = shift || '' ;
my $trace = $arg =~ /t/ ? 1 : 0 ;
$::verbose          = 1 if $arg =~ /v/;
$::debug            = 1 if $arg =~ /d/;
Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

ok(1,"compiled");

my $inst = $model->instance (root_class_name => 'Master', 
			     model_file => 't/big_model.pm',
			     instance_name => 'test1');
ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;
ok($root,"Config root created") ;

my $step = 'std_id:ab X=Bv - std_id:bc X=Av - a_string="toto tata" '
  .'hash_a:toto=toto_value hash_a:titi=titi_value '
  .'lista=a,b,c,d olist:0 X=Av - olist:1 X=Bv - listb=b,c,d';

ok( $root->load( step => $step, permission => 'intermediate' ),
  "set up data in tree with '$step'");

my $description = $root->describe ;

print "description string:\n$description" if $trace ;

my $expect = <<'EOF' ;
name         value        type         comment                            
std_id       <SlaveZ>     node hash    keys: ab bc                        
lista        a,b,c,d      list                                            
listb        b,c,d        list                                            
hash_a:titi  titi_value   string                                          
hash_a:toto  toto_value   string                                          
hash_b       [empty hash] value hash                                      
olist        <SlaveZ>     node list    keys: 0 1                          
tree_macro   [undef]      enum         choice: XY XZ mXY                  
warp         <SlaveY>     node                                            
string_with_def "yada yada"  string                                          
a_string     "toto tata"  string       mandatory                          
int_v        10           integer                                         
EOF

is($description,$expect,"check root description ") ;

$description = $root->grab('std_id:ab')->describe();
print "description string:\n$description" if $trace  ;

$expect = <<'EOF' ;
name         value        type         comment                            
X            Bv           enum         choice: Av Bv Cv                   
Z            [undef]      enum         choice: Av Bv Cv                   
DX           Dv           enum         choice: Av Bv Cv Dv                
EOF

is($description,$expect,"check std_id:ab description ") ;


