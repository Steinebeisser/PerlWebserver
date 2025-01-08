package streaming_video;

use strict;
use warnings;

sub get_streaming_video {
    my ($id) = @_;

    my $translations = language_utils::load_language("streaming");

    my $html = <<HTML;
    <div class="streaming_video">
        <video src="/streaming/video/src/$id" width="60%" controls></video>
    </div>
HTML

    my $html_content = html_structure::get_html($html, "Streaming");

    return $html_content;
}

1;