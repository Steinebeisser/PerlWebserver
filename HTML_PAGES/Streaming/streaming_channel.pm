package streaming_channel;

use strict;
use warnings;

use Cwd;
use JSON;


sub get_streaming_channel {
    my ($username, $client_socket) = @_;

    my $base_dir = getcwd();
    my $uuid = user_utils::get_uuid_by_username($username);
    my $channel_path = "$base_dir/Data/UserData/Users/$uuid/streaming";
    my $videos_file = "$channel_path/videos.txt";

    my $human_username = user_utils::decode_uri(user_utils::get_display_name_with_uuid($uuid));
    my @videos = video_utils::get_videos($videos_file);

    my $html = <<HTML;
    <div class="StreamingChannel">
        <div class="ChannelInfo">
            <div class="ChannelBanner">
                <img src="/streaming/image/channel_banner/$uuid" class="channel_banner">
            </div>
            <div class="ChannelIcon">
                <img src="/streaming/image/channel_icon/$uuid" class="channel_icon">
            </div>
            <div class="ChannelText">
                <div class="ChannelName">
                    <h1>$human_username</h1>
                </div>
                <div class="SubscriberCount">
                    10 Subscribers
                </div>
            </div>
            <div class="SubscribeButton">
                <button>Subscribe</button>
            </div>
        </div>
        <div class="ChannelFeatures">
            <div class="ChannelVideosButton">
                <a href="/streaming/channel/$username/videos">Videos</a>
            </div>
            <div class="ChannelAboutButton">
                <a href="/streaming/channel/$username/about">About</a>
            </div>
        </div>

    </div>

HTML

    my $html_content = html_structure::get_html($html, "$human_username");

    return $html_content;
}

sub get_streaming_channel_videos {
    my ($username, $client_socket) = @_;

    my $base_dir = getcwd();
    my $uuid = user_utils::get_uuid_by_username($username);
    my $channel_path = "$base_dir/Data/UserData/Users/$uuid/streaming";
    my $videos_file = "$channel_path/videos.txt";

    my @videos = video_utils::get_videos($videos_file);

    my $html = <<HTML;
    <div class="channel_videos">
HTML
    foreach my $video (@videos) {
        print("VIDEO FOUND\n");
        my $video_id = $video->{video_id};
        my $title = $video->{title};
        my $thumbnail_path = $video->{thumbnail_path};
        my $channel_name = $video->{channel_name};
        my $channel_username = $video->{channel_username};

        $html .= <<HTML;
            <div class="video">
                <a href="/streaming/watch/v=$video_id">
                    <img src="/streaming/image/src/$video_id" class="thumbnail">
                    <h2>$title</h2>
                    <h3>By: $channel_name</h3>
                </a>
            </div>
HTML

    $html .= <<HTML;
    </div>
HTML

    return $html;

    }
}

1;