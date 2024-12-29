package get_user_main_support_page;

use strict;
use warnings;

sub get_user_main_support_page {
    my ($client_socket, $request) = @_;

    my $html = <<HTML;
    
HTML

    my $html_content = html_structure::get_html($html, "Support");

    return $html_content;
}

1;