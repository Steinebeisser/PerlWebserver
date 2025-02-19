package post_friends;

use strict;
use warnings;

use Cwd;
use JSON;

my %request_types = (
    "accept" => \&friend_utils::accept_friend_request,
    "reject" => \&friend_utils::reject_friend_request,
    "cancel" => \&friend_utils::cancel_friend_request,
    "add" => \&friend_utils::send_friend_request
);
sub post_friend_request {
    my ($client_socket, $route, $temp_file) = @_;
    print($route."\n");
    print("HELLO\n");
    my $sender_uuid = $main::user->{uuid};

    my ($type) = $route =~ /friends\/request\/(.*)/;
    print("TYPE: $type\n");

    if (!$sender_uuid) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_401("Unauthorized"));
        return;
    }

    
    if (!exists $request_types{$type}) {
        print("BAD REQUEST\n");
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_400("Bad Request"));
        return;
    }

    return $request_types{$type}->($client_socket, $route, $temp_file);
}

1;