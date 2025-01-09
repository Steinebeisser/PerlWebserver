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
        $html .= video_utils::create_video_emblem($video);
    }

    $html .= <<HTML;
                    </div>
                </div>
            </div>
            <div class="StreamingMainRight">
HTML
    if ($main::user) {
        $html .= <<HTML;
                <div class="Account">
                    <a href="/streaming/channel/$main::user->{username}">My Channel</a>
                </div>
                <div class="ManageAccount">
                    <a href="/streaming/manage/channel/$main::user->{username}">Manage Account</a>
                </div>
HTML
    }
    $html .= <<HTML;
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