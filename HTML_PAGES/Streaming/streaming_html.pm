package streaming_html;

use strict;
use warnings;

sub get_streaming_home {

    my $translations = language_utils::load_language("streaming");

    my @videos = video_utils::get_top_videos();
    my $html = <<HTML;
    <div class="StreamingView">
        <div class="StreamingTop">
            <div class="StreamingTopLeft">
                <a href="/streaming/videos">Videos</a>
            </div>
            <div class="StreamingTopCenter">
                <div class="Search">
                    <input type="text" placeholder="Search..." name="search">
                    <button type="submit">Search</button>
                </div>
            </div>
            <div class="StreamingTopRight">
                <a href="/streaming/live">Live</a>
            </div>
        </div>
        <div class="StreamingMain">
            <div class="StreamingMainLeft">
                <div class="StreamingMainLeftTop">
                    <div class="MainPage">
                        <a href="/streaming">Video Main</a>
                    </div>
                </div>
                <div class="StreamingMainLeftCenter">
                    <div class="Following">
                    </div>
                </div>
                <div class="StreamingMainLeftBottom">
                    <a href="/streaming/live">Live</a>
                </div>
            </div>
            <div class="StreamingMainCenter">
                <div class="StreamingMainCenterTop">
                    <div class="Videos">
HTML

    foreach my $video (@videos) {
        my $video_id = $video->{video_id};
        my $video_title = user_utils::decode_uri($video->{title});
        my $thumbnail_path = $video->{thumbnail_path};
        my $channel_name = $video->{channel_name} || "Cant fetch Channel";
        my $channel_username = $video->{channel_username};
        $html .= <<HTML;
                        <div class="Video">
                            <button type="button" class="Thumbnail" onclick="window.location.href='/streaming/watch/v=$video_id'">
                                <img src="/streaming/image/src/$video_id" alt="Video Thumbnail: $video_title">
                            </button>
                            <div class="VideoMetadata">
                                <button type="button" class="ChannelIcon" onclick="window.location.href='/streaming/channel/$channel_username'">
                                    <img src="/streaming/image/channel_icon/$channel_username" alt="Channel Icon">
                                </button>
                                <div class="OtherMetadata">
                                    <div class="VideoTitle">
                                        <a href="/streaming/watch/v=$video_id">$video_title</a>
                                    </div>
                                    <div class="ChannelName">
                                        <a href="/streaming/channel/$channel_username">$channel_name</a>
                                    </div>
                                    <div class="VideoInline">
                                        <div class="VideoViews">
                                            0 views
                                        </div>
                                        <div class="VideoSeparator">
                                            •
                                        </div>
                                        <div class="VideoUploadDate">
                                            0 days ago
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
HTML
    }

    $html .= <<HTML;
                    </div>
                </div>
            </div>
            <div class="StreamingMainRight">
                <div class="StreamingMainRightTop">
                    <a href="/streaming/videos">Videos</a>
                </div>
                <div class="StreamingMainRightBottom">
                    <a href="/streaming/live">Live</a>
                </div>
                <div class="Upload">
                    <a href="/streaming/upload">Upload</a>
                </div>
            </div>
        </div>
    </div>
HTML

    my $html_content = html_structure::get_html($html, "Streaming");

    return $html_content;

}

1;