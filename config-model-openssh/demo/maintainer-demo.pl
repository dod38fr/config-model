#!/usr/bin/perl

use strict;
use warnings;

use Text::Wrap ;
use File::Path qw(make_path remove_tree);


sub go_on {
    print "continue (Y/n/q)?";
    my $ans =  <STDIN>;
    exit if $ans =~ /^q/i;
    return if $ans =~ /^n/i ;
}

sub done {
    print "Done. hit return to continue ... ";
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

print "Copying ssh model\n\n";
system("cp -r ../lib .") ;

my $showpostinst = "config-edit -model Sshd -ui none -save" ;
my $postinst = $showpostinst . " -model_dir lib/Config/Model/models "
	 . "-root_dir . -backend custom ";

print "Upstream upgrade: KeepAlive is to be changed to TCPKeepAlive\n";
print "postinst will run: $showpostinst\n" ;
go_on ;
system($postinst) ;
print "\n";

print "Add distro policy: Debian dev patches OpenSsh model...\n";
my_system("config-model-edit -model Sshd -save ".
	  qq!class:Sshd element:PermitRootLogin default=no upstream_default~!, 1) ;
print "\n";

print "Add distro policy: show the diff...\n";
my_system("diff -Naur ../lib lib") ;
print "\n";

print "Package upgrade: PermitRootLogin is updated\n";
go_on ;
system($postinst) ;
print "\n";

print "Add another distro policy: Patch model with reduced default cipher list...\n";
my_system("config-model-edit -model Sshd -save ".
	  qq!class:Sshd element:Ciphers !.
	  qq!default_list=aes128-cbc,aes128-ctr,aes192-cbc,aes192-ctr,aes256-cbc,aes256-ctr!,1) ;
print "\n";

print "Package upgrade: Ciphers is added in config file\n";
go_on ;
system($postinst) ;
print "\n";

if (0) {
# bug: -force does not work
print "Big problem: aes-128-* are compromised. Need to help user remove these ciphers\n";
print "Patch model to have a hard restriction on cipher list...\n";
my_system("config-model-edit -model Sshd -save ".
 	  'class:Sshd element:Ciphers '.
 	  'choice=arcfour256,aes192-cbc,aes192-ctr,aes256-cbc,aes256-ctr '.
 	  'default_list=aes192-cbc,aes192-ctr,aes256-cbc,aes256-ctr',1) ;

print "standard upgrade: Ciphers restriction leads to error\n";
system($postinst) ;
go_on ;


print "Possibility to use -force to override\n";
my_system("$postinst -force",1) ;
}

print "Usability for maintainers is not forgotten\n",
	 "There's also a GUI to edit models\n";
my_system("config-model-edit -model Sshd",1) ;

END {
    kill "QUIT",$pid ;
}
