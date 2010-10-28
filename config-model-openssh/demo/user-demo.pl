#!/usr/bin/perl

use strict;
use warnings;

use Text::Wrap ;
use File::Path qw(make_path remove_tree);
use Config::Model::OpenSsh ; # to get path



sub go_on {
    print "continue (Y/n/q)?";
    my $ans =  <STDIN>;
    exit if $ans =~ /^q/i;
    return if $ans =~ /^n/i ;
}

sub done {
    print "Done.\nHit return to continue ... ";
    my $ans =  <STDIN>;
    print "\n";
}

sub my_system {
    my $run = shift ;
    my $show = shift || 0 ;
    print "Will run: $run\n" if $show ;
    go_on ;
    system($run) ;
    done ;
    print "\n";
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
my $mod_file = 'Config/Model/OpenSsh.pm' ;
my $lib_path = $INC{$mod_file} ;
$lib_path =~ s/OpenSsh.pm/models/;
make_path('lib/Config/Model/') ;
system("cp -r $lib_path lib/Config/Model/") ; # required to be able to modify the model for the demo

my $postinst = "config-edit -model Sshd -model_dir lib/Config/Model/models "
	 . "-root_dir . -ui none -backend custom -save";

print "Upstream changelog: KeepAlive is changed to TCPKeepAlive\n";
print "User file is updated by package posinst...\n";
my_system($postinst) ;

print "Changing model to reflect maintainer's work. Please wait ..." ;
system("config-model-edit -model Sshd -save ".
	  qq!class:Sshd element:PermitRootLogin default=no upstream_default~!) ;
print "done\n\n";

print "Maintainer changelog: new policy, PermitRootLogin should be set to 'no'\n";
print "Package upgrade triggers same postinst script\n";
my_system($postinst) ;

print "Changing model to reflect maintainer's work. Please wait ..." ;
system("config-model-edit -model Sshd -save ".
	  qq!class:Sshd element:Ciphers !.
	  qq!default_list=aes128-cbc,aes128-ctr,aes192-cbc,aes192-ctr,aes256-cbc,aes256-ctr!) ;
print "done\n\n";

print "Maintainer changelog: reduced default cipher list...\n";

print "Package upgrade: same postinst, Cipher list is added in config file\n";
my_system($postinst) ;

print "Even command line is safe for users: try to modify IgnoreRhosts with bad value\n";
print "Run: 'config-edit-sshd -ui none IgnoreRhosts=oui'\n";
my_system("config-edit -model Sshd -model_dir lib/Config/Model/models ".
 	 "-root_dir . -ui none -backend custom IgnoreRhosts=oui") ;

print "Better let beginner use a GUI\n";
print "Run: config-edit-sshd\n";
my_system("config-edit -model Sshd -model_dir lib/Config/Model/models ".
	 "-root_dir . -backend custom ") ;

END {
    kill "QUIT",$pid ;
}
