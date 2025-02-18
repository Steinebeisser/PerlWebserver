package post_friends;

use strict;
use warnings;

use Cwd;
use JSON;

sub post_friend_request {
    my ($client_socket, $route) = @_;

    my $sender_uuid = $main::user->{uuid};
    
    if (!$sender_uuid) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_401("Unauthorized"));
        return;
    }

    my ($friend_username) = $route =~ /friend\/request\/(.+)/;

    my $friend_uuid = user_utils::get_uuid_by_username($friend_username);
    if (!$friend_uuid) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_400("User Not Found"));
        return;
    }

    if ($sender_uuid eq $friend_uuid) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_400("Cannot send friend request to yourself"));
        return;
    }

    friend_utils::send_friend_request($sender_uuid, $friend_uuid, $client_socket);
}

1;