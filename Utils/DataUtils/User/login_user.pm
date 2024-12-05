package login_user;

use strict;
use warnings;

sub post_login {
    my ($client_socket, $request) = @_;
    my $response;
    my $username;
    my $password; 
    my $accept_language;
    
    if ($request =~ /username=(.*)&password=(.*)?/) {
        $username = $1;
        $password = $2;
    }

    if (!$username || !$password) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_400());
    }

    if (length($username) > 24 || length($password) > 24) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_400("Username or password too long"));
    }

    if ($request =~ /Accept-Language: (.*)\r/) {
        $accept_language = $1;
    }

    if (login_user($username, $password, $client_socket)) {
        my $cookie = "username=$username";
        my $html = get_operation_finished_pages::get_logined($username);
        $response = HTTP_RESPONSE::OK_WITH_COOKIE($html, $cookie);
        user_utils::populate_user($cookie, $accept_language);

    } else {
        $response = HTTP_RESPONSE::OK("Invalid username or password <a href=\"/login \">Try again</a>");
    }
    http_utils::send_http_response($client_socket, $response);
}

sub login_user {
    my ($username, $password, $client_socket) = @_;
    my $filename = "UserData/$username/$username.json";
    # print("LOGGING IN\n");
    
    if (!user_utils::compare_values($username, "password", $password)) {
        # print("WROMG PASSWORD\n");
        return 0;
    }

    if (!user_utils::check_permissions($client_socket, $username)) {
        return 0;
    }

    return 1;
}

1;