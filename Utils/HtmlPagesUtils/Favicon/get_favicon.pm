package get_favicon;

use strict;
use warnings;

sub get_favicon {
    my ($client_socket) = @_;
    http_utils::send_http_response($client_socket, HTTP_RESPONSE::OK_FAVICON());
}

1;