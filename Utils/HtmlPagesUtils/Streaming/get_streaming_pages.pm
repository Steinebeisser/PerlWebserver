package get_streaming_pages;

use strict;
use warnings;

sub get_streaming_home {
    my ($client_socket) = @_;
    return streaming_html::get_streaming_home();
}

sub get_streaming_upload {
    my ($client_socket) = @_;
    if (!$main::user) {
        return "Need to be logged in to upload videos";
    }
    return streaming_upload::get_streaming_upload();
}

sub get_streaming_watch {
    my ($client_socket, $route) = @_;
    print("ROUTE: $route\n");
    my ($type, $id) = $route =~ /\/watch\/(.*)=(.*)/;
    if ($type eq "v") {
        return streaming_video::get_streaming_video($id);
    } elsif ($type eq "l") {
        return streaming_html::get_streaming_live($id);
    } else {
        return HTTP_RESPONSE::ERROR_404("Video not found");
    }
}

sub get_streaming_video_src {
    my ($client_socket, $route) = @_;
    my ($id) = $route =~ /\/video\/src\/(.*)/;
    if (!$id) {
        return HTTP_RESPONSE::ERROR_404("Video not found");
    }
    return video_utils::get_video($id, $client_socket);
}
sub get_streaming_image_src {
    my ($client_socket, $route) = @_;
    my ($id) = $route =~ /\/image\/src\/(.*)/;
    if (!$id) {
        return HTTP_RESPONSE::ERROR_404("Image not found");
    }
    return image_utils::get_thumbnail($id, $client_socket);   
}    

sub get_streaming_image_channel_icon {
    my ($client_socket, $route) = @_;
    my ($id) = $route =~ /\/image\/channel_icon\/(.*)/;
    print("HI\n");
    if (!$id) {
        return image_utils::get_default_channel_icon($client_socket);
    }
    return image_utils::get_channel_icon($id, $client_socket);   
}

sub get_streaming_image_channel_banner {
    my ($client_socket, $route) = @_;
    my ($id) = $route =~ /\/image\/channel_banner\/(.*)/;
    if (!$id) {
        return HTTP_RESPONSE::ERROR_404("Channel not found");
    }
    return image_utils::get_channel_banner($id, $client_socket);   
}
sub get_streaming_channel {
    my ($client_socket, $route) = @_;
    my ($username) = $route =~ /\/channel\/(.*)/;
    my $location;
    if ($username =~ /(.*)\/(.*)/) {
        $username = $1;
        $location = $2;
    }
    if (!$username) {
        return HTTP_RESPONSE::ERROR_404("Channel not found");
    }
    print("USERNAME: $username\n");
    return streaming_channel::get_streaming_channel($username, $client_socket, $location);
}

sub get_streaming_manage_channel {
    my ($client_socket, $route) = @_;
    my ($username) = $route =~ /\/manage\/channel\/(.*)/;
    my $path;
    if ($username =~ /^([^\/]+)\/(.*)$/) {
        $username = $1;
        $path = $2;
    }
    if (!$username) {
        return HTTP_RESPONSE::ERROR_404("Channel not found");
    }
    return streaming_manage_channel::get_streaming_manage_channel($username, $client_socket, $path);
}

1;