#    Copyright (c) 2005-2011 Dominique Dumont.
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

package Config::Model::TreeSearcher ;

use Any::Moose ;
use Any::Moose '::Util::TypeConstraints';

use Log::Log4perl qw(get_logger :levels);
use Config::Model::Exception ;
use Config::Model::ObjTreeScanner ;
use Carp;

my @search_types = qw/element value key summary description help/;
enum ('SearchType' =>  @search_types, 'all');

has 'node'  => ( is => 'ro', isa => 'Config::Model::Node' , 
                  weak_ref => 1, required => 1 );

has 'type' => ( is => 'ro', isa => 'SearchType' ) ;

has '_type_hash' => (
    is =>'rw',
    isa => 'HashRef[Bool]',
    builder => '_build_type_hash',
    lazy => 1,
) ;

my $logger = get_logger("TreeSearcher") ;

sub _build_type_hash {
    my $self = shift ;
    my $t = $self->type ;
    my $def = $t eq 'all' ? 1 : 0 ;
    my %res=  map { $_ => $def ;} @search_types ;
    $res{$t} = 1 unless $t eq 'all' ;
    return \%res ;
}

sub search {
    my $self = shift ;
    my $string = shift ; # string to search, can be a regexp 
    
    $logger->debug( "TreeSearcher: creating scanner for ".$self->node->name);
    my $reg = qr/$string/i ;

    my @scanner_args ;
    my $need_search =  $self->_build_type_hash ;
     
    push @scanner_args, leaf_cb => sub { 
        my ($scanner, $data_ref, $node,$element_name,$index, $leaf_object) = @_ ;

        my $loc = $leaf_object->location ;
        $logger->debug( "TreeSearcher: scanning leaf $loc");
            
        my $v = $leaf_object->fetch(check => 'no') ;
        if ($need_search->{value} and defined $v and $v =~ $reg ) {
            $data_ref->($loc) ;
        }
        if ($need_search->{help}) {
            my $help_ref = $leaf_object->get_help ;
            $data_ref->($loc)
                if grep { $_ =~ $reg ; } values %$help_ref ;
        }
    } ;

    push @scanner_args, hash_element_cb => sub { 
        my  ($scanner, $data_ref,$node,$element_name,@keys) = @_ ;
        my $loc = $node->location ;
        $loc .= ' ' if $loc ;
        $loc .= $element_name ;

        $logger->debug( "TreeSearcher: scanning hash $loc");

        foreach my $k (@keys) {
            if ($need_search->{key} and $k =~ $reg) {
                my $hloc= $node->fetch_element($element_name)->fetch_with_id($k)->location;
                $data_ref->($hloc) ;
            }
            $scanner->scan_hash($data_ref,$node,$element_name,$k) ;
        }
     } ;

    push @scanner_args,  node_content_cb => sub { 
        my ($scanner, $data_ref,$node,@element) = @_ ;
        my $loc = $node->location ;
        $logger->debug( "TreeSearcher: scanning node $loc");

        foreach my $e (@element) {
            my $store = 0;
            
            map { $store = 1 if $need_search->{$_} and 
                  $node->get_help($_ => $e) =~ $reg 
            } qw/description summary/;
            $store = 1 if $need_search->{element} and $e =~ $reg ;
            
            $data_ref->( $loc ? $loc.' '.$e : $e )  if $store ;

            $scanner->scan_element($data_ref, $node,$e);
        }
    } ;

    
    my $scan = Config::Model::ObjTreeScanner-> new (
        @scanner_args ,
    ) ;

    # use hash to avoid duplication of path
    my @loc ;
    my $store_sub = sub {
        my $p = shift ;
        return if @loc and $loc[$#loc] eq $p ;
        $logger->debug( "TreeSearcher: storing location '$p'");
        push @loc,$p ;
    } ;
    $scan->scan_node($store_sub, $self->node) ;
    
    return @loc ;
}


no Any::Moose ;
1;

=head1 NAME

Config::Model::TreeSearcher - Search tree for match in value, description...

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

 my $step = 'baz:fr=bonjour baz:hr="dobar dan" foo="journalled"';
 $root->load( step => $step ) ;

 my @result = $root->tree_searcher(type => 'value')->search('jour');
 print join("\n",@result),"\n" ;
 # print 
 #  baz:fr
 #  foo

=head1 DESCRIPTION

This class provides a way to search the content of a configuration tree. 
Given a keyword or a pattern, the search method will scan the tree to find
a value, a description or anything that match the given pattern (or keyword).

=head1 Constructor

=head2 new (type => [ value | description ... ] )

Creates a new searcher object. The C<type> parameter can be:

=over 

=item element 

=item value 

=item key 

=item summary 

=item description 

=item help

=item all

Search in all the items above

=back

=head1 Methods

=head2 search(keyword)

Search the keyword or pattern in the tree. The search is done in a case
insensitive manner. Returns a list of path pointing 
to the matching tree element. See L<Config::Model::AnyThing/grab(...)> for details
on the path syntax.

=head1 BUGS

Creating a class with just one search method may be overkill. OTOH, it may 
be extended later to provide iterative search.

=head1 AUTHOR

Dominique Dumont, (ddumont at cpan dot org)

=head1 SEE ALSO

L<Config::Model>,
L<Config::Model::SearchElement>,
L<Config::Model::AnyThing>
 
=cut

