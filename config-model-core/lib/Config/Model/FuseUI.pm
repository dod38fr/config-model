package Config::Model::FuseUI ;

# there's no Singleton with Mouse
use Any::Moose ;

use Fuse qw(fuse_get_context);
use Fcntl ':mode';
use POSIX qw(ENOENT EISDIR EINVAL);
use Log::Log4perl qw(get_logger :levels);
use English qw( -no_match_vars ) ;

has model         => ( is => 'rw', isa => 'Config::Model');
has root          => ( is => 'ro', isa => 'Config::Model::Node', required => 1 );
has mountpoint    => ( is => 'ro', isa => 'Str'          , required => 1 );

my $logger = get_logger("FuseUI") ;

our $fuseui ;

sub BUILD {
    my $self = shift ;
    croak (__PACKAGE__," singleton constructed twice" )
        if defined $fuseui and $fuseui ne $self;
    $fuseui = shift ; # store singleton object in global variable
}

# nodes, list and hashes are directories
sub getdir {
    my $name = shift ;
    $logger->debug("FuseUI getdir called with $name");

    my $obj = $fuseui->root->get(path => $name, check => 'skip', get_obj => 1, autoadd=>0) ;
    return -EINVAL() unless (ref $obj and $obj->can('children')) ;
    
    my @c = ('..','.', $obj->children ) ;
    $logger->debug("FuseUI getdir return @c , wantarray is ".(wantarray ? 1 : 0) );
    return ( @c , 0 ) ;
}

my %files ;

sub fetch_as_line {
    my $obj = shift ; 
    my $v = $obj->fetch(check => 'no') ;
    $v = '' unless defined $v ;
    # let's append a \n so that returned files always have a line ending
    $v .= "\n" unless $v =~ /\n$/ ;

    return $v ;
}


sub getattr {
    my $name = shift ;
    $logger->debug("FuseUI getattr called with $name");
    my $obj = $fuseui->root->get(path => $name, check => 'skip', get_obj => 1, autoadd=>0) ;

    return -&ENOENT() unless ref $obj ;

    my $type = $obj->get_type ;

    # return -ENOENT() unless exists($files{$file});

    my $size ;
    if ($type eq 'leaf' or $type eq 'check_list') { 
        $size = length (fetch_as_line($obj)) ;
    }
    else {
        my @c = $obj->children ; 
        $size = @c; 
    }
    
    my $mode ;
    if ($type eq 'leaf' or $type eq 'check_list') {
        $mode = S_IFREG | 0644  ;
    }
    else {
        $mode = S_IFDIR | 0755 ;
    }

    my ($dev, $ino, $rdev, $blocks, $gid, $uid, $nlink, $blksize) = (0,0,0,1,$EGID,$EUID,1,1024);
    my ($atime, $ctime, $mtime);
    $atime = $ctime = $mtime = time ;
	# 2 possible types of return values:
	#return -ENOENT(); # or any other error you care to
	#print(join(",",($dev,$ino,$modes,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks)),"\n");
    my @r = ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks);
    $logger->trace("FuseUI getattr returns '".join("','",@r)."'");

    return @r ;
}


sub open {
    # VFS sanity check; it keeps all the necessary state, not much to do here.
    my $name = shift ;
    $logger->debug("FuseUI open called on $name");
    my $obj = $fuseui->root->get(path => $name, check => 'skip', get_obj => 1) ;
    my $type = $obj->get_type ;
    
    return -ENOENT() unless defined $obj;
    return -EISDIR() unless ($type eq 'leaf' or $type eq 'check_list') ;
    $logger->debug("FuseUI open on $name ok");
    return 0;
}

sub read {
    # return an error numeric, or binary/text string.  (note: 0 means EOF, "0" will
    # give a byte (ascii "0") to the reading program)
    my ($name,$buf,$off) = @_;
 
    $logger->debug("FuseUI read called on $name");
    my $obj = $fuseui->root->get(path => $name, check => 'skip', get_obj => 1) ;
    my $type = $obj->get_type ;

    return -ENOENT() unless defined $obj;
    return -EISDIR() unless ($type eq 'leaf' or $type eq 'check_list') ;
    my $v = fetch_as_line($obj) ;

    if(not defined $v) {
	return -EINVAL() if $off > 0;
        return '' ;
    }

    return -EINVAL() if $off > length($v);
    return 0 if $off == length($v);
    my $ret = substr($v,$off,$buf); 
    $logger->debug("FuseUI read returns '$ret'");
    return "$ret" ;
}

sub truncate {
    my ($name,$off) = @_;

    $logger->debug("FuseUI truncate called on $name with length $off");
    my $obj = $fuseui->root->get(path => $name, check => 'skip', get_obj => 1) ;
    my $type = $obj->get_type ;

    return -ENOENT() unless defined $obj;
    return -EISDIR() unless ($type eq 'leaf' or $type eq 'check_list') ;

    my $v = substr fetch_as_line($obj) , 0, $off ;

    $logger->debug("FuseUI truncate stores '$v'");
    $obj->store(value => $v, check => 'no') ;
    return 0 ;
}

sub write {
    my ($name,$buf,$off) = @_;

    if ($logger->is_debug) {
        my $str = $buf ;
        $str =~ s/\n/\\n/g;
        $logger->debug("FuseUI write called on $name with '$str' offset $off");
    }
    
    my $obj = $fuseui->root->get(path => $name, check => 'skip', get_obj => 1) ;
    my $type = $obj->get_type ;

    return -ENOENT() unless defined $obj;
    return -EISDIR() unless ($type eq 'leaf' or $type eq 'check_list') ;

    my $v = fetch_as_line($obj);
    $logger->debug("FuseUI write starts with '$v'");

    substr $v,$off,length($buf),$buf ;
    chomp $v unless ($type eq 'leaf' and $obj->value_type eq 'string') ;
    $logger->debug("FuseUI write stores '$v'");
    $obj->store(value => $v, skip => 'check' ) ;
    return length($buf) ;
}

sub mkdir {
    # return an error numeric, or binary/text string.  (note: 0 means EOF, "0" will
    # give a byte (ascii "0") to the reading program)
    my ($name,$mode) = @_;
 
    $logger->debug("FuseUI mkdir called on $name with mode $mode");
    my $obj = $fuseui->root->get(path => $name, check => 'skip', get_obj => 1) ;
    return -ENOENT() unless defined $obj;

    my $type = $obj->get_container_type ;
    return -ENOENT() unless ($type eq 'list' or $type eq 'hash') ;

    return 0 ;
}

sub rmdir {
    # return an error numeric, or binary/text string.  (note: 0 means EOF, "0" will
    # give a byte (ascii "0") to the reading program)
    my ($name) = @_;
 
    $logger->debug("FuseUI rmdir called on $name");
    my $obj = $fuseui->root->get(path => $name, check => 'skip', get_obj => 1, autoadd=>0) ;
    return -ENOENT() unless defined $obj;

    my $type = $obj->get_type ;
    return -ENOENT() if ($type eq 'leaf' or $type eq 'check_list') ;

    my $ct = $obj->get_container_type ;
    my $elt_name = $obj->element_name ;
    my $parent = $obj->parent ;
    
    if ($ct eq 'list' or $ct eq 'hash') {
        my $idx = $obj->index_value ;
        $logger->debug("FuseUI rmdir actually deletes $idx");
        $parent->fetch_element($elt_name)->delete($idx) ;
    }
    
    # ignore deletion request for other "non deletable" elements

    return 0 ;
}

sub unlink {
    my ($name) = @_;

    $logger->debug("FuseUI unlink called on $name");
    my $obj = $fuseui->root->get(path => $name, check => 'skip', get_obj => 1, autoadd=>0) ;
    my $type = $obj->get_type ;

    return -ENOENT() unless defined $obj;
    return -EISDIR() unless ($type eq 'leaf' or $type eq 'check_list') ;
    
    my $ct = $obj->get_container_type ;
    my $elt_name = $obj->element_name ;
    my $parent = $obj->parent ;
    
    if ($ct eq 'list' or $ct eq 'hash') {
        my $idx = $obj->index_value ;
        $logger->debug("FuseUI unlink actually deletes $idx");
        $parent->fetch_element($elt_name)->delete($name) ;
    }
    
    # ignore deletion request for other "non deletable" elements

    return 0 ;
}
 
sub statfs { return 255, 1, 1, 1, 1, 2 }

my @methods = map { ( $_ => __PACKAGE__."::$_" ) } 
    qw/getattr getdir open read write statfs truncate unlink mkdir rmdir/ ;

# FIXME: flush release 
# maybe also: readlink mknod symlink rename link chmod chown utime

sub run_loop {
    my ($self,%args) = @_ ;
    my $debug = $args{debug} || 0 ;

    Fuse::main(
        mountpoint => $self->mountpoint,
        @methods ,
        debug    => $debug || 0,
        threaded => 0 ,
    );
}

1;

=head1 NAME

Config::Model::FuseUI - Fuse virtual file interface for Config::Model

=head1 SYNOPSIS

 # command line
 mkdir fuse_dir
 config-edit -application popcon -ui fuse -fuse_dir fusedir 
 ll fuse_dir
 fusermount -u fuse_dir
 
 # programmatic
 use Config::Model ;
 use Config::Model::FuseUI ;
 use Log::Log4perl qw(:easy) ; 
 
 Log::Log4perl->easy_init($WARN); 
 my $model = Config::Model -> new; 
 my $root = $model -> instance (root_class_name => "PopCon") -> config_root ; 
 my $ui = Config::Model::FuseUI->new( root => $root, mountpoint => "fuse_dir" ); 
 $ui -> run_loop ;  # blocking call
 
 # explore fuse_dir in another terminal then umount fuse_dir directory
 

=head1 DESCRIPTION

This module provides a virtual file system interface for you configuration data. Each possible 
parameter of your configuration file is mapped to a file. 

=head1 Example 

 $ perl -Ilib config-edit -ui fuse -fuse_dir fused -appli popcon 
 Mounting config on fused in background.
 Use command 'fusermount -u fused' to unmount
 $ ll fused
 total 4
 -rw-r--r-- 1 domi domi  1 Dec  8 19:27 DAY
 -rw-r--r-- 1 domi domi  0 Dec  8 19:27 HTTP_PROXY
 -rw-r--r-- 1 domi domi  0 Dec  8 19:27 MAILFROM
 -rw-r--r-- 1 domi domi  0 Dec  8 19:27 MAILTO
 -rw-r--r-- 1 domi domi 32 Dec  8 19:27 MY_HOSTID
 -rw-r--r-- 1 domi domi  3 Dec  8 19:27 PARTICIPATE
 -rw-r--r-- 1 domi domi  0 Dec  8 19:27 SUBMITURLS
 -rw-r--r-- 1 domi domi  3 Dec  8 19:27 USEHTTP
 $ fusermount -u fuse_dir

=head1 BUGS

For some configuration, mapping each parameter to a file may lead to a high number of files.

=head1 constructor

=head1 new (...)

parameters are:

=over 

=item model

Config::Model object

=item root

Root of the configuration tree (C<Config::Model::Node> object )

=item mountpoint

=back

=head1 Methods

=head2 run_loop( fork_in_loop => 1|0, debug => 1|0)

Mount the file system either in the current process or fork a new process before mounting the file system.
In the former case, the call is blocking. In the latter, the call will return after forking a process that
will perform the mount. Debug parameter is passed to Fuse system to get Fuse traces.

=head2 fuse_mount

Mount the fuse file system. This method will block until the file system is 
unmounted (with C<fusermount -u mount_point> command)

=cut

=head1 SEE ALSO

L<Fuse>, L<Config::Model>
