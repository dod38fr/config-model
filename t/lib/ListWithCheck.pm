package ListWithCheck;
use v5.20;

use Mouse;
use Scalar::Util qw/weaken/;

extends qw/Config::Model::ListId/;

use feature qw/postderef signatures/;
no warnings qw/experimental::postderef experimental::signatures/;

sub check_foo_presence ($self, $error, $warn, $apply_fix, $silent = 0) {
    foreach my $val ($self->fetch_all_values(check => 'no')) {
        return if $val eq 'foo';
    }

    if ($apply_fix) {
        $self->push('foo');
    }
    else {
        push $warn->@*, "Missing foo value in " . $self->element_name;
        $self->inc_fixes;
    }
    return;
}

sub BUILD ($self, $) {
    weaken($self);
    $self->add_check_content( sub { $self->check_foo_presence(@_);} );
}

1;
