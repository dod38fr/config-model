# -*- cperl -*-

use ExtUtils::testlib;
use Test::More tests => 21;
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
			     model_file => 't/dump_load_model.pm',
			     instance_name => 'test1');
ok($inst,"created dummy instance") ;

my $root = $inst -> config_root ;
ok($root,"Config root created") ;

$inst->preset_start ;

$root->fetch_element(name => 'hidden_string', accept_hidden => 1)->store('hidden value');

my $step = 'std_id:ab X=Bv '
  .'! lista=a,b listb=b ' ;
ok( $root->load( step => $step, experience => 'advanced' ),
    "preset data in tree with '$step'");

$inst->preset_stop ;

$step = 'std_id:ab X=Bv - std_id:bc X=Av - std_id:"b d " X=Av '
  .'- a_string="toto \"titi\" tata" another_string="foobar" '
  .'lista=a,b,c,d olist:0 X=Av - olist:1 X=Bv - listb=b,"c c2",d '
  . '! hash_a:X2=x hash_a:Y2=xy  hash_b:X3=xy my_check_list=X2,X3' ;
ok( $root->load( step => $step, experience => 'advanced' ),
  "set up data in tree");

is_deeply([ sort $root->fetch_element('std_id')->get_all_indexes ],
	  ['ab','b d ','bc'], "check std_id keys" ) ;

is_deeply([ sort $root->fetch_element('lista')->fetch_all_values(mode => 'custom') ],
	  [qw/c d/], "check lista custom values" ) ;

my $cds = $root->dump_tree;

print "cds string:\n$cds" if $trace ;

my $expect = <<'EOF' ;
std_id:ab -
std_id:"b d "
  X=Av -
std_id:bc
  X=Av -
lista=c,d
listb="c c2",d
hash_a:X2=x
hash_a:Y2=xy
hash_b:X3=xy
olist:0
  X=Av -
olist:1
  X=Bv -
a_string="toto \"titi\" tata"
another_string=foobar
my_check_list=X2,X3 -
EOF

$cds =~ s/\s+\n/\n/g;
is_deeply( [split /\n/,$cds], [split /\n/,$expect], 
	   "check dump of only customized values ") ;

$cds = $root->dump_tree( full_dump => 1 );
print "cds string:\n$cds" if $trace  ;

$expect = <<'EOF' ;
std_id:ab
  X=Bv
  DX=Dv -
std_id:"b d "
  X=Av
  DX=Dv -
std_id:bc
  X=Av
  DX=Dv -
lista=a,b,c,d
listb=b,"c c2",d
hash_a:X2=x
hash_a:Y2=xy
hash_b:X3=xy
olist:0
  X=Av
  DX=Dv -
olist:1
  X=Bv
  DX=Dv -
string_with_def="yada yada"
a_uniline="yada yada"
a_string="toto \"titi\" tata"
another_string=foobar
int_v=10
my_check_list=X2,X3 -
EOF

$cds =~ s/\s+\n/\n/g;
is_deeply( [split /\n/,$cds], [split /\n/,$expect], 
	   "check dump of all values ") ;

my $listb = $root->fetch_element('listb');
$listb->clear ;

$cds = $root->dump_tree( full_dump => 1 );
print "cds string:\n$cds" if $trace  ;

$expect = <<'EOF' ;
std_id:ab
  X=Bv
  DX=Dv -
std_id:"b d "
  X=Av
  DX=Dv -
std_id:bc
  X=Av
  DX=Dv -
lista=a,b,c,d
hash_a:X2=x
hash_a:Y2=xy
hash_b:X3=xy
olist:0
  X=Av
  DX=Dv -
olist:1
  X=Bv
  DX=Dv -
string_with_def="yada yada"
a_uniline="yada yada"
a_string="toto \"titi\" tata"
another_string=foobar
int_v=10
my_check_list=X2,X3 -
EOF

$cds =~ s/\s+\n/\n/g;
is_deeply( [split /\n/,$cds], [split /\n/,$expect], 
	   "check dump of all values after listb is cleared") ;


# check empty strings

my $a_s = $root->fetch_element('a_string');
$a_s->store("") ;

$expect = <<'EOF' ;
std_id:ab
  X=Bv
  DX=Dv -
std_id:"b d "
  X=Av
  DX=Dv -
std_id:bc
  X=Av
  DX=Dv -
lista=a,b,c,d
hash_a:X2=x
hash_a:Y2=xy
hash_b:X3=xy
olist:0
  X=Av
  DX=Dv -
olist:1
  X=Bv
  DX=Dv -
string_with_def="yada yada"
a_uniline="yada yada"
a_string=""
another_string=foobar
int_v=10
my_check_list=X2,X3 -
EOF

$cds = $root->dump_tree( full_dump => 1 );
print "cds string:\n$cds" if $trace  ;

$cds =~ s/\s+\n/\n/g;
is_deeply( [split /\n/,$cds], [split /\n/,$expect], 
	   "check dump of all values after a_string is set to ''") ;

# check preset values

$cds = $root->dump_tree( mode => 'preset' );
print "cds string:\n$cds" if $trace  ;

$expect = <<'EOF' ;
std_id:ab
  X=Bv -
std_id:"b d " -
std_id:bc -
lista=a,b
olist:0 -
olist:1 - -
EOF

$cds =~ s/\s+\n/\n/g;
is_deeply( [split /\n/,$cds], [split /\n/,$expect], 
	   "check dump of all preset values") ;

# shake warp stuff
my $tm = $root -> fetch_element('tree_macro') ;
map { $tm->store($_);} qw/XY XZ mXY XY mXY XZ/;

$cds = $root->dump_tree( full_dump => 1 ,skip_auto_write => 'cds_file');
print "cds string:\n$cds" if $trace  ;

like($cds,qr/hidden value/,"check that hidden value is shown (macro=XZ)") ;


# check that list of undef is not shown
map { $listb->fetch_with_id($_)->store(undef) } (0 .. 3);

$cds = $root->dump_tree( full_dump => 1 );
print "Empty listb dump:\n$cds" if $trace  ;

unlike($cds,qr/listb/,"check that listb containing undef values is not shown") ;

# annotation tests

my $root2 = $model->instance (root_class_name => 'Master', 
			      instance_name => 'test2') -> config_root ;

$step = ' std_id:ab#std_id_ab_note 
                                    X=Bv X#std_id_ab_X_note 
      - std_id#std_id_note std_id:bc X=Av X#std_id_bc_X_note '
  .'- a_string="toto \"titi\" tata" a_string#a_string_note another_string="foobar"'
  .'lista#lista_note lista=a,b,c,d lista:1#lista_1_note olist#o_list_note olist:0#olist_0_note X=Av - olist:1#olist1_c X=Bv - listb=b,"c c2",d '
  . '! hash_a:X2=x#hash_a_X2 hash_a:Y2=xy#"hash_a Y2 note"  hash_b:X3=xy#hash_b_X3
     my_check_list=X2,X3 plain_object#"plain comment" aa2=aa2_value' ;
ok( $root2->load( step => $step, experience => 'advanced' ),
  "set up data in tree annotation");

is($root2->fetch_element('std_id')->annotation,'std_id_note',"check annotation for std_id");
is($root2->grab('std_id:ab')->annotation,'std_id_ab_note',"check annotation for std_id:ab");
is($root2->grab('olist:0')->annotation,'olist_0_note',"check annotation for olist:0");

my $expect_count = scalar grep {/#/} split //, $step ;

$cds = $root2->dump_tree( full_dump => 1 );
print "Dump with annotations:\n$cds" if $trace  ;

is( (scalar grep {/#/} split //,$cds) ,$expect_count ,
  "check that $expect_count annotations are found");

my $root3 = $model->instance (root_class_name => 'Master', 
			      instance_name => 'test3')
  -> config_root ;

ok($root3->load ( step => $cds, experience => 'advanced' ),
   "set up data in tree with dumped data+annotation");

my $cds2 = $root3->dump_tree( full_dump => 1 );
print "Dump second instance with annotations:\n$cds2" if $trace  ;

is($cds2,$cds,"check both dumps") ;
memory_cycle_ok($model);
