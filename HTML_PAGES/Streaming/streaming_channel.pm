package streaming_channel;

use strict;
use warnings;

use Cwd;
use JSON;

my %locations = (
    "videos" => \&get_streaming_channel_videos,
    "about" => \&get_streaming_channel_about,
);


sub get_streaming_channel {
    my ($username, $client_socket, $location) = @_;

    my $base_dir = getcwd();
    my $uuid = user_utils::get_uuid_by_username($username);
    my $channel_path = "$base_dir/Data/UserData/Users/$uuid/Streaming";
    my $videos_file = "$channel_path/videos.txt";

    my $human_username = user_utils::decode_uri(user_utils::get_displayname_by_uuid($uuid));

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
HTML
    if ($main::user->{uuid} eq $uuid) {
        $html .= <<HTML;
            <div class="ManageAccount">
                <a href="/streaming/manage/channel/$username">Manage Account</a>
            </div>
HTML
    }
    $html .= <<HTML;
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

    if ($location) {
        my $location_function = $locations{$location};
        if ($location_function) {
            $html .= $location_function->($username, $client_socket);
        }
    }

    my $html_content = html_structure::get_html($html, "$human_username");

    return $html_content;
}

sub get_streaming_channel_videos {
    my ($username, $client_socket) = @_;

    my $base_dir = getcwd();
    my $uuid = user_utils::get_uuid_by_username($username);
    my $channel_path = "$base_dir/Data/UserData/Users/$uuid/Streaming";
    my $videos_file = "$channel_path/videos.txt";

    my @videos = video_utils::get_videos($videos_file, 0, $uuid);

    my $html = <<HTML;
    <div class="channel_videos">
        <div class="Videos">
HTML
    foreach my $video (@videos) {
        $html .= video_utils::create_video_emblem($video);

    }
    $html .= <<HTML;
        </div>
    </div>
HTML

    return $html;

}

sub get_streaming_channel_about {
    my ($username, $client_socket) = @_;

    my $base_dir = getcwd();
    my $uuid = user_utils::get_uuid_by_username($username);
    my $streaming_path = "$base_dir/Data/UserData/Users/$uuid/Streaming";
    if (!-d $streaming_path) {
        mkdir $streaming_path;
    }
    my $channel_path = "$streaming_path/Channel";
    if (!-d $channel_path) {
        mkdir $channel_path;
    }
    my $about_file = "$channel_path/about.txt";

    my $skip;
    my $about;
    open my $fh, "<", $about_file or do {
        warn "no about file";
        $skip = 1;
    };
    if (!$skip) {
        $about = do { local $/; <$fh> };
        close $fh;
    }
    if (!$about) {
        $about = "No about section";
    }

    my $html = <<HTML;
    <div class="channel_about">
        <div class="About">
            <p>$about</p>
        </div>
    </div>
HTML

    return $html;
}

1;