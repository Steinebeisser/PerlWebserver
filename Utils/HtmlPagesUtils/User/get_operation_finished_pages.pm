package get_operation_finished_pages;

use strict;
use warnings;


sub get_logined {
    my ($username) = @_;
    return logined_html::new($username);
}

sub get_logout_html {
    return logout_html::get_logout();
}

sub get_registered_html {
    my ($username) = @_;
    return registered_html::get_registered($username);
}

sub get_email_unlinked {
    my ($email) = @_;
    return unlinked_email_html::get_unlinked_email($email);
}
1;