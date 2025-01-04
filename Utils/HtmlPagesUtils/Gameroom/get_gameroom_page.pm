package get_gameroom_page;

use strict;
use warnings;

sub get_gameroom {
    my ($client_socket) = @_;

    my $html = get_gameroom::get_gameroom();

    return $html;
}

1;