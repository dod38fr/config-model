package Config::Model::Lister;

=pod

=head1 NAME

Config::Model::Lister - List available models and applications

=head1 SYNOPSIS

 perl -MConfig::Model::Lister -e'print Config::Model::Lister::models;'

 perl -MConfig::Model::Lister -e'print Config::Model::Lister::applications;'

=head1 DESCRIPTION

Small modules to list available models or applications whose config
can be edited by L<config-edit>. This module is designed to be used
by bash completion.

=head1 FUNCTIONS

=cut

use strict;
use warnings;
use Exporter;

use vars qw/@EXPORT/;

@EXPORT = qw(applications models) ;

=head1 available_models

Returns an array of 3 hash refs:

=over 

=item *

category (system or user or application) => application list. E.g. 

 { system => [ 'popcon' , 'fstab'] }

=item *

application => { model => 'model_name', ... }

=item *

application => model_name

=back

=cut

sub available_models {
   
    my $path = $INC{"Config/Model/Lister.pm"} ;
    $path =~ s!/Lister\.pm!! ;
    my (%categories, %appli_info, %applications ) ;

    foreach my $dir (glob("$path/*.d")) {
        my ($cat) = ( $dir =~ m!.*/([\w\-]+)\.d! );

        if ($cat !~ /^user|system|application$/) {
            warn "available_models: skipping unexpected category: $cat\n";
            next;
        }
        
        foreach my $file (sort glob("$dir/*")) {
            next if $file =~ m!/README! ;
            my ($appli) = ($file =~ m!.*/([\w\-]+)! );
            open (F, $file) || die "Can't open file $file:$!" ;
            while (<F>) {
                chomp ;
                s/^\s+// ;
                s/\s+$// ;
                s/#.*// ;
                my ($k,$v) = split /\s*=\s*/ ;
                next unless $v ;
                push @{$categories{$cat}} , $appli if $k =~ /model/i;
                $appli_info{$appli}{$k} = $v ; 
                $applications{$appli} = $v if $k =~ /model/i; 
            }
        }
    }
    return \%categories, \%appli_info, \%applications ;
}

=head1 models

Returns a string with the list of models.

=cut

sub models {
    my @i = available_models ;
    return join( ' ',  sort values %{$i[2]} )."\n"; 
}

=head1 applications

Returns a string with the list of editable applications.

=cut

sub applications {
    my @i = available_models ;
    return join( ' ',  sort keys   %{$i[2]} )."\n"; 
}

1;

=pod

=head1 SUPPORT

CPAN RT system, Debian BTS or mailing list.

=head1 AUTHOR

Copyright 2011 Dominique Dumont

=cut
