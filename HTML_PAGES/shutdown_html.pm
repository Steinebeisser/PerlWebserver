package shutdown_html;

use strict;
use warnings;

sub get_shutdown {
    my $html_body = <<HTML;
    <h2>bye bye :(</h2>
HTML

    my $html_content = html_structure::get_html($html_body, "Shutdown");

    return ($html_content);
}

1;