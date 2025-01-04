package get_admin_ban_user;

use strict;
use warnings;

# use lib 'Webserver\HTML_PAGES';
# use Admin::user_Utils::user_utils as admin_utils;

use HTML_PAGES::Admin::Utils::admin_utils;


sub get_admin_ban_user {
    my ($client_socket, $username) = @_;
    if (!user_utils::check_if_admin_and_logged_in($client_socket)) {
        return 0;
    }

    my $human_username;
    if (user_utils::is_encoded($username)) {
        $human_username = user_utils::decode_uri($username);
    }
    my $html_body = <<HTML;
    
    <h1>Ban user $human_username</h1>
    <br>
    <form action="/admin/users/ban/$username" method="post">
        Reason: <input type="text" name="reason" required>
        <br>
        Time: <input type="text" name="time" required>
        <br>
        <br>
        <input type="submit" value="Ban user">
        <br>
    </form>
    <br>
HTML
    $html_body .= admin_utils::return_buttons();

    my $html_content = html_structure::get_html($html_body, "Ban user");

    return ($html_content);
}

1;