package http_utils;

use strict;
use warnings;

sub send_http_response {
    my ($client_socket, $response) = @_;
    print $client_socket $response;
    # print("SENT RESPONSE, CLOSING SOCKET\n");
    close($client_socket);
}

sub send_response {
    my ($client_socket, $response) = @_;
    if (!$response) {
        $response = HTTP_RESPONSE::ERROR_500("Internal Server Error");
    }
    send($client_socket, $response, 0);
}
sub serve_error {
    my ($client_socket, $error) = @_;
    send_response($client_socket, $error);
    close($client_socket);
}

1;