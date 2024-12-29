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
    if (!$client_socket) {
        return;
    }
    send($client_socket, $response, 0) or return;
}
sub serve_error {
    my ($client_socket, $error) = @_;
    if (!$client_socket) {
        return;
    }
    if (!$error) {
        $error = HTTP_RESPONSE::ERROR_500("Internal Server Error");
    }
    send_response($client_socket, $error);
    close($client_socket);
}

sub encode_characters {
    my ($string) = @_;
    $string =~ s/&/&amp;/g;
    $string =~ s/</&lt;/g;
    $string =~ s/>/&gt;/g;
    $string =~ s/"/&quot;/g;
    $string =~ s/'/&#39;/g;
    return $string;
}

sub parse_input {
    my ($string) = @_;

    $string = user_utils::decode_uri($string);
    $string =~ s/\+/ /g;

    return $string;
}
1;