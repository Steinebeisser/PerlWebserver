package friend_utils;

use strict;
use warnings;

use JSON;
use Cwd;

sub send_friend_request {
    my ($sender_uuid, $friend_uuid, $client_socket) = @_;

    my $base_dir = getcwd();
    my $friend_path = "$base_dir/Data/UserData/Users/$friend_uuid/Friends";
    if (!-d $friend_path) {
        mkdir($friend_path) or do {
            http_utils::send_http_response($client_socket, HTTP_RESPONSE::ERROR_500("Internal Server Error"));
            return;
        };
    }

    my $requests_file = "$friend_path/requests.json";
    if (!-e $requests_file) {
        open my $fh, '>', $requests_file or do {
            http_utils::send_http_response($client_socket, HTTP_RESPONSE::ERROR_500("Internal Server Error"));
            return;
        };
        print $fh "[]";
        close($fh);
    }

    open my $fh, '<', $requests_file;
    my $requests_data = do { local $/; <$fh> };
    close $fh;

    my $requests = decode_json($requests_data);

    push @$requests, $sender_uuid;

    open $fh, '>', $requests_file;
    print $fh encode_json($requests);
    close $fh;

    my $sender_path = "$base_dir/Data/UserData/Users/$sender_uuid/Friends";
    if (!-d $sender_path) {
        mkdir($sender_path) or do {
            http_utils::send_http_response($client_socket, HTTP_RESPONSE::ERROR_500("Internal Server Error"));
            return;
        };
    }

    my $sent_requests_file = "$sender_path/sent_requests.json";
    if (!-e $sent_requests_file) {
        open $fh, '>', $sent_requests_file or do {
            http_utils::send_http_response($client_socket, HTTP_RESPONSE::ERROR_500("Internal Server Error"));
            return;
        };
        print $fh "[]";
        close($fh);
    }

    open $fh, '<', $sent_requests_file;
    my $sent_requests_data = do { local $/; <$fh> };
    close $fh;

    my $sent_requests = decode_json($sent_requests_data);

    push @$sent_requests, $friend_uuid;

    open $fh, '>', $sent_requests_file;
    print $fh encode_json($sent_requests);
    close $fh;
}

1;