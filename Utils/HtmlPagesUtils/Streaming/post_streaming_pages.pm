package post_streaming_pages;

use strict;
use warnings;

sub post_streaming_manage_channel {
    my ($client_socket, $route, $temp_file) = @_;
    if (!$main::user) {
        return;
    }

    print("ROUTE: $route\n");
    my ($channel_username, $category, $video_id, $update_item) = $route =~ /\/manage\/channel\/([^\/]+)(?:\/([^\/]+))(?:\/([^\/]+))?\/(.*)/;
    if (!$channel_username || !$category || !$update_item) {
        # print("ROUTE: $route\n");
        # print("channel_USERNAME: $channel_username\n");
        # print("CATEGORY: $category\n");
        # print("UPDATE ITEM: $update_item\n");
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_400("Bad Request"));
        return;
    }

    # print("ROUTE: $route\n");
    # print("channel_USERNAME: $channel_username\n");
    # print("CATEGORY: $category\n");
    # print("VIDEO ID: $video_id\n");
    # print("UPDATE ITEM: $update_item\n");

    if (!channel_utils::has_manage_access(user_utils::get_uuid_by_channel_username($channel_username))) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_401("Unauthorized"));
    }

    channel_utils::update_channel_item($channel_username, $category, $video_id, $update_item, $temp_file, $client_socket);
}

sub post_streaming_channel {
    my ($client_socket, $route, $temp_file) = @_;
    if (!$main::user) {
        return;
    }

    my ($channel_username, $category) = $route =~ /\/channel\/([^\/]+)\/(.*)/;
    if (!$channel_username || !$category) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_400("Bad Request"));
        return;
    }

    channel_utils::post_streaming_channel($channel_username, $category, $temp_file, $client_socket);
}

sub post_streaming_video {
    my ($client_socket, $route, $temp_file) = @_;
    if (!$main::user) {
        return;
    }

    my ($category, $video_id) = $route =~ /streaming\/video\/(.*)\/(.*)/;
    if (!$category || !$video_id) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_400("Bad Request"));
        return;
    }

    channel_utils::post_streaming_video($category, $video_id, $temp_file, $client_socket);
}

sub post_streaming_video_comments {
    my ($client_socket, $route, $temp_file) = @_;
    if (!$main::user) {
        return;
    }
    print("ROUTE: $route\n");

    my ($category, $video_id, $parent_comment_id) = $route =~ /update\/streaming\/video\/comments\/(.*)\/(.*)\/(\d+)/;

    if (!$video_id) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_400("Bad Request"));
        return;
    }

    video_utils::manage_video_comments($category, $video_id, $parent_comment_id, $temp_file, $client_socket);
}

sub post_streaming_video_replies {
    my ($client_socket, $route, $temp_file) = @_;
    if (!$main::user) {
        return;
    }

    my ($category, $video_id, $parent_comment_id, $comment_id) = $route =~ /video\/replies\/([^\/]+)\/([^\/]+)\/(\d+)\/(\d+)/;

    if (!$video_id) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_400("Bad Request"));
        return;
    }

    video_utils::manage_video_replies($category, $video_id, $parent_comment_id, $comment_id, $temp_file, $client_socket);
}
1;