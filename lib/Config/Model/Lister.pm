package Config::Model::Lister;

use strict;
use warnings;
use Exporter;

use vars qw/@EXPORT/;

@EXPORT = qw(applications models);

sub available_models {
    my $test = shift || 0;

    my ( %categories, %appli_info, %applications );
    my %done_cat;
    my @dir_to_scan = $test ? qw/lib/ : @INC;

    foreach my $dir ( map { glob("$_/Config/Model/*.d") } @dir_to_scan ) {
        my ($cat) = ( $dir =~ m!.*/([\w\-]+)\.d! );

        if ( $cat !~ /^user|system|application$/ ) {
            warn "available_models: skipping unexpected category: $cat\n";
            next;
        }

        foreach my $file ( sort glob("$dir/*") ) {
            next if $file =~ m!/README!;
            my ($appli) = ( $file =~ m!.*/([\w\-]+)! );
            open( F, $file ) || die "Can't open file $file:$!";
            while (<F>) {
                chomp;
                s/^\s+//;
                s/\s+$//;
                s/#.*//;
                my ( $k, $v ) = split /\s*=\s*/;
                next unless $v;
                if ( $k =~ /model/i ) {
                    push @{ $categories{$cat} }, $appli unless $done_cat{$cat}{$appli};
                    $done_cat{$cat}{$appli} = 1;
                }

                $appli_info{$appli}{$k} = $v;
                $applications{$appli} = $v if $k =~ /model/i;
            }
        }
    }
    return \%categories, \%appli_info, \%applications;
}

sub models {
    my @i = available_models;
    return join( ' ', sort values %{ $i[2] } ) . "\n";
}

sub applications {
    my @i = available_models;
    return join( ' ', sort keys %{ $i[2] } ) . "\n";
}

1;

# ABSTRACT: List available models and applications

__END__

=head1 SYNOPSIS

 perl -MConfig::Model::Lister -e'print Config::Model::Lister::models;'

 perl -MConfig::Model::Lister -e'print Config::Model::Lister::applications;'

=head1 DESCRIPTION

Small modules to list available models or applications whose config
can be edited by L<config-edit>. This module is designed to be used
by bash completion.

=head1 FUNCTIONS

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

=head1 models

Returns a string with the list of models.

=head1 applications

Returns a string with the list of editable applications.

=head1 SUPPORT

CPAN RT system, Debian BTS or mailing list.

=head1 AUTHOR

Copyright 2011 Dominique Dumont

=cut
