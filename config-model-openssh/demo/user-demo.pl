#!/usr/bin/perl

use feature ":5.10" ;
use strict;
use warnings;

use Text::Wrap ;
use File::Path qw(make_path remove_tree);
use lib '../lib' ;

sub go_on {
    print "continue (Y/n/q)?";
    my $ans =  <STDIN>;
    exit if $ans =~ /^q/i;
    return if $ans =~ /^n/i ;
}

sub pause {
    print "Done.\nHit return to continue ... ";
    my $ans =  <STDIN>;
    print "\n";
}

sub my_system {
    my $run = shift ;
    my $show = shift || 0 ;
    print "Will run: $run\n" if $show ;
    go_on ;
    print '\/ ' x 15,"\n";
    system($run) ;
    print '/\ ' x 15,"\n";
    pause ;
}

print wrap('','',
	   "This program will provide a short demo of the configuration",
	   "upgrade feature of Config::Model seen from user's point of view.\n");

remove_tree('etc','lib') ;

make_path('etc/ssh') ;

print "Creating dummy config file\n";
open(CONF,">etc/ssh/sshd_config") ;
print CONF << "EOC" ;
# dummy config made for demo
HostKey              /etc/ssh/ssh_host_key

KeepAlive   no

# another comment
IgnoreRhosts         no
EOC

close CONF ;

my $pid = fork ;
if (not $pid) {
    # child
    die "Cannot fork: $!" unless defined $pid ;
    exec ("xterm -e watch -n 1 cat etc/ssh/sshd_config") ;
}

print "Forked terminal with pid $pid\n";

$SIG{KILL} = sub { kill "QUIT",$pid } ;

die "Must be run in demo directory\n" unless -d "../lib" ;

print "Copying ssh model\n\n\n";
make_path('lib/Config/Model/') ;
foreach my $inc (@INC) {
    my $model_path = "$inc/Config/Model/models" ;
    if (-d "$model_path/Sshd") {
        print "Copying model from $model_path\n" ;
        # required to be able to modify the model for the demo
        system("cp -r $model_path lib/Config/Model/") ; 
        last;
    }
}

my $postinst = "perl -I../lib -S config-edit -model Sshd -model_dir lib/Config/Model/models "
	 . "-root_dir . -ui none  -save";

print "Upstream changelog: KeepAlive is changed to TCPKeepAlive\n";
print "User file is updated by package posinst...\n";
my_system($postinst) ;

print "Changing model to reflect maintainer's work. Please wait ..." ;
system("perl -I../lib -S config-model-edit -model Sshd -save ".
	  qq!class:Sshd element:PermitRootLogin default=no upstream_default~!) ;
print "done\n\n";

print "Maintainer changelog: new policy, PermitRootLogin should be set to 'no'\n";
print "Package upgrade triggers same postinst script\n";
my_system($postinst) ;

print "Changing model to reflect maintainer's work. Please wait ..." ;
system("perl -I../lib -S config-model-edit -model Sshd -save ".
	  qq!class:Sshd element:Ciphers !.
	  qq!default_list=aes128-cbc,aes128-ctr,aes192-cbc,aes192-ctr,aes256-cbc,aes256-ctr!) ;
print "done\n\n";

print "Maintainer changelog: reduced default cipher list...\n";

print "Package upgrade: same postinst, Cipher list is added in config file\n";
my_system($postinst) ;

print "Even command line is safe for users: try to modify IgnoreRhosts with bad value\n";
print "Run: 'config-edit-sshd -ui none IgnoreRhosts=oui'\n";
my_system("perl -I../lib -S config-edit -model Sshd -model_dir lib/Config/Model/models ".
 	 "-root_dir . -ui none  IgnoreRhosts=oui") ;

my $fuse_dir = 'my_fuse' ;
say "If you prefer to use a virtual file system (script ?)" ;
say "Run: 'config-edit-sshd -ui fuse -fuse_dir $fuse_dir'";
mkdir ($fuse_dir,0755) unless -d $fuse_dir ;
my_system("perl -I../lib -S config-edit -model Sshd -model_dir lib/Config/Model/models ".
    "-root_dir .  -ui fuse -fuse_dir $fuse_dir"
) ;
my_system("ls --classify $fuse_dir",1);
my_system(qq!echo "/etc/my_banner.txt" > $fuse_dir/Banner!,1) ; 
my_system("fusermount -u $fuse_dir",1);	 
	 
print "Beginners will probably prefer a GUI\n";
print "Run: config-edit-sshd\n";
my_system("perl -I../lib -S config-edit -model Sshd -model_dir lib/Config/Model/models ".
	 "-root_dir .  ") ;

END {
    system("fusermount -u $fuse_dir");
    kill "QUIT",$pid ;
}
