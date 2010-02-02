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

print "Upgrade: KeepAlive is changed to TCPKeepAlive\n";
my_system("config-edit -model Sshd -model_dir lib/Config/Model/models",
	 "-root_dir . -ui none -backend augeas -save") ;

sleep 10;

END {
    kill "QUIT",$pid ;
}
