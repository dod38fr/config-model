# $Author:$
# $Date:$
# $Revision:$

#    Copyright (c) 2008 Peter Knowles.
#
#    This file is part of Config-Model-Krb5.
#
#    Config-Xorg is free software; you can redistribute it and/or
#    modify it under the terms of the GNU Lesser Public License as
#    published by the Free Software Foundation; either version 2.1 of
#    the License, or (at your option) any later version.
#
#    Config-Xorg is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Lesser Public License for more details.
#
#    You should have received a copy of the GNU Lesser Public License
#    along with Config-Model; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA

package Config::Model::Krb5;

use strict;
use warnings;

use Carp;
use IO::File;
use Log::Log4perl;
use File::Copy;

#use Parse::RecDescent ;
use vars qw($VERSION);    # $grammar $parser) ;

$VERSION = sprintf "1.%04d", q$Revision: 696 $ =~ /(\d+)/;

my $logger = Log::Log4perl::get_logger(__PACKAGE__);

sub krb5_read {
    my %args        = @_;
    my $config_root = $args{object}
      || croak __PACKAGE__, " krb5_read: undefined config root object";
    my $dir = $args{conf_dir}
      || croak __PACKAGE__, " krb5_read: undefined config dir";

    unless ( -d $dir ) {
        croak __PACKAGE__, " krb5_read: unknown config dir $dir";
    }

    my $file = "$dir/krb5.conf";
    unless ( -r "$file" ) {
        croak __PACKAGE__, " krb5_read: unknown file $file";
    }

    $logger->info("loading config file $file");

    my $fh = new IO::File $file, "r";

    #&clear ; # reset Match closure

    if ( defined $fh ) {
        my @file = $fh->getlines;
        $fh->close;

        # remove comments and cleanup beginning of line
        map { s/#.*//; s/^\s+//; } @file;

        my $configlines    = \@file;
        my $config         = {};
        my $currentloc     = \$config;
        my @nestedelements = ();
        foreach my $line (@$configlines) {

            # Skip Blank Lines
            next if $line =~ /^\s*$/;

            # Skip Comments
            next if $line =~ /^\s*#/;

            # Section Header
            if ( $line =~ m/^\s*\[([^\]]+)\]/ ) {
                if ( !$config->{$1} ) {
                    $config->{$1} = {};
                    $currentloc = \%{ $config->{$1} };
                }
                next;
            }

            # Simple Binding
            if ( $line =~ m/^\s*([^\s]+)\s*=\s*([^{\s][^\s]*)\s*$/ ) {
                if ( !$currentloc->{$1} ) {
                    $currentloc->{$1} = ();
                }
                push( @{ $currentloc->{$1} }, $2 );
                next;
            }

            # Bracketed Binding
            if ( $line =~ m/^\s*([^\s]+)\s*=\s*{.*$/ ) {
                if ( !$currentloc->{$1} ) {
                    $currentloc->{$1} = {};
                    push( @nestedelements, $currentloc );
                    $currentloc = \%{ $currentloc->{$1} };
                }
                next;
            }

            # End of Bracketed Binding
            if ( $line =~ /^\s*}.*$/ ) {
                $currentloc = pop(@nestedelements);
                next;
            }
        }

        #use Data::Dumper;
        #print Dumper($config);
        #exit;

        my $current_node = $config_root;

        # Simple sections (i.e. tag=value)
        my @simplesections = ( 'libdefaults', 'login', 'dbdefaults' );
        foreach my $sectionname (@simplesections) {
            my $sectionnode = $config_root->fetch_element($sectionname);
            my $section     = $config->{$sectionname};
            if ($section) {
                foreach my $tagname ( sort( keys %$section ) ) {
                    my $tagvalue = $section->{$tagname};
                    my $element  = $sectionnode->fetch_element($tagname);
                    $element->store( $tagvalue->[0] );
                }
            }
        }

        # Domain -> Realm mapping section
        my $sectionnode = $config_root->fetch_element('domain_realm');
        my $section     = $config->{'domain_realm'};
        if ($section) {
            foreach my $tagname ( sort( keys %$section ) ) {
                my $tagvalue = $section->{$tagname};
                my $element  = $sectionnode->fetch_with_id($tagname);
                $element->store( $tagvalue->[0] );
            }
        }

        # Database Modules section
        my $configsection = $config_root->fetch_element('dbmodules');
        $section = $config->{'dbmodules'};
        if ($section) {
            foreach my $configname ( sort( keys %$section ) ) {
                my $thisconfigsection = $configsection->fetch_with_id($configname);
                foreach my $tag ( sort( keys %{ $section->{$configname} } ) ) {
                    my $tagvalue = $section->{$configname}->{$tag};
                    my $element  = $thisconfigsection->fetch_element($tag);
                    $element->store( $tagvalue->[0] );
                }
            }
        }

        # Realms section
        my $realmsection = $config_root->fetch_element('realms');
        $section = $config->{'realms'};
        if ($section) {
            foreach my $realmname ( sort( keys %$section ) ) {
                my $thisrealm = $realmsection->fetch_with_id($realmname);
                foreach my $tag ( sort( keys %{ $section->{$realmname} } ) ) {
                    my $tagvalue = $section->{$realmname}->{$tag};
                    my $element  = $thisrealm->fetch_element($tag);
                    if ( ( $tag eq 'kdc' ) || ( $tag eq 'admin_server' ) ) {
                        for ( my $i = 0 ; $i < scalar(@$tagvalue) ; $i++ ) {
                            my $elementsize   = $element->fetch_size;
                            my $nestedelement = $element->fetch_with_id($elementsize);
                            $nestedelement->store( $tagvalue->[$i] );
                        }
                    }
                    elsif ( ( $tag eq 'v4_instance_convert' ) || ( $tag eq 'auth_to_local_names' ) ) {
                        foreach my $subtag ( keys(%$tagvalue) ) {
                            my $nestedelement = $element->fetch_with_id($subtag);
                            $nestedelement->store( $tagvalue->{$subtag}->[0] );
                        }
                    }
                    else {
                        $element->store( $tagvalue->[0] );
                    }
                }
            }
        }

        # Appdefaults Section
        my $appdefaultssection = $config_root->fetch_element('appdefaults');
        $section = $config->{'appdefaults'};
        if ($section) {
            foreach my $tagname ( sort( keys %$section ) ) {
                if ( ref( $section->{$tagname} ) eq 'ARRAY' ) {

                    # Simple tag -> value binding
                    my $options = $appdefaultssection->fetch_element('option');
                    foreach my $value ( @{ $section->{$tagname} } ) {
                        my $elementsize   = $options->fetch_size;
                        my $nestedelement = $options->fetch_with_id($elementsize);
                        my $nestedtagname = $nestedelement->fetch_element('name');
                        my $nestedvalue   = $nestedelement->fetch_element('value');
                        $nestedtagname->store($tagname);
                        $nestedvalue->store($value);
                    }
                }
                elsif ( ref( $section->{$tagname} ) eq 'HASH' ) {

                    # This could be an application or realm.
                    my $nestedhash    = $appdefaultssection->fetch_element('subsection');
                    my $nestedobject  = $nestedhash->fetch_with_id($tagname);
                    my $configsection = $section->{$tagname};
                    foreach my $tagname ( sort( keys %$configsection ) ) {
                        if ( ref( $configsection->{$tagname} ) eq 'ARRAY' ) {

                            # Simple tag -> value binding
                            my $options = $nestedobject->fetch_element('option');
                            foreach my $value ( @{ $configsection->{$tagname} } ) {
                                my $elementsize   = $options->fetch_size;
                                my $nestedelement = $options->fetch_with_id($elementsize);
                                my $nestedtagname = $nestedelement->fetch_element('name');
                                my $nestedvalue   = $nestedelement->fetch_element('value');
                                $nestedtagname->store($tagname);
                                $nestedvalue->store($value);
                            }
                        }
                        elsif ( ref( $configsection->{$tagname} ) eq 'HASH' ) {

                            # If we're nested two deep by now, then this is actually a realm (inside an application)
                            my $nestedhash    = $nestedobject->fetch_element('subsection');
                            my $nestedobject  = $nestedhash->fetch_with_id($tagname);
                            my $configsection = $configsection->{$tagname};
                            foreach my $tagname ( sort( keys %$configsection ) ) {
                                if ( ref( $configsection->{$tagname} ) eq 'ARRAY' ) {

                                    # Simple tag -> value binding
                                    my $options = $nestedobject->fetch_element('option');
                                    foreach my $value ( @{ $configsection->{$tagname} } ) {
                                        my $elementsize   = $options->fetch_size;
                                        my $nestedelement = $options->fetch_with_id($elementsize);
                                        my $nestedtagname = $nestedelement->fetch_element('name');
                                        my $nestedvalue   = $nestedelement->fetch_element('value');
                                        $nestedtagname->store($tagname);
                                        $nestedvalue->store($value);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        # Logging Section
        my $loggingroot = $config_root->fetch_element('logging');
        $section = $config->{'logging'};
        if ($section) {
            foreach my $loggingtype ( ( 'kdc', 'admin_server', 'default' ) ) {
                my $loggingelement = $loggingroot->fetch_element($loggingtype);
                foreach my $loggingline ( @{ $section->{$loggingtype} } ) {
                    if ( ( $loggingline eq "STDERR" ) or ( $loggingline eq "CONSOLE" ) ) {
                        my $elementsize          = $loggingelement->fetch_size;
                        my $loggingconfigelement = $loggingelement->fetch_with_id($elementsize);
                        $loggingconfigelement->fetch_element('logging_type')->store($loggingline);
                    }
                    elsif ( $loggingline =~ m/^FILE(:|=)(.*)$/ ) {
                        my $elementsize          = $loggingelement->fetch_size;
                        my $loggingconfigelement = $loggingelement->fetch_with_id($elementsize);
                        $loggingconfigelement->fetch_element('logging_type')->store('FILE');
                        $loggingconfigelement->fetch_element('logging_config')->fetch_element('filename')->store($2);
                        if ( $1 eq ":" ) {
                            $loggingconfigelement->fetch_element('logging_config')->fetch_element('append')->store(1);
                        }
                        else {
                            $loggingconfigelement->fetch_element('logging_config')->fetch_element('append')->store(0);
                        }
                    }
                    elsif ( $loggingline =~ m/^DEVICE=(.*)$/ ) {
                        my $elementsize          = $loggingelement->fetch_size;
                        my $loggingconfigelement = $loggingelement->fetch_with_id($elementsize);
                        $loggingconfigelement->fetch_element('logging_type')->store('DEVICE');
                        $loggingconfigelement->fetch_element('logging_config')->fetch_element('devicename')->store($1);
                    }
                    elsif ( $loggingline =~ m/^SYSLOG(.*)$/ ) {
                        my $elementsize          = $loggingelement->fetch_size;
                        my $loggingconfigelement = $loggingelement->fetch_with_id($elementsize);
                        $loggingconfigelement->fetch_element('logging_type')->store('SYSLOG');
                        if ($1) {
                            my @severityfacility = split( /:/, $1 );
                            my $severity         = '';
                            my $facility         = '';
                            if ( scalar(@severityfacility) == 3 ) {
                                $severity = $severityfacility[1];
                                $facility = $severityfacility[2];
                            }
                            elsif ( scalar(@severityfacility) == 2 ) {
                                $severity = $severityfacility[1];
                            }
                            if ($severity) {
                                $loggingconfigelement->fetch_element('logging_config')->fetch_element('severity')->store($severity);
                            }
                            if ($facility) {
                                $loggingconfigelement->fetch_element('logging_config')->fetch_element('facility')->store($facility);
                            }
                        }
                    }
                    else { croak __PACKAGE__, " krb5_read: unknown logging method in logging section: $loggingline"; }
                }
            }
        }

        # CAPaths section
        my $realmslist = $config_root->fetch_element('capaths');
        $section = $config->{'capaths'};
        if ($section) {
            foreach my $realmname ( sort( keys %$section ) ) {
                my $realmobj = $realmslist->fetch_with_id($realmname);
                foreach my $tagname ( sort( keys %{ $section->{$realmname} } ) ) {
                    my $tagvalue         = $section->{$realmname}->{$tagname};
                    my $element          = $realmobj->fetch_element('paths');
                    my $elementsize      = $element->fetch_size;
                    my $realmpathelement = $element->fetch_with_id($elementsize);
                    $realmpathelement->fetch_element('realm')->store($tagname);
                    $realmpathelement->fetch_element('intermediate')->store( $tagvalue->[0] );
                }
            }
        }

    }
    else {
        die __PACKAGE__, " krb5_read: can't open $file:$!";
    }
}

1;
