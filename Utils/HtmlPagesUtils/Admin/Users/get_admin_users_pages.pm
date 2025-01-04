package get_admin_users_pages;

use strict;
use warnings;

sub get_admin_users {
    my ($client_socket, $route) = @_;
    my $current_page = 0;
    my $user_per_page = 3;
    # print ("ROUTE: $route\n");
    # print ("REQUEST: $request\n");
    # $request = request_utils::skip_to_body($request);
    if ($route =~ /\/admin\/users\/.*\?page=(\d+)/) {
        $current_page = $1;
    }
    if ($route =~ /\&userperpage=(\d+)/) {
        $user_per_page = $1;
    }
    if ($user_per_page > 2147483647) {
        $user_per_page = 2147483647;
    }
    if ($current_page > 2147483647) {
        $current_page = 2147483647;
    }
    # print "REQUEST: $request\n";
    # print "User per page: $user_per_page\n";

    if (!$main::user) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_401("You are not logged in<br><a href=\"/ \">Return to index</a><br><a href=\"/login\">Login</a>"));
    } 
    my $role = user_utils::get_role();
    if ($role ne "admin") {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_401("You are not an admin<br><a href=\"/ \">Return to index</a><br><a href=\"/login\">Login</a>"));
    }
    return admin_user_html::get_user_list($current_page, $user_per_page);
}







sub get_admin_edit_user {
    my ($client_socket, $route) = @_;
    if ($route =~ /\/admin\/users\/edit\/(.*)/) {
        my $username = $1;
        if (user_utils::is_encoded($username)) {
            $username = user_utils::decode_uri($username);
        }
        my $html = get_admin_edit_user::get_admin_edit_user($client_socket, $username);
        return $html;
    }
}



sub get_admin_view_user {
    my ($client_socket, $route) = @_;
    if ($route =~ /\/admin\/users\/view\/(.*)/) {
        my $username = $1;
        if (user_utils::is_encoded($username)) {
            $username = user_utils::decode_uri($username);
        }
        my $html = get_admin_view_user::get_admin_view_user($client_socket, $username);
        return $html;
    }
}

sub get_admin_delete_user {
    my ($client_socket, $route) = @_;
    if ($route =~ /\/admin\/users\/delete\/(.*)/) {
        my $username = $1;
        my $html = get_admin_delete_user::get_admin_delete_user($client_socket, $username);
        return $html;
    }
}

sub get_admin_ban_user {
    my ($client_socket, $route) = @_;
    if ($route =~ /\/admin\/users\/ban\/(.*)/) {
        my $username = $1;
        my $html = get_admin_ban_user::get_admin_ban_user($client_socket, $username);
        return $html;
    }
}

1;