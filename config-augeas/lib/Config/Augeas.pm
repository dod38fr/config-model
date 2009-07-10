#    Copyright (c) 2008-2009 Dominique Dumont.
#
#    This library is free software; you can redistribute it and/or
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
#    02110-1301 USA

package Config::Augeas;

use strict;
use warnings;
use Carp;
use IO::File ;

our $VERSION = '0.501';

require XSLoader;
XSLoader::load('Config::Augeas', $VERSION);

=head1 NAME

Config::Augeas - Edit configuration files through Augeas C library

=head1 SYNOPSIS

  use Config::Augeas;

  my $aug = Config::Augeas->new( root => $aug_root ) ;

  my $ret = $aug->get("/files/etc/hosts/1/ipaddr") ;
  $aug->set("/files/etc/hosts/2/ipaddr","192.168.0.1") ;

  my @a = $aug->match("/files/etc/hosts/") ;

  my $nb = $aug->count_match("/files/etc/hosts/") ;

  $aug->save ;

=head1 DESCRIPTION

=for comment
Description snatched from Augeas README

Augeas is a library and command line tool that focuses on the most
basic problem in handling Linux configurations programmatically:
editing actual configuration files in a controlled manner.

To that end, Augeas exposes a tree of all configuration settings
(well, all the ones it knows about) and a simple local API for
manipulating the tree. Augeas then modifies underlying configuration
files according to the changes that have been made to the tree; it
does as little modeling of configurations as possible, and focuses
exclusively on transforming the tree-oriented syntax of its public API
to the myriad syntaxes of individual configuration files.

This module provides an object oriented Perl interface for Augeas
configuration edition library with a more "perlish" API than Augeas C
counterpart.

=head1 Constructor

=head1 new ( ... )

Creates a new Config::Augeas object. Optional parameters are:

=over

=item loadpath

a colon-spearated list of directories that lenses should be searched
in. This is in addition to the standard load path and the directories
in specified C<AUGEAS_LENS_LIB> environment variable.

=item root

Use C<root> as the filesystem root. If not specified, use the value of
the environment variable C<AUGEAS_ROOT>. If that doesn't exist either,
use "C</>".

=item save => backup | newfile | noop

Specify how to save the configuration file. Either create a newfile
(with extension C<.augnew>, and do not overwrite the original file) or
move the original file into a backup file (C<.augsave> extension).
C<noop> make saves a no-op process, just record what would have
changed

=item type_check => 1

Typecheck lenses; since it can be very expensive it is not done by
default.

=item no_std_inc

Do not use the builtin load path for modules

=item no_load

Do not load the tree from AUG_INIT

=back

=cut

sub new {
    my $type = shift ;
    my $self = {} ;
    my %args = @_ ;
    my $flags = 0 ;
    my $loadpath = delete $args{loadpath} || '';
    my $root  = delete $args{root} || '';

    my $save = delete $args{save} || '';
    if    ($save eq 'backup')  { $flags ||= &AUG_SAVE_BACKUP }
    elsif ($save eq 'newfile') { $flags ||= &AUG_SAVE_NEWFILE }
    elsif ($save =~ 'noop')    { $flags ||= &AUG_SAVE_NOOP }
    elsif ($save) { 
	croak  __PACKAGE__," new: unexpected save value: $save. ",
	  "Expected backup or newfile";
    }

    $flags ||= &AUG_TYPE_CHECK if ( delete $args{type_check} || 0 );
    $flags ||= &AUG_NO_STDINC  if ( delete $args{no_std_inc} || 0 ) ;
    $flags ||= &AUG_NO_LOAD    if ( delete $args{no_load}    || 0 ) ;

    croak  __PACKAGE__," new: unexpected parameters: ",
      join (' ',keys %args) 
	if %args ;

    $self->{aug_c} = Config::Augeas::init($root,$loadpath,$flags) ;

    bless $self,$type ;

    return $self
}

=head1 Methods

=head2 defvar( name, [ expr ])

Define a variable C<name> whose value is the result of evaluating
C<expr>. If a variable C<name> already exists, its name will be replaced
with the result of evaluating C<expr>.

If C<expr> is omitted, the variable C<name> will be removed if it is
defined.

Path variables can be used in path expressions later on by prefixing
them with '$'.

Returns -1 on error; on success, returns 0 if C<expr> evaluates to anything
other than a nodeset, and the number of nodes if C<expr> evaluates to a
nodeset

=cut

sub defvar {
    my $self = shift ;
    my $name = shift || croak __PACKAGE__," defvar: undefined name";
    my $expr = shift || 0 ;

    return $self->{aug_c} -> defvar($name, $expr) ;
}

=head2 defnode ( name, expr, value )

Define a variable C<name> whose value is the result of evaluating
C<expr>, which must evaluate to a nodeset. If a variable C<name>
already exists, its name will be replaced with the result of
evaluating C<expr>.

If C<expr> evaluates to an empty nodeset, a node is created, equivalent to
calling C<set( expr, value)> and C<name> will be the nodeset containing
that single node.

Returns undef on error

Returns an array containing:

=over

=item *

the number of nodes in the nodeset

=item *

1 if a node was created, and 0 if it already existed.

=back

=cut

sub defnode {
    my $self = shift ;
    my $name = shift || croak __PACKAGE__," defnode: undefined name";
    my $expr = shift || croak __PACKAGE__," defnode: undefined expr";
    my $value = shift || croak __PACKAGE__," defnode: undefined value";

    return ($self->{aug_c} -> defnode($name, $expr, $value)) ;
}

=head2 get( path )

Lookup the value associated with C<path>. Returns the value associated
with C<path> if C<path> matches exactly one node. If PATH matches no
nodes or more than one node, returns undef.

=cut

sub get {
    my $self = shift ;
    my $path = shift || croak __PACKAGE__," get: undefined path";

    return $self->{aug_c} -> get($path) ;
}

=head2 set ( path, value )

Set the value associated with C<path> to C<value>. C<value> is copied
into Augeas internal data structure. Intermediate entries are created
if they don't exist. Return 1 on success, 0 on error. It is an error
if more than one node matches C<path>.

=cut

sub set {
    my $self  = shift ;
    my $path  = shift || croak __PACKAGE__," set: undefined path";
    my $value = shift ;

    croak __PACKAGE__," set: undefined value" unless defined $value;

    my $result ;
    my $ret = $self->{aug_c} -> set($path,$value) ;

    return 1 if $ret == 0;

    $self -> print('/augeas') ;
    croak __PACKAGE__," set: error with path $path";
}

=head2 insert ( label, before | after , path )

Create a new sibling C<label> for C<path> by inserting into the tree
just before or just after C<path>.

C<path> must match exactly one existing node in the tree, and C<label>
must be a label, i.e. not contain a '/', '*' or end with a bracketed
index '[N]'.

Return 1 on success, and 0 if the insertion fails.

=cut 

sub insert {
    my $self   = shift ;
    my $label  = shift || croak __PACKAGE__," insert: undefined label";
    my $where  = shift || croak __PACKAGE__," insert: undefined 'where'";
    my $path   = shift || croak __PACKAGE__," insert: undefined path";

    my $before = $where eq 'before' ? 1
               : $where eq 'after'  ? 0
	       :                      undef ;
    croak __PACKAGE__," insert: 'where' must be 'before' or 'after' not $where"
      unless defined $before ;

    if ($label =~ m![/\*]! or $label =~ /\]/ ) {
	croak __PACKAGE__," insert: invalid label '$label'";
    }

    my $result ;
    my $ret = $self->{aug_c} -> insert($path,$label, $before) ;

    return 1 if $ret == 0;

    $self->print('/augeas') ;
    croak __PACKAGE__," insert: error with path $path";
}

=head2 remove ( path )

Remove path and all its children. Returns the number of entries
removed.  All nodes that match C<path>, and their descendants, are
removed. (C<remove> can also be called with C<rm>)

=cut 

sub rm {
    goto &remove ;
}

sub remove {
    my $self   = shift ;
    my $path   = shift || croak __PACKAGE__," remove: undefined path";

    return $self->{aug_c} -> rm($path) ;
}

=head2 move ( src, dest )

Move the node SRC to DST. SRC must match exactly one node in the
tree. DST must either match exactly one node in the tree, or may not
exist yet. If DST exists already, it and all its descendants are
deleted. If DST does not exist yet, it and all its missing ancestors
are created.

Note that the node SRC always becomes the node DST: when you move
C</a/b> to C</x>, the node C</a/b> is now called C</x>, no matter
whether C</x> existed initially or not. (C<move> can also be called
with C<mv>)

Returns 1 in case of success, 0 otherwise.

=cut

sub mv {
    goto &move ;
}

sub move {
    my $self   = shift ;
    my $src    = shift || croak __PACKAGE__," move: undefined src";
    my $dst    = shift || croak __PACKAGE__," move: undefined dst";

    my $result = $self->{aug_c} -> mv($src,$dst) ;
    return $result == 0 ? 1 : 0 ;
}

=head2 match ( pattern )

Returns an array of the elements that match of the path expression
C<pattern>. The returned paths are sufficiently qualified to make sure
that they match exactly one node in the current tree.

=cut

sub match {
    my $self = shift ;
    my $pattern = shift || croak __PACKAGE__," match: undefined pattern";

    # Augeas 0.4.0 is a little picky about trailing slashes
    $pattern =~ s!/$!!;
    return $self->{aug_c} -> match($pattern) ;

}

=head2 count_match ( pattern )

Same as match but return the number of matching element in manner more
efficient than using C<scalar match( pattern )>

=cut

sub count_match {
    my $self = shift ;
    my $pattern = shift || croak __PACKAGE__," count_match: undefined pattern";

    # Augeas 0.4.0 is a little picky about trailing slashes
    $pattern =~ s!/$!!;
    return $self->{aug_c} -> count_match($pattern) ;
}

=head2 save

Write all pending changes to disk. Return 0 if an error is
encountered, 1 on success. Only files that had any changes made to
them are written. C<save> will follow backup files as specified with
Config::Augeas::new C<backup> parameter.

=cut

sub save {
    my $self   = shift ;
    my $ret = $self->{aug_c} -> save() ;
    return $ret == 0 ? 1 : 0 ;
}

=head2 print ( [ path  , [ file ] ] )

Print each node matching C<path> and its descendants on STDOUT or in a file

The second parameter can be :

=over

=item *

A file name. 

=item *

Omitted. In this case, print to STDOUT

=back

If path is omitted, all Augeas nodes will be printed.

Example:

  $aug->print ; # print all nodes to STDOUT
  $aug->print('/files') ; # print all file nodes to STDOUT
  $aug->print('/augeas/','bar.txt'); # print Augeas meta data in bar.txt

WARNING: The orders of the parameter are reversed compared to Augeas C
API.

=cut

sub print {
    my $self   = shift ;
    my $path   = shift || '' ;
    my $f_param     = shift ;

    my $fd = IO::File->new ;

    if (defined $f_param) {
	$fd->open($f_param,"w");
    }
    else {
	# stdio 
	$fd->fdopen(fileno(STDOUT),"w");
    } 

    my $ret = $self->{aug_c} -> print($fd,$path) ;
    return $ret == 0 ? 1 : 0 ;
}

1;

__END__

=head1 SEE ALSO

=over 

=item * 

http://augeas.net/ : Augeas project page

=item *

L<Config::Model> : Another kind of configuration editor (with optional
GUI and advanced validation).

=item *

Augeas mailing list: http://augeas.net/developers.html

=back

=head1 AUTHOR

Dominique Dumont, E<lt>ddumont at cpan dot org@<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Dominique Dumont

This library is free software; you can redistribute it and/or modify
it under the LGPL terms.

=cut
