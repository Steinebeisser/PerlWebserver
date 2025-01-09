package post_streaming_pages;

use strict;
use warnings;

sub post_streaming_manage_channel {
    my ($client_socket, $route, $temp_file) = @_;
    if (!$main::user) {
        return;
    }

    my ($username, $category, $video_id, $update_item) = $route =~ /\/manage\/channel\/([^\/]+)\/([^\/]+)(?:\/([^\/]+))?\/(.*)/;
    if (!$username || !$category || !$update_item) {
        print("ROUTE: $route\n");
        print("USERNAME: $username\n");
        print("CATEGORY: $category\n");
        print("UPDATE ITEM: $update_item\n");
        die;
    }

    print("USERNAME: $username\n");
    print("CATEGORY: $category\n");
    print("VIDEO ID: $video_id\n");
    print("UPDATE ITEM: $update_item\n");


    if (!channel_utils::has_manage_access(user_utils::get_uuid_by_username($username))) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_401("Unauthorized"));
    }

    channel_utils::update_channel_item($username, $category, $video_id, $update_item, $temp_file, $client_socket);
}

1;