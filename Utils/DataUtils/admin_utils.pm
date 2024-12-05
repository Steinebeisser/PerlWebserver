package admin_utils;

use strict;
use warnings;

sub return_buttons {
    my $return_buttons = <<HTML;
    <span class="admin_return">
        <a href="/admin/users">Return to users</a>
        <a href="/admin">Return to admin</a>
        <a href="/">Return to index</a>
    </span>
HTML
    
    return $return_buttons;
}
sub check_if_admin_and_logged_in {
    my ($client_socket) = @_;
    if (!$main::user) {
        serve_error($client_socket, HTTP_RESPONSE::ERROR_401("You are not logged in<br><a href=\"/ \">Return to index</a><br><a href=\"/login\">Login</a>"));
        return 0;
    } 
    my $role = user_utils::get_role();
    if ($role ne "admin") {
        serve_error($client_socket, HTTP_RESPONSE::ERROR_401("You are not an admin<br><a href=\"/ \">Return to index</a><br><a href=\"/login\">Login</a>"));
        return 0;
    }
    else {
        return 1;
    }
}

sub check_if_admin {
    my ($client_socket) = @_;
    if (!$main::user) {
        return 0;
    } 
    my $role = user_utils::get_role();
    if ($role ne "admin") {
        return 0;
    }
    else {
        return 1;
    }
}

1;