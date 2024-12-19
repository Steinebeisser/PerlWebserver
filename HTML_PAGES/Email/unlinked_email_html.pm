package unlinked_email_html;

use strict;
use warnings;

sub get_unlinked_email {
    my ($email) = @_;
    my $html = <<HTML;
    <h1>Unlinked email</h1>
    <p>Email $email is now unlinked from your account</p>
HTML

    return $html;
}

1;