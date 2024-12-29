package get_admin_delete_user;

use strict;
use warnings;

use HTML_PAGES::Admin::Utils::admin_utils;
sub get_admin_delete_user {
    my ($client_socket, $request, $username) = @_;
    my $html_body;
    my $human_username = user_utils::decode_uri($username);
    my $uuid = user_utils::get_uuid_by_username($username);

    if (!$uuid) {
        return HTTP_RESPONSE::ERROR_404("User does not exist");
    }
    if (!user_utils::check_if_admin_and_logged_in($client_socket)) {
        return 0;
    }
    if (!user_utils::check_if_user_exists($client_socket, $uuid)) {
        return HTTP_RESPONSE::ERROR_404("User does not exist");
    } 
    
    print("TO DELETE USERNAME $username\n");
    $html_body = <<HTML;
    <h1>Delete user $human_username</h1>
    <br>
    <br>
    <form action="/admin/users/delete/$human_username" method="post">
        <input type="submit" value="Delete user">
    </form>
    <br>
HTML
    

    $html_body .= admin_utils::return_buttons();

    my $html_content = html_structure::get_html($html_body, "Delete user");

    return ($html_content);
}

sub get_admin_deleted_user {
    my ($client_socket, $username) = @_;

    my $html_body = <<HTML;
    <h1>User $username has been deleted</h1>
    <br>
    <br>
HTML

    $html_body .= admin_utils::return_buttons();

    my $html_content = html_structure::get_html($html_body, "User deleted");

    return ($html_content);
}
1;