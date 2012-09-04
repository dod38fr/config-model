#    Copyright (c) 2010 Dominique Dumont.
#
#    This file is part of Config-Model.
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

package Config::Model::Annotation;

use Any::Moose ;
use English ;

use File::Path;
use IO::File ;
use Data::Dumper ;
#use Log::Log4perl qw(get_logger :levels);

use Config::Model::Exception ;
use Config::Model::Node ;
use Config::Model::ObjTreeScanner;

#use strict ;
use Carp;
#use warnings FATAL => qw(all);


use Carp qw/croak confess cluck/;

#my $logger = get_logger("Annotation") ;

=head1 NAME

Config::Model::Annotation - Read and write configuration annotations

=head1 SYNOPSIS

 use Config::Model ;
 use Log::Log4perl qw(:easy) ;
 Log::Log4perl->easy_init($WARN);

 # define configuration tree object
 my $model = Config::Model->new ;
 $model ->create_config_class (
    name => "MyClass",
    element => [ 
        [qw/foo bar/] => { 
            type => 'leaf',
            value_type => 'string'
        },
        baz => { 
            type => 'hash',
            index_type => 'string' ,
            cargo => {
                type => 'leaf',
                value_type => 'string',
            },
        },
        
    ],
 ) ;

 my $inst = $model->instance(root_class_name => 'MyClass' );

 my $root = $inst->config_root ;

 # put some data in config tree the hard way
 $root->fetch_element('foo')->store('yada') ;
 $root->fetch_element('baz')->fetch_with_id('en')->store('hello') ;

 # put annotation the hard way
 $root->fetch_element('foo')->annotation('english') ;
 $root->fetch_element('baz')->fetch_with_id('en')->annotation('also english') ;

 # put more data the easy way
 my $step = 'baz:fr=bonjour#french baz:hr="dobar dan"#croatian';
 $root->load( step => $step ) ;

 # dump resulting tree with annotations
 print $root->dump_tree;

 # save annotations
 my $annotate_saver = Config::Model::Annotation
  -> new (
          config_class_name => 'MyClass',
          instance => $inst ,
	  root_dir => '/tmp/', # for test
         ) ;
 $annotate_saver->save ;

 # now check content of /tmp/config-model/MyClass-note.pl


=head1 DESCRIPTION

This module provides an object that read and write annotations (a bit
like comments) to and from a configuration tree and save them in a file (not 
configuration file)

Depending on the effective id of the process, the annotation will be
saved in:

=over 

=item * 

C<< /var/lib/config-model/<model_name>-note.yml >> for root (EUID == 0)

=item *

C<< ~/.config-model/<model_name>-note.yml >> for normal user (EUID > 0)

=back

=head1 CONSTRUCTOR

Quite standard. The constructor is passed a L<Config::Model::Instance>
object.


=cut

has 'instance' => ( is => 'ro', isa => 'Config::Model::Instance', required => 1 );
has 'config_class_name' => ( is => 'ro', isa => 'Str', required => 1 ) ;
has 'file'     => ( is => 'ro', isa => 'Str', lazy =>1, builder => '_set_file' ) ;
has 'dir'      => ( is => 'ro', isa => 'Str', lazy =>1, builder => '_set_dir' ) ;
has 'root_dir'     => ( is => 'ro', isa => 'Str|Undef', default => '') ;

sub _set_file {
    my $self = shift ;
    return $self->dir.$self->config_class_name . '-note.pl' ; 
}

sub _set_dir {
    my $self = shift ;
    my $dir = $self->root_dir ? $self->root_dir 
             :  $EUID       ? "/var/lib/" 
             :                "~/." ;
    $dir .= "config-model/" ;
    return $dir ;
}

#sub new {
#    my $proto = shift ;
#    my $class = ref($proto) || $proto ;
#    my $instance = shift ;
#
#    my $self 
#      = {
#	 instance => $instance ,
#	};
#
#    bless $self, $class;
#
#}
#

=head1 METHODS

=head2 save()

Save annotations in a file (See L<DESCRIPTION>)

=cut

sub save {
    my $self = shift ;

    my $dir = $self->dir ;
    mkpath ($dir, { mode => 0755, verbose => 0}) unless -d $dir ;
    my $h = $self->get_annotation_hash ;
    my $data = Dumper($h) ;
    my $io = IO::File->new($self->file, 'w',0644) 
      || croak "Can't open $dir".$self->file.": $!";
    print $io $data ;
    $io->close ;
}

sub get_annotation_hash {
    my $self = shift ;

    my %data ;
    my $scanner = Config::Model::ObjTreeScanner
      ->new(
	    leaf_cb         => \&my_leaf_cb ,
	    hash_element_cb => \&my_hash_element_cb,
	    list_element_cb => \&my_list_element_cb,
	    node_element_cb => \&my_node_element_cb,
	    fallback        => 'all',
	   ) ;
    my $root = $self->instance->config_root ;

    $scanner->scan_node(\%data,$root) ;
    return \%data ;
}

# WARNING: not a method
sub my_hash_element_cb {
    my ($scanner, $data_ref,$node,$element_name,@keys) = @_ ;

    # custom code using $data_ref
    store_note_in_data($data_ref, $node->fetch_element($element_name) ) ;

    # resume exploration
    map {$scanner->scan_hash($data_ref,$node,$element_name,$_)} @keys ;
}

# WARNING: not a method
sub my_node_element_cb {
    my ($scanner, $data_ref,$node,$element_name,$key, $contained_node) = @_;

    # your custom code using $data_ref
    store_note_in_data($data_ref, $contained_node ) ;

    # explore next node 
    $scanner->scan_node($data_ref,$contained_node);
}

# WARNING: not a method
sub my_list_element_cb {
     my ($scanner, $data_ref,$node,$element_name,@idx) = @_ ;

     # custom code using $data_ref
    store_note_in_data($data_ref, $node->fetch_element($element_name) ) ;

    # resume exploration (if needed)
     map {$scanner->scan_list($data_ref,$node,$element_name,$_)} @idx ;

     # note: scan_list and scan_hash are equivalent
  }


# WARNING: not a method
sub my_leaf_cb {
    my ($scanner, $data_ref,$node,$element_name,$index, $leaf_object) = @_ ;
    store_note_in_data($data_ref, $leaf_object) ;
}

# WARNING: not a method
sub store_note_in_data {
    my ($data_ref,$obj) = @_ ;

    my $note = $obj -> annotation ;
    return unless $note ;
    
    my $key = $obj -> location ;
    $data_ref->{$key} = $note ;
}

=head2 load()

Loads annotations from a file (See L<DESCRIPTION>)

=cut

sub load {
    my $self = shift ;
    my $f = $self->file ;
    return unless -e $f ;
    my $hash = do $f || croak "can't do $f:$!";
    my $root = $self->instance->config_root ;

    foreach my $path (keys %$hash ) {
	my $obj = eval {$root ->grab(step => $path, autoadd => 0) } ;
	next if $@ ; # skip annotation of unknown elements 
	$obj->annotation($hash->{$path}) ;
    }
}

no Any::Moose ;

__PACKAGE__ -> meta->make_immutable;

1;

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>, 
L<Config::Model::Node>, 
L<Config::Model::Loader>,
L<Config::Model::Searcher>,
L<Config::Model::Value>,

=cut

