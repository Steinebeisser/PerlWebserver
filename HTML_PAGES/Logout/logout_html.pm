package logout_html;

use strict;
use warnings;

sub get_logout {
    my $html_body = <<HTML;
    <h1>You have been logged out</h1>
    <br>
    <a href="/ ">Return to index</a>
    <br>
HTML

    my $html_content = html_structure::get_html($html_body, "User logouted");

    return ($html_content);
}

1;