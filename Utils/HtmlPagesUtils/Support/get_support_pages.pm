package get_support_pages;

use strict;
use warnings;

sub get_starting_page {
    my ($client_socket) = @_;

    my $html = get_choose_request_support_page::get_choose_request_support_page();
    return $html;
}

1;