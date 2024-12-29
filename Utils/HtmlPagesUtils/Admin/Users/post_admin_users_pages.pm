package post_admin_users_pages;

use strict;
use warnings;

sub post_admin_users {
    my ($client_socket, $request) = @_;
    admin_utils::check_if_admin_and_logged_in($client_socket);
    my $user_per_page = 3;
    $request = request_utils::skip_to_body($request);
    if ($request =~ /userperpage=(\d+)/) {
        $user_per_page = $1;
    }

    my $redirect_url = "/admin/users/?page=1&userperpage=$user_per_page";
    my $response = HTTP_RESPONSE::REDIRECT_303($redirect_url);

    http_utils::send_http_response($client_socket, $response);
}

sub post_admin_edit_user {
    my ($client_socket, $request) = @_;
    my $username;
    if ($request =~ /\/admin\/users\/edit\/(.*) HTTP/) {
        $username = $1;
    } else {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_500());
    }

    $request = request_utils::skip_to_body($request);
    my $uuid = user_utils::get_uuid_by_username($username);
    
    if (!$uuid) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_404("User does not exist"));
    }

    if ($request =~ /role=(.*)/) {
        my $role = $1;
        
        if (!user_utils::update_user_values($uuid, "role", $role)) {
            return 0;
        }

        my $html = get_admin_edit_user::get_admin_edit_user($client_socket, $request, $username);
        my $response = HTTP_RESPONSE::OK($html);
        http_utils::send_http_response($client_socket, $response);
    } else {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_500());
    }

    my $html = get_admin_edit_user::get_admin_edit_user($client_socket, $request, $username);
    my $response = HTTP_RESPONSE::OK($html);
    http_utils::send_http_response($client_socket, $response);
}

sub post_admin_ban_user {
    my ($client_socket, $request) = @_;
    my $username;
    if (!admin_utils::check_if_admin_and_logged_in($client_socket)) {
        return;
    }
    if ($request =~ /\/admin\/users\/ban\/(.*) HTTP/) {
        $username = $1;
    } else {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_500());
    }

    $request = request_utils::skip_to_body($request);
    my $uuid = user_utils::get_uuid_by_username($username);

    if (!$uuid) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_404("User does not exist"));
    }

    if ($request =~ /reason=(.*)&time=(.*)/) {
        my $reason = $1;
        my $time = $2;

        my $time_until = time() + $time;
        
        if (!user_utils::ban_user($uuid, $reason, $time_until)) {
            return 0;
        }
    } else {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_500());
    }

    my $html = get_admin_ban_user::get_admin_ban_user($client_socket, $request, $username);
    my $response = HTTP_RESPONSE::OK($html);
    http_utils::send_http_response($client_socket, $response);
}


sub post_admin_delete_user {
    my ($client_socket, $request) = @_;
    my $username;
    if (!admin_utils::check_if_admin_and_logged_in($client_socket)) {
        return;
    }
    if ($request =~ /\/admin\/users\/delete\/(.*) HTTP/) {
        $username = $1;
    } else {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_500());
    }

    # $request = request_utils::skip_to_body($request);
    my $uuid = user_utils::get_uuid_by_username($username);
    if (!$uuid) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_404("User does not exist"));
    }

    if (!user_utils::delete_user($uuid)) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_500("Could not delete user"));
    }
    # if ($request =~ /reason=(.*)/) {
    #     my $reason = $1;
        
    # } else {
    #     http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_500());
    # }

    # if (user_utils::is_encoded($username)) {
    #     $username = user_utils::decode_uri($username);
    # }
    my $html = get_admin_delete_user::get_admin_deleted_user($client_socket, $username);
    # my $html = get_admin_delete_user::get_admin_delete_user($client_socket, $request, $username);
    my $response = HTTP_RESPONSE::OK($html);
    http_utils::send_http_response($client_socket, $response);
}

1;