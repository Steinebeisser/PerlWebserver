package get_streaming_pages;

use strict;
use warnings;

use JSON;

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
    # print("ROUTE: $route\n");
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
    # print("HI\n");
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
    # print("USERNAME: $username\n");
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

sub get_streaming_videos {
    my ($client_socket, $route) = @_;

    my ($last_video) = $route =~ /\/videos\/(.*)/;
    if (!$last_video) {
        $last_video = 0;
    }

    my @videos = video_utils::get_top_videos($last_video);
    if (!@videos) {
        http_utils::send_http_response($client_socket, HTTP_RESPONSE::NO_MORE_CONTENT_204());
        return;
    }
    
    return encode_json(\@videos);
}

sub get_streaming_video_comments {
    my ($client_socket, $route) = @_;

    my ($video_id, $last_comment) = $route =~ /\/video\/comments\/(.*)\/(.*)/;
    if (!$video_id) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_404("Video not found"));
        return;
    }

    my $comments_ref = video_utils::get_comments($video_id, $last_comment);

    if (!$comments_ref || !@$comments_ref) {
        http_utils::send_http_response($client_socket, HTTP_RESPONSE::NO_MORE_CONTENT_204());
        return;
    }

    foreach my $comment (@$comments_ref) {  
        $comment->{author_displayname} = user_utils::get_displayname_by_uuid($comment->{author_uuid});
        $comment->{author_username} = user_utils::get_username_by_uuid($comment->{author_uuid});
        $comment->{comment_date} = streaming_html::parse_date($comment->{commented_at});
        $comment->{liked} = video_utils::get_comment_liked_status($video_id, $comment->{comment_id});
        my $replies = $comment->{replies};
        if ($replies) {
            foreach my $reply (keys %$replies) {
                $reply = $replies->{$reply};
                $reply->{author_displayname} = user_utils::get_displayname_by_uuid($reply->{author_uuid});
                $reply->{author_username} = user_utils::get_username_by_uuid($reply->{author_uuid});
                $reply->{comment_date} = streaming_html::parse_date($reply->{commented_at});
                $reply->{parent_comment_id} = $comment->{comment_id};
                $reply->{liked} = video_utils::get_comment_liked_status($video_id, $reply->{comment_id}, $comment->{comment_id});
            }
        }
    }
    return encode_json($comments_ref); 

}
1;