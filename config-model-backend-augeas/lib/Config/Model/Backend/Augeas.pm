# $Author$
# $Date$
# $Revision$

#    Copyright (c) 2008-2009 Dominique Dumont.
#
#    This file is part of Config-Model-Backend-Augeas.
#
#    Config-Model is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser Public License as
#    published by the Free Software Foundation; either version 2.1 of
#    the License, or (at your option) any later version.
#
#    Config-Model is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser Public License for more details.
#
#    You should have received a copy of the GNU Lesser Public License
#    along with Config-Model; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA

package Config::Model::Backend::Augeas ;
use Carp;
use strict;
use warnings ;
use Config::Model::Exception ;
use UNIVERSAL ;
use File::Path;

my $has_augeas = 1;
eval { require Config::Augeas ;} ;
$has_augeas = 0 if $@ ;

our $VERSION = '0.106';

=head1 NAME

Config::Model::Backend::Augeas - Read and write config data through Augeas

=head1 SYNOPSIS

  # use with Augeas
  $model->create_config_class 
  (
   config_class_name => 'OpenSsh::Sshd',

   # try Augeas and fall-back with custom method
   read_config  => [ { backend => 'augeas' , 
                       config_file => '/etc/ssh/sshd_config',
                       # declare "seq" Augeas elements 
                       sequential_lens => [/AcceptEnv AllowGroups [etc]/],
                     },
                     { backend => 'custom' , # dir hardcoded in custom class
                       class => 'Config::Model::Sshd' 
                     }
                   ],
   # write_config will be written using read_config specifications


   element => ...
  ) ;

=head1 DESCRIPTION

This class provides a way to load or store configuration data through
L<Config::Augeas>. This way, the structure and commments of the
original configuration file will preserved.

To use Augeas as a backend, you must specify the following
C<read_config> parameters:

=over

=item backend

Use C<augeas> (or C<Augeas>)in this case.

=item save

Either C<backup> or C<newfile>. See L<Config::Augeas/Constructor> for
details.

=item config_file

Name of the config_file.

=item sequential_lens

This one is tricky. Set to one when new Augeas list or hash node must
be created for each new list or hash element. See L</Sequential lens>
for details.

=back

For instance:

   read_config  => [ { backend => 'augeas' , 
                       save   => 'backup',
                       config_file => '/etc/ssh/sshd_config',
                       # declare "seq" Augeas elements 
                       sequential_lens => [/AcceptEnv AllowGroups/],
                     },
                   ],


=head2 Sequential lens

Some configuration files feature data that must be written as list or
as hash. Depending on the syntax, Augeas list or hash lenses can be
written so that new "container" nodes are required for each new element.

For instance, C<HostKey> lines can be repeated several times in
C<sshd_config>. Since Augeas must keep track of these several lines,
Augeas tree will be written like:

 /files/etc/ssh/sshd_config/HostKey[1]
 /files/etc/ssh/sshd_config/HostKey[2]
 /files/etc/ssh/sshd_config/HostKey[3]

and not:

 /files/etc/ssh/sshd_config/HostKey/1
 /files/etc/ssh/sshd_config/HostKey/2
 /files/etc/ssh/sshd_config/HostKey/3

The C<HostKey> node is created several times. A new hostkey must be
added with the following syntax:

 /files/etc/ssh/sshd_config/HostKey[4]

and not:

 /files/etc/ssh/sshd_config/HostKey/4

So the C<HostKey> lens is sequential.

The situation is more complex when syntax allow repeated values on
several lines. Like:

 AcceptEnv LC_PAPER LC_NAME LC_ADDRESS
 AcceptEnv LC_IDENTIFICATION LC_ALL

Augeas will have this tree:

 /files/etc/ssh/sshd_config/AcceptEnv[1]/1
 /files/etc/ssh/sshd_config/AcceptEnv[1]/2
 /files/etc/ssh/sshd_config/AcceptEnv[1]/3
 /files/etc/ssh/sshd_config/AcceptEnv[2]/4
 /files/etc/ssh/sshd_config/AcceptEnv[2]/5

Note that the first index between squarekeeps track of how are grouped
the C<AcceptEnv> data, but the I<real> list index is after the slash.

Augeas does not require new elements to create C<AcceptEnv[3]>. A new
element can be added as :

 /files/etc/ssh/sshd_config/AcceptEnv[2]/6

So this lens is not sequential.

The same kind of trouble occurs with hash elements. Some hashes tree
are like:

 /files/etc/foo/my_hash/my_key1
 /files/etc/foo/my_hash/my_key2

Others are like:

 /files/etc/foo/my_hash[1]/my_key1
 /files/etc/foo/my_hash[2]/my_key2

Note that a list-like index is used with the hash key.

This also depends on the syntax of the configuration file. For
instance, C<Subsystem> in C<sshd_config> can be :

 Subsystem   sftp /usr/lib/openssh/sftp-server
 Subsystem   fooftp /usr/lib/openssh/fooftp-server
 Subsystem   barftp /usr/lib/openssh/barftp-server


This (unvalid) sshd configuration is represented by:

 /files/etc/ssh/sshd_config/Subsystem[1]/sftp
 /files/etc/ssh/sshd_config/Subsystem[2]/fooftp
 /files/etc/ssh/sshd_config/Subsystem[3]/barftp

Any new Subsystem must be added with:

 /files/etc/ssh/sshd_config/Subsystem[4]/bazftp

In this case, the hash is also sequential.

For these examples, the augeas backend declaration must feature:

 sequential_lens => [qw/HostKey Subsystem/],

=head2 Augeas backend limitation

The structure and element names of the Config::Model tree must match
the structure defined in Augeas lenses. I.e. the order of the element
declared in Config::Model must match the order required by Augeas
lenses.

Sometimes, the structure of a file loaded by Augeas starts directly
with a list of items. For instance C</etc/hosts> structure starts with
a list of lines that specify hosts and IP adresses. The C<set_in>
parameter specifies an element name in Config::Model root class that
will hold the configuration data retrieved by Augeas.

=cut

sub new {
    my $type = shift ;
    my %args = @_ ;
    my $node = $args{node} || croak "write: missing node parameter";
    my $self = { node => $node } ;
    bless $self,$type ;
}

# for tests only
sub _augeas_object {return shift->{augeas_obj} ; } ;

sub read
  {
    my $self = shift;
    my %args = @_ ; # contains root and config_dir
    return 0 unless $has_augeas ;

    $self->{augeas_obj} ||= Config::Augeas->new(root => $args{root}, 
						save => $args{save} ) ;

    foreach my $param (qw/config_dir config_file/) {
	if (not defined $args{$param}) {
	    Config::Model::Exception::Model -> throw
		(
		 error=> "read_augeas error: model "
		 . "does not specify '$param' for Augeas ",
		 object => $self->{node}
		) ;
	}
    }

    my $cdir = $args{root}.$args{config_dir} ;
    print "Read config data through Augeas in directory '$cdir' ",
      "file $args{config_file}\n" 
	if $::verbose;

    my $mainpath = '/files'.$args{config_dir}.$args{config_file} ;

    my @result =  $self->augeas_deep_match($mainpath) ;
    my @cm_path = @result ;

    # cleanup resulting path to remove Augeas '/files', remove the
    # file path and plug the remaining path where it is consistent in
    # the model. I.e if the file "root" matches a list element (like
    # for /etc/hosts), get this element name from "set_in" parameter
    my $set_in = $args{set_in} || '';
    map {
	s!$mainpath!! ;
	$_ = "/$set_in/$_" if $set_in;
	s!/+!/!g;
    } @cm_path ;

    # Create a hash of sequential lenses
    my %is_seq_lens = map { ( $_ => 1 ) ;} @{$args{sequential_lens} || []} ;

    my $augeas_obj = $self->{augeas_obj} ;

    # this may break as data will be written in the tree in an order
    # decided by Augeas. This may break complex model with warping as
    # the best writing order is indicated by the model stored in
    # Config::Model and not by Augeas.
    while (@result) {
	my $aug_p = shift @result;
	my $cm_p  = shift @cm_path; # Config::Model path
	my $v = $augeas_obj->get($aug_p) ;
	next unless defined $v ;

	print "read-augeas $aug_p, will set C::M path $cm_p with $v\n" if $::debug ;
	$cm_p =~ s!^/!! ;
	# With some list, we can get
	# /files/etc/ssh/sshd_config/AcceptEnv[1]/1/ =  LC_PAPER
	# /files/etc/ssh/sshd_config/AcceptEnv[1]/2/ =  LC_NAME
	# /files/etc/ssh/sshd_config/AcceptEnv[2]/3/ =  LC_ADDRESS
	# /files/etc/ssh/sshd_config/AcceptEnv[2]/4/ =  LC_TELEPHONE

	# Depending on the syntax, list can be in the form:
	# /files/etc/ssh/sshd_config/AcceptEnv[2]/3/   non-seq  ditch idx
        # /files/etc/hosts/4/                          non-seq
	# /files/etc/ssh/sshd_config/HostKey[2]         is-seq  keep idx

	# Likewise, hashes can be in the form
	# /files/etc/ssh/sshd_config/Subsystem[2]/foo/    is-seq ditch idx
	# /files/etc/ssh/sshd_config/Bar/foo/            non-seq

	my @cm_steps = split m!/+!, $cm_p ;
	my $obj = $self->{node};
	$obj = $obj->fetch_element(shift @cm_steps) if $set_in ;

	while (my $step = shift @cm_steps) {
	    my ($label,$idx) = ( $step =~ /(\w+)(?:\[(\d+)\])?/ ) ;
	    my $is_seq = $is_seq_lens{$label} || 0 ;
	    print "read-augeas: step label $label ",
	      defined $idx ? "idx $idx ": '', "(is_seq $is_seq)\n"
		if $::debug ; 

	    # idx will be treated next iteration if needed
	    if (    $obj->get_type eq 'node' 
		and $obj->element_type($label) eq 'list'
		and $is_seq
	       ) {
		$idx = 1 unless defined $idx ;
		print "read-augeas: keep seq lens idx $idx\n" if $::debug ; 
		unshift @cm_steps , $idx ;
	    }

	    if ($label =~ /\[/) {
		Config::Model::Exception::Model -> throw
		    (
		     error=> "read_augeas error: can't use $label with "
		     ."Augeas index in Config::Model. $label should "
		     . "probably be listed as 'sequential_lens'",
		     object => $self->{node}
		    ) ;
	    }

	    # augeas list begin at 1 not 0
	    $label -= 1 if $obj->get_type eq 'list';
	    if (scalar @cm_steps > 0) {
		print "read-augeas: get $label\n" if $::debug;
		$obj = $obj->get($label) ;
	    }
	    else {
		# last step
		print "read-augeas: set $label $v\n" if $::debug ; 
		$obj->set($label,$v) ;
	    }

	    if (not defined $obj) {
		Config::Model::Exception::Model -> throw
		    (
		     error=> "read_augeas error: '$cm_p' led to undef object. "
		     . "Check for errors in 'sequential_lens' specification",
		     object => $self->{node}
		    ) ;
	    }
	}
    }

    return 1 ;
  }

sub augeas_deep_match {
    my ($self,$mainpath) = @_ ;

    # work around Augeas feature where '*' matches only one hierarchy
    # level 
    # See https://www.redhat.com/archives/augeas-devel/2008-July/msg00016.html
    my @worklist = ( $mainpath );
    print "read-augeas on @worklist\n" if $::debug ;

    my $augeas_obj = $self->{augeas_obj} ;
    my @result ;
    while (@worklist) {
	my $p = pop @worklist ;
	my @newpath = $augeas_obj -> match($p . "/*") ;
	print "read-augeas $p/* matches paths: @newpath\n" if $::debug ;
	push @worklist, @newpath ;
	push @result,   @newpath ;
    }

    return @result ;
}

sub write {
    my $self = shift;
    my %args = @_ ; # contains root and config_dir
    return 0 unless $has_augeas ;

    foreach my $param (qw/config_dir config_file/) {
	if (not defined $args{$param}) {
	    Config::Model::Exception::Model -> throw
		(
		 error=> "write_augeas error: model "
		 . "does not specify '$param' for Augeas ",
		 object => $self->{node}
		) ;
	}
    }

    my $cdir = $args{root}.$args{config_dir} ;
    print "Write config data through Augeas in directory '$cdir' ",
      "file $args{config_file}\n" 
	if $::verbose;

    my $set_in = $args{set_in} || '';
    my $mainpath = '/files'.$args{config_dir}.$args{config_file} ;
    my $augeas_obj =   $self->{augeas_obj} 
                   ||= Config::Augeas->new(root => $args{root}, 
					   save => $args{save} ) ;

    my %to_set = $self->copy_in_augeas($augeas_obj,$mainpath,$set_in,
				       $args{sequential_lens}) ;

    $self->save($mainpath);
}

sub save {
    my $self = shift ;
    my $mainpath = shift ;

    $self->{augeas_obj}->print() if $::debug ;

    $self->{augeas_obj}->save || die "Augeas save failed" . 
      $self->{augeas_obj}->print("/augeas/$mainpath/*");
}

sub copy_in_augeas {
    my $self = shift ;
    my $augeas_obj = shift ;
    my $mainpath = shift ;
    my $set_in = shift ;
    my $seq_list = shift || [];
    my %is_seq_lens = map { ( $_ => 1 ) ;} @$seq_list ;

    # The callback are kludgy and may be improved when the
    # following bugs are fixed:
    # https://fedorahosted.org/augeas/ticket/23
    # https://fedorahosted.org/augeas/ticket/24

    my @scan_args = (
		     experience            => 'master',
		     fallback              => 'all',
		     auto_vivify           => 0,
		     list_element_cb       => \&list_element_cb,
		     check_list_element_cb => \&std_cb,
		     hash_element_cb       => \&hash_element_cb,
		     leaf_cb               => \&std_cb ,
		     node_content_cb       => \&node_content_cb,
		    );

    # perform the scan
    my $view_scanner = Config::Model::ObjTreeScanner->new(@scan_args);

    $view_scanner->scan_node([$mainpath,$augeas_obj,$set_in,\%is_seq_lens],
			     $self->{node});
}

sub std_cb {
    my ( $scanner, $data_ref, $obj, $element, $index, $value_obj ) = @_;
    my ($p,$augeas_obj,$set_in,$is_seq_lens) = @$data_ref ;

    my $v = $value_obj->fetch () ; 
    if (defined $v and $v ne '') {
	print "copy_in_augeas: set $p = '$v'\n" if $::verbose;
	$augeas_obj->set($p , $v) ;
	#$self->save($mainpath) if $::debug ;
    }
    else {
	$augeas_obj->remove($p) ;
    }
}


sub list_element_cb {
    my ($scanner, $data_ref,$node,$element_name,@idx) = @_ ;
    my ($p,$augeas_obj,$set_in,$is_seq_lens) = @$data_ref ;

    my $is_seq = $is_seq_lens->{$element_name} || 0;
    # the idea is to compare list indexes from Config::Model with the
    # corresponding hash-like keys in Augeas tree

    # find Augeas nodes matching this path
    my @matches = $augeas_obj->match($p) ;

    # need to find 2nd levels of sub-nodes for non-seq list lenses
    @matches = sort map { $augeas_obj->match($_.'/*') ; } @matches 
      unless $is_seq ;

    # Depending on the syntax, list can be in the form:
    # /files/etc/ssh/sshd_config/AcceptEnv[2]/3/   non-seq  use [last()]/idx/
    # /files/etc/hosts/4/                          non-seq  use [last()]/idx/
    # /files/etc/ssh/sshd_config/HostKey[2]         is-seq  use [idx]

    if ($is_seq) {
	# sequential lens need a list index to store list element.
	# I.e foo[1]/1 foo[1]/2 foo[2]/3 is ok. foo/1 foo/2 will
	# fail. But Augeas does return foo/1 if only one element is
	# present in the tree :-/
	my $replace = $element_name.'[1]';
	map { s/$element_name(?!\[)/$replace/ } @matches ;
    }

    print "copy_in_augeas: List (@idx) path $p matches (seq $is_seq):\n\t",
      join("\n\t",@matches),"\n" if $::debug;

    # store list indexes found in Augeas and their corresponding path
    my %match = map { 
	my ($k) = m!/([\w\[\]\-]+)$!; 
	# need to keep only index in %match key
	$k =~ s/\w+\[(\d+)\]$/$1/ if $is_seq ;
	($k => $_ ) ;
    } @matches ;

    # Handle indexes found in Config::Model, but not in Augeas
    # tree. Create a new Augeas path for sequential list lenses. This
    # path will be used by scan_list
    if ($is_seq) {
	my $count = $augeas_obj->count_match($p) ;
	foreach my $idx (@idx) {
	    # augeas index starts at 1 not 0
	    my $i = $idx + 1; 
	    next if defined $match{$i} ;

	    $match{$i} = $p.'['.++$count."]" . ($is_seq ? '' : "/$i");

	    print "copy_in_augeas: New list path $match{$i} for index $i\n"
	      if $::debug;
	} 
    }

    # now scan the elements stored by Config::Model hash keys to
    # store the hash values
    foreach my $i (@idx) {
	# use Augeas path (given by match command) or the path
	# created for unknown non-seq list elements
	my $scan_path = delete $match{$i+1} || $p.'/'.($i+1);
	print "copy_in_augeas: scan list called on $scan_path index $i\n"
	      if $::debug;
	$scanner->scan_list([$scan_path,$augeas_obj,$set_in,$is_seq_lens], 
			    $node,$element_name,$i);
    }

    # cleanup indexes found in Augeas but not in Config::Model
    foreach (keys %match) {
	my $rm_path = $match{$_} ;

	print "copy_in_augeas: List rm $_ ->$rm_path\n" if $::debug; 
	$augeas_obj->remove($rm_path) || die "remove $rm_path failed";

	# check if removing parent node in Augeas is needed
	$rm_path =~ s!/([\w\[\]\-]+)$!! ; # chomp last "step" of the path
	if ($augeas_obj->count_match($rm_path) == 1
	    and $set_in ne $element_name 
	    and $rm_path =~ /$element_name$/
	   ) {
	    print "copy_in_augeas: List rm parent node $_ ->$rm_path\n" 
	      if $::debug; 
	    $augeas_obj->remove($rm_path) || die "remove $rm_path failed";
	}
    }
}

# this callback is similar but not identical to the list callback.
sub hash_element_cb {
    my ($scanner, $data_ref,$node,$element_name,@keys) = @_ ;
    my ($p,$augeas_obj,$set_in,$is_seq_lens) = @$data_ref ;
    my $is_seq = $is_seq_lens->{$element_name} || 0;

    # the idea is to compare hash keys from Config::Model with the
    # corresponding hash-like keys in Augeas tree

    # find Augeas nodes matching this path
    my @matches = $augeas_obj->match($p) ;

    # need to find 2nd levels of sub-nodes 
    @matches = sort map { $augeas_obj->match($_.'/*') ; } @matches ;

    # sequential lens need a list index to store element.  I.e
    # foo[1]/key1 foo[2]/key2 is ok. foo/key1 foo/key2 will fail But
    # Augeas does return foo/key1 if only one element is present in
    # the tree :-/
    if ($is_seq) {
	my $replace = $element_name.'[1]';
	map { s/$element_name(?!\[)/$replace/ } @matches ;
    }

    print "copy_in_augeas: Hash path $p matches (seq $is_seq):\n\t", 
      join("\n\t",@matches),"\n" if $::debug;

    # store indexes found in Augeas and their corresponding path
    my %match = map { 
	my ($k) = m!/([\w\[\]\-]+)$!; 
	# need to keep only index in %match key
	$k =~ s/\w+\[(\d+)\]$/$1/ if $is_seq ;
	($k => $_ ) ;
    } @matches ;

    # Handle keys found in Config::Model, but not in Augeas
    # tree. Create a new Augeas path for sequential hash lenses. This
    # path will be used by scan_list. This insertion cannot be done if
    # no elements are already present in Augeas tree.
    if ($is_seq and @matches) {
	my $count = $augeas_obj->count_match($p) ;
	foreach (@keys) {
	    next if defined $match{$_} ;

	    my $ip = $p.'[last()]';
	    print "inserting $element_name after $ip\n" if $::debug ;
	    $augeas_obj->insert($element_name, after => $ip ) 
	      || die "augeas insert $element_name after $ip failed";

	    my $np = $match{$_} = $p.'['.++$count."]/$_";
	    print "copy_in_augeas: New hash path $np for key $_\n"
	      if $::debug;
	} 
    }

    # now scan the elements stored by Config::Model hash keys to
    # store the hash values
    foreach (@keys) {
	# use Augeas path (given by match command) or a new path for
	# new elements
	my $scan_path = delete $match{$_} || $p."/$_" ;
	$scanner->scan_hash([$scan_path,$augeas_obj,$set_in,$is_seq_lens],
			    $node,$element_name,$_)
    }

    # cleanup keys found in Augeas but not in Config::Model
    foreach (keys %match) {
	my $rm_path = $match{$_} ;
	print "copy_in_augeas: Hash rm $_ ->$rm_path\n" if $::debug; 
	$augeas_obj->remove($rm_path) || die "remove $rm_path failed";

	# check if removing parent node in Augeas is needed
	$rm_path =~ s!/([\w\[\]\-]+)$!! ;
	if (    $augeas_obj->count_match($rm_path) == 1 
	    and $set_in ne $element_name and $is_seq
	   ) {
	    print "copy_in_augeas: Hash rm parent $_ ->$rm_path\n" 
	      if $::debug; 
	    $augeas_obj->remove($rm_path) || die "remove $rm_path failed";
	}
    }
}

sub node_content_cb {
    my ($scanner, $data_ref,$node,@element) = @_ ;
    my ($p,$augeas_obj,$set_in,$is_seq_lens) = @$data_ref ;

    # See set_in parameter (who said kludge ?)
    if (scalar @element == 1 and $element[0] eq $set_in) {
	# Augeas tree is stored below element[0]
	print "copy_in_augeas: Augeas tree set in node path $p\n" if $::debug;
	$scanner->scan_element([$p,$augeas_obj,$set_in,$is_seq_lens], 
			       $node,$element[0]);
    }
    else {
	my @matches = $augeas_obj->match($p.'/*') ;
	# cleanup indexes are we don't handle them now with element
	# (later in lists and hashes)
	map { s/\[\d+\]+$//;  } @matches ;
	print "copy_in_augeas: Node path $p matches:\n\t", 
	  join("\n\t",@matches),"\n" if $::debug;

	# store elements found in Augeas and their corresponding path
	my %match = map { 
			  my ($elt) = m!/([\w\-]+)$!; 
			  ($elt => $_ ) } @matches ;

	# Handle element found in Config::Model, but not in Augeas
	# tree. Create a new Augeas path for new elements respecting
	# the order of the elements declared in Config::Model. This
	# path will be used by scan_element. This insertion cannot
	# be done if no elements are already present in Augeas tree.
	if (@matches) {
	    my $previous_match = '';
	    foreach (@element) {
		if (defined $match{$_}) {
		    $previous_match = $_ ;
		}
		elsif ($node->fetch_element($_)->dump_as_data) {
		    # insert in Augeas only if the element contains
		    # something interesting
		    my ($direction,$ip) 
		      = $previous_match 
                          ? (after  => $p.'/'.$previous_match.'[last()]')
		          : (before => $matches[0]     ) ;

		    print "inserting $_ $direction $ip\n" if $::debug ;
		    $augeas_obj->insert($_, $direction => $ip ) 
		      || die "augeas insert $_ $direction $ip failed";

		    my $np = $match{$_} = "$p/$_";
		    print "copy_in_augeas: New hash path $np for element $_\n"
		      if $::debug;
		}
	    } 
	}

	# now scan the elements stored by Config::Model elements to
	# store the children nodes
	foreach (@element) {
	    # use Augeas path (given by match command) or the path
	    # created for new elements
	    my $scan_path = delete $match{$_} || $p.'/'.$_ ;
	    print "copy_in_augeas: Node scan $scan_path for element $_\n" 
	      if $::debug;
	    $scanner->scan_element([$scan_path,$augeas_obj,$set_in,$is_seq_lens],
				   $node,$_)
	}

	# cleanup keys found in Augeas but not in Config::Model
	foreach (keys %match) {
	    my $rm_path = $match{$_} ;
	    print "copy_in_augeas: Node rm $_ ->$rm_path\n" if $::debug; 
	    $augeas_obj->remove($rm_path) || die "remove $rm_path failed";
	}
    }
}


1;

=head1 SEE ALSO

=over 

=item * 

http://augeas.net/ : Augeas project page

=item *

L<Config::Model> 

=item *

Augeas mailing list: http://augeas.net/developers.html

=item *

Config::Model mailing list : http://sourceforge.net/mail/?group_id=155650

=back

=head1 AUTHOR

Dominique Dumont, E<lt>ddumont at cpan dot org@<gt>

=head1 COPYRIGHT

Copyright (C) 2008-2009 by Dominique Dumont

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the LGPL terms.

=cut
