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
    print "Done. hit return to continue ... ";
    $ans =  <STDIN>;
    print "\n\n";
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
    exec ("xterm -e watch cat etc/ssh/sshd_config") ;
}

print "Forked terminal with pid $pid\n";

$SIG{KILL} = sub { kill "QUIT",$pid } ;

print "Copying ssh model\n";
system("cp -r ../lib .") ;

my $postinst = "config-edit -model Sshd -model_dir lib/Config/Model/models "
	 . "-root_dir . -ui none -backend custom -save";

print "Upstream changelog: KeepAlive is changed to TCPKeepAlive\n";
print "User file have to be updated. Package postinst will run something like \n";
my_system($postinst) ;

print "Maintainer changelog: new policy, PermitRootLogin should be set to 'no'\n";

print "Changing model to reflect maintainer's work. Please wait ..." ;
system("config-model-edit -model Sshd -save ".
	  qq!class:Sshd element:PermitRootLogin default=no upstream_default~!) ;
print "done\n";

print "Package upgrade triggers same postinst script\n";
my_system($postinst) ;

print "Maintainer changelog: reduced default cipher list...\n";
print "Changing model to reflect maintainer's work. Please wait ..." ;
system("config-model-edit -model Sshd -save ".
	  qq!class:Sshd element:Ciphers !.
	  qq!default_list=aes128-cbc,aes128-ctr,aes192-cbc,aes192-ctr,aes256-cbc,aes256-ctr!) ;
print "done\n";

print "Package upgrade: same postinst, Cipher list is added in config file\n";
my_system($postinst) ;

print "What if user wants to tinker with config ? -> GUI\n";
my_system("config-edit -model Sshd -model_dir lib/Config/Model/models",
	 "-root_dir . -backend custom ") ;

END {
    kill "QUIT",$pid ;
}
