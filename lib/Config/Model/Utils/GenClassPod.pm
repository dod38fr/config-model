package Config::Model::Utils::GenClassPod;

# ABSTRACT: generate pod documentation from configuration models

use strict;
use warnings;
use 5.010;
use parent qw(Exporter);
our @EXPORT = qw(gen_class_pod);

use lib qw/lib/;
use Path::Tiny ;
use Config::Model ;             # to generate doc

sub gen_class_pod {
    my $cm = Config::Model -> new(model_dir => "lib/Config/Model/models") ;
    my %done;

    my @models = @_ ? @_ :
        map { /model\s*=\s*([\w:-]+)/; $1; }
        grep { /^\s*model/; }
        map  { $_->lines; }
        map  { $_->children; }
        path ("lib/Config/Model/")->children(qr/\.d$/);

    foreach my $model (@models) {
        # %done avoid generating doc several times (generate_doc scan docs for
        # classes referenced by the model with config_class_name parameter)
        print "Checking doc for model $model\n";
        $cm->load($model) ;
        $cm->generate_doc ($model,'lib', \%done) ;
    }
}

1;

__END__

=head1 SYNOPSIS

 use Config::Model::Utils::GenClassPod;
 gen_class_pod;

 # or

 gen_class_pod('Foo','Bar',...)

=head1 DESCRIPTION

This module provides a single exported function: C<gen_class_pod>.

This function scans C<./lib/Config/Model/models/*.d>
and generate pod documentation for each file found there using
L<Config::Model::generate_doc|Config::Model/"generate_doc ( top_class_name , directory , [ \%done ] )">

You can also pass one or more class names. C<gen_class_pod> writes
the documentation for each passed class and all other classes used by
the passed classes.

=cut
