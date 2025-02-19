package get_friends;

use strict;
use warnings;


my %request_types = (
    "received" => \&friend_utils::get_received_requests,
    "sent" => \&friend_utils::get_sent_requests,
);

sub get_friend_requests {
    my ($client_socket, $route) = @_;

    if (!$main::user) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_401("Unauthorized"));
        return;
    }

    my ($request_type) = $route =~ /\/friends\/requests\/(.+)/;
    print("REQUEST TYPE: $request_type\n");
    if (!exists $request_types{$request_type}) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_400("Bad Request"));
        return;
    }

    return $request_types{$request_type}->($client_socket, $route);
}

1;