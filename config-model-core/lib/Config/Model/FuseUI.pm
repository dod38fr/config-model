package Config::Model::FuseUI ;

use Moose ;

use Fuse qw(fuse_get_context);
use Fcntl ':mode';
use POSIX qw(ENOENT EISDIR EINVAL);
use Log::Log4perl qw(get_logger :levels);

use MooseX::Singleton;
has model       => ( is => 'rw', isa => 'Config::Model');
has root        => ( is => 'ro', isa => 'Config::Model::Node', required => 1 );
has mountpoint  => ( is => 'ro', isa => 'Str'          , required => 1 );

my $logger = get_logger("FuseUI") ;

our $fuseui ;

sub BUILD {
    $fuseui = shift ; # store singleton object in global variable
}

# nodes, list and hashes are directories
sub getdir {
    my $name = shift ;
    $logger->debug(__PACKAGE__."::getdir called with $name");

    my $obj = $fuseui->root->get(path => $name, check => 'skip', get_obj => 1, autoadd=>0) ;
    return -EINVAL() unless (ref $obj and $obj->can('children')) ;
    
    my @c = ('..','.', $obj->children ) ;
    $logger->debug(__PACKAGE__."::getdir return @c , wantarray is ".(wantarray ? 1 : 0) );
    return ( @c , 0 ) ;
}

sub filename_fixup {
	my ($file) = shift;
	$file =~ s,^/,,;
	$file = '.' unless length($file);
	return $file;
}

my %files ;

sub getattr {
    my $name = shift ;
    $logger->debug(__PACKAGE__."::getattr called with $name");
    my $obj = $fuseui->root->get(path => $name, check => 'skip', get_obj => 1, autoadd=>0) ;

    return -&ENOENT() unless ref $obj ;

    my $type = $obj->get_type ;

    # return -ENOENT() unless exists($files{$file});

    my $size ;
    if    ($type eq 'leaf') { $size = length ($obj->fetch || '') ;}
    elsif ($type eq 'check_list') { $size = length ($obj->fetch || '') ;}
    else {my @c = $obj->children ; $size = @c; }
    
    my $mode ;
    if ($type eq 'leaf' or $type eq 'check_list') {
        $mode = S_IFREG | 0666  ;
    }
    else {
        $mode = S_IFDIR | 0755 ;
    }

    my ($dev, $ino, $rdev, $blocks, $gid, $uid, $nlink, $blksize) = (0,0,0,1,0,0,1,1024);
    my ($atime, $ctime, $mtime);
    $atime = $ctime = $mtime = time ;
	# 2 possible types of return values:
	#return -ENOENT(); # or any other error you care to
	#print(join(",",($dev,$ino,$modes,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks)),"\n");
    my @r = ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks);
        $logger->trace(__PACKAGE__."::getattr returns '".join("','",@r)."'");
    return @r ;
}


sub open {
    # VFS sanity check; it keeps all the necessary state, not much to do here.
    my $name = shift ;
    $logger->debug(__PACKAGE__."::open called on $name");
    my $obj = $fuseui->root->get(path => $name, check => 'skip', get_obj => 1) ;
    my $type = $obj->get_type ;
    
    return -ENOENT() unless defined $obj;
    return -EISDIR() unless ($type eq 'leaf' or $type eq 'check_list') ;
    $logger->debug(__PACKAGE__."::open on $name ok");
    return 0;
}

sub read {
    # return an error numeric, or binary/text string.  (note: 0 means EOF, "0" will
    # give a byte (ascii "0") to the reading program)
    my ($name,$buf,$off) = @_;
 
    $logger->debug(__PACKAGE__."::read called on $name");
    my $obj = $fuseui->root->get(path => $name, check => 'skip', get_obj => 1) ;
    my $type = $obj->get_type ;

    return -ENOENT() unless defined $obj;
    return -EISDIR() unless ($type eq 'leaf' or $type eq 'check_list') ;
    my $v = $obj->fetch ;

    if(not defined $v) {
	return -EINVAL() if $off > 0;
        return '' ;
    }

    return -EINVAL() if $off > length($v);
    return 0 if $off == length($v);
    my $ret = substr($v,$off,$buf); 
    $logger->debug(__PACKAGE__."::read returns '$ret'");
    return $ret ;
}

sub truncate {
    my ($name,$off) = @_;

    $logger->debug(__PACKAGE__."::truncate called on $name with length $off");
    my $obj = $fuseui->root->get(path => $name, check => 'skip', get_obj => 1) ;
    my $type = $obj->get_type ;

    return -ENOENT() unless defined $obj;
    return -EISDIR() unless ($type eq 'leaf' or $type eq 'check_list') ;

    my $v = substr $obj->fetch, 0, $off ;

    $logger->debug(__PACKAGE__."::truncate stores '$v'");
    $obj->store(value => $v, check => 'skip') ;
    return 0 ;
}

sub write {
    my ($name,$buf,$off) = @_;

    if ($logger->is_debug) {
        my $str = $buf ;
        $str =~ s/\n/\\n/g;
        $logger->debug(__PACKAGE__."::write called on $name with '$str' offset $off");
    }
    
    my $obj = $fuseui->root->get(path => $name, check => 'skip', get_obj => 1) ;
    my $type = $obj->get_type ;

    return -ENOENT() unless defined $obj;
    return -EISDIR() unless ($type eq 'leaf' or $type eq 'check_list') ;

    my $v = $obj->fetch || '';
    $logger->debug(__PACKAGE__."::write starts with '$v'");

    substr $v,$off,length($buf),$buf ;
    chomp $v unless ($type eq 'leaf' and $obj->value_type eq 'string') ;
    $logger->debug(__PACKAGE__."::write stores '$v'");
    $obj->store(value => $v, skip => 'check' ) ;
    return length($buf) ;
}

sub mkdir {
    # return an error numeric, or binary/text string.  (note: 0 means EOF, "0" will
    # give a byte (ascii "0") to the reading program)
    my ($name,$mode) = @_;
 
    $logger->debug(__PACKAGE__."::mkdir called on $name with mode $mode");
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
 
    $logger->debug(__PACKAGE__."::rmdir called on $name");
    my $obj = $fuseui->root->get(path => $name, check => 'skip', get_obj => 1, autoadd=>0) ;
    return -ENOENT() unless defined $obj;

    my $type = $obj->get_type ;
    return -ENOENT() if ($type eq 'leaf' or $type eq 'check_list') ;

    my $ct = $obj->get_container_type ;
    my $elt_name = $obj->element_name ;
    my $parent = $obj->parent ;
    
    if ($ct eq 'list' or $ct eq 'hash') {
        my $idx = $obj->index_value ;
        $logger->debug(__PACKAGE__."::rmdir actually deletes $idx");
        $parent->fetch_element($elt_name)->delete($idx) ;
    }
    
    # ignore deletion request for other "non deletable" elements

    return 0 ;
}

sub unlink {
    my ($name) = @_;

    $logger->debug(__PACKAGE__."::unlink called on $name");
    my $obj = $fuseui->root->get(path => $name, check => 'skip', get_obj => 1, autoadd=>0) ;
    my $type = $obj->get_type ;

    return -ENOENT() unless defined $obj;
    return -EISDIR() unless ($type eq 'leaf' or $type eq 'check_list') ;
    
    my $ct = $obj->get_container_type ;
    my $elt_name = $obj->element_name ;
    my $parent = $obj->parent ;
    
    if ($ct eq 'list' or $ct eq 'hash') {
        my $idx = $obj->index_value ;
        $logger->debug(__PACKAGE__."::unlink actually deletes $idx");
        $parent->fetch_element($elt_name)->delete($name) ;
    }
    
    # ignore deletion request for other "non deletable" elements

    return 0 ;
}
 
sub statfs { return 255, 1, 1, 1, 1, 2 }

=head1 Methods

=head2 run_loop()

Engage in user interaction until user enters '^D' (CTRL-D).

=cut

my @methods = map { ( $_ => __PACKAGE__."::$_" ) } qw/getattr getdir open read write statfs truncate unlink mkdir rmdir/ ;

# FIXME: mkdir rmdir unlink truncate flush release 
# maybe also: readlink mknod symlink rename link chmod chown utime

sub run_loop {
    my ($self,$debug) = @_ ;

    # If you run the script directly, it will run fusermount, which will in turn
    # re-run this script.  Hence the funky semantics.
    Fuse::main(
            mountpoint => $self->mountpoint,
            @methods ,
            debug    => $debug || 0,
            threaded => 0 ,
    );
}

1;

=head1 SEE ALSO

L<Fuse>
