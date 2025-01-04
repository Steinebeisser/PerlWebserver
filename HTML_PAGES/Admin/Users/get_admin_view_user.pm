package get_admin_view_user;

use strict;
use warnings;

use HTML_PAGES::Admin::Utils::admin_utils;
sub get_admin_view_user {
    my ($client_socket, $username) = @_;

    my $html_body = <<HTML;
    <h1>View user $username</h1>
    <br>
    <br>
HTML

    $html_body .= admin_utils::return_buttons();

    my $html_content =  html_structure::get_html($html_body, "View user");

    return ($html_content);
}

1;