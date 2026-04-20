package Config::Model::Lister;

use strict;
use warnings;
use Exporter;
use v5.20;

use vars qw/@EXPORT/;

use feature qw/postderef signatures/;
no warnings qw/experimental::postderef experimental::signatures/;

@EXPORT = qw(applications models);

sub available_models ($test = 0) {
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
            next if $file =~ /(~|\.bak|\.orig)$/;
            my ($appli) = ( $file =~ m!.*/([\w\-]+)! );

            # ensure that an appli file of a cat is not parsed twice
            # (useful in dev, where system appli file may clobber
            # appli file in dvelopment
            next if $done_cat{$cat}{$appli};

            $appli_info{$appli}{_file} = $file;
            $appli_info{$appli}{_category} = $cat;
            open my $fh, '<', $file || die "Can't open file $file:$!";
            while (my $line = <$fh>) {
                chomp($line);
                $line =~ s/^\s+//;
                $line =~ s/\s+$//;
                $line =~ s/#.*//;
                my ( $k, $v ) = split /\s*=\s*/, $line;
                next unless $v;
                if ( $k =~ /model/i ) {
                    push @{ $categories{$cat} }, $appli unless $done_cat{$cat}{$appli};
                    $done_cat{$cat}{$appli} = 1;
                }

                $appli_info{$appli}{$k} = $v;
                $applications{$appli} = $v if $k =~ /model/i;
            }
            die "Missing model line in file $file\n" unless $done_cat{$cat}{$appli};
        }
    }
    return \%categories, \%appli_info, \%applications;
}

sub models ($test = 0) {
    my @i = available_models($test);
    return join( ' ', sort values %{ $i[2] } ) . "\n";
}

sub applications ($test = 0) {
    my @i = available_models($test);
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
can be edited by L<cme>. This module is designed to be used by bash
completion.

All functions accept an optional boolean parameter. When true, only
the local C<lib> dir is scanned.

=head1 FUNCTIONS

=head1 available_models

Returns an array of 3 hash refs:

=over

=item *

category (system or user or application) => application list. E.g.

 { system => [ 'popcon' , 'fstab'] }

=item *

application name to model information. E.g.

 { 'popcon' => { model => 'Popcon', require_config_file => 1 }

=item *

application name to model name. E.g.

 { popcon => 'Popcon' }

=back

=head1 models

Returns a string with the list of models.

=head1 applications

Returns a string with the list of editable applications.

=cut
