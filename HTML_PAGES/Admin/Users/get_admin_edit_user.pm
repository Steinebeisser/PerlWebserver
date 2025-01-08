package get_admin_edit_user;

use strict;
use warnings;

use HTML_PAGES::Admin::Utils::admin_utils;

sub get_admin_edit_user {
    my ($client_socket, $username) = @_;
    my $username_human;
    if (!user_utils::check_if_admin_and_logged_in($client_socket)) {
        return 0;
    }
    
    # print("USERNAME: $username\n");
    my $uuid = user_utils::get_uuid_by_username($username);
    # print("UUID: $uuid\n");
    if (!user_utils::check_if_user_exists($client_socket, $uuid)) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_404("User not found"));
    }

    $username_human = user_utils::decode_uri($username);


    my $username_role = user_utils::get_user_stat($uuid, "role");

    my $html_body = <<HTML;
    
    <h1>Edit user $username_human</h1>
    <br>
    <form action="/admin/users/edit/$username" method="post">
    Role: 
    <select name="role">
HTML
        if (!$username_role) {
            $html_body .= qq(<option value="" selected></option>\n);
        } else {
            $html_body .= qq(<option value=""></option>\n);
        }
        foreach my $role (user_utils::get_all_roles()) {
            my $selected = $username_role eq $role ? "selected" : "";
            $html_body .= qq(<option value="$role" $selected>$role</option>\n);
            # print(" ROLLONE: $role\n");
        }
        

    $html_body .= <<HTML;
    </select>
    <br>
    <br>
    <input type="submit" value="Change Role">
    </form>
    <br>

HTML
    $html_body .= admin_utils::return_buttons();

    my $html_content = html_structure::get_html($html_body, "Edit user");

    return ($html_content);
}

1;