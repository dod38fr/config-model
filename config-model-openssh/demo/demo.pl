#!/usr/bin/perl

use strict;
use warnings;

use Text::Wrap ;
use File::Path qw(make_path remove_tree);

sub my_system{
    print "Will run: @_\n";
    print "(Y/n/q)?";
    my $ans =  <STDIN>;
    exit if $ans =~ /^q/i;
    return if $ans =~ /^n/i ;
    system("@_") ;
    print "continue ... ";
    $ans =  <STDIN>;
    print "\n\n";
}

print wrap('','',
	   "This program will provide a short demo of the configuration",
	   "upgrade feature of Config::Model.\n");

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
    exec ("xterm -e watch -d cat etc/ssh/sshd_config") ;
}

print "Forked terminal with pid $pid\n";

$SIG{KILL} = sub { kill "QUIT",$pid } ;

print "Copying ssh model\n";
system("cp -r ../lib .") ;

print "Upstream upgrade: KeepAlive is changed to TCPKeepAlive\n";
my_system("config-edit -model Sshd -model_dir lib/Config/Model/models",
	 "-root_dir . -ui none -backend custom -save") ;

print "Add distro policy: Debian dev patches OpenSsh model...\n";
my_system("config-model-edit -model Sshd -save ",
	  qq!class:Sshd element:PermitRootLogin default=no upstream_default=''!) ;

print "Add distro policy: show the diff...\n";
my_system("diff -Naur ../lib lib") ;

print "Package upgrade: PermitRootLogin is updated\n";
my_system("config-edit -model Sshd -model_dir lib/Config/Model/models",
	 "-root_dir . -ui none -backend custom -save") ;

print "Add another distro policy: Patch model: reduced default cipher list...\n";
my_system("config-model-edit -model Sshd -save ",
	  qq!class:Sshd element:Ciphers !,
	  qq!default_list=aes128-cbc,aes128-ctr,aes192-cbc,aes192-ctr,aes256-cbc,aes256-ctr!) ;

print "Package upgrade: Ciphers is added in config file\n";
my_system("config-edit -model Sshd -model_dir lib/Config/Model/models",
	 "-root_dir . -ui none -backend custom -save") ;

# print "May be system room policy: Patch model: hard restriction on cipher list...\n";
# my_system("config-model-edit -model Sshd -save ",
# 	  'class:Sshd element:Ciphers ',
# 	  'choice=arcfour256,aes192-cbc,aes192-ctr,aes256-cbc,aes256-ctr',
# 	  'default_list=aes192-cbc,aes192-ctr,aes256-cbc,aes256-ctr') ;

# print "cluster upgrade: Ciphers restriction leads to error\n";
# my_system("config-edit -model Sshd -model_dir lib/Config/Model/models",
# 	 "-root_dir . -ui none -backend custom -save") ;

# print "cluster upgrade: use -force to override\n";
# my_system("config-edit -model Sshd -model_dir lib/Config/Model/models",
# 	 "-root_dir . -ui none -backend custom -force -save") ;

# print "User set up: Modify IgnoreRhosts with wrong keyword\n";
# my_system("config-edit -model Sshd -model_dir lib/Config/Model/models",
# 	 "-root_dir . -ui none -backend custom IgnoreRhosts=oui") ;
# 

print "Config edition can be scripted: Modify IgnoreRhosts\n";
my_system("config-edit -model Sshd -model_dir lib/Config/Model/models",
	 "-root_dir . -ui none -backend custom IgnoreRhosts=yes") ;

print "And the user ? -> GUI\n";
my_system("config-edit -model Sshd -model_dir lib/Config/Model/models",
	 "-root_dir . -backend custom ") ;

END {
    kill "QUIT",$pid ;
}
