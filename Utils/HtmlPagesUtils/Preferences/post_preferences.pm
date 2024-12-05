package post_preferences;

sub post_change_language {
    my ($client_socket, $request) = @_;
    my $language;
    my $referer;
    my $username;
    my $language_test1;
    my $language_test2;
    my $username_test1;
    my $username_test2;
    my $test_request = $request;

    my $cookie_data = request_utils::get_cookie_data($request);
    $username = $cookie_data->{username};
    $language = $cookie_data->{language};

    $referer = request_utils::get_referer($request);


    $request = request_utils::skip_to_body($request);
    if ($request =~ /language=(.*)/) {
        $language = $1;
    } 

    if (!$language) {
        # print("NO LANGUAGE\n");
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_500());
    }

    if (!$referer) {
        # print("NO REFERER\n");
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_500());
    }


    # print("GOT LANGUAGE: $language\n");

    if ($language) {
        if ($username) {
            if (user_utils::update_user_values($username, "preferences", {language => $language})) {
                my $response = HTTP_RESPONSE::REDIRECT_303($referer);
                http_utils::send_http_response($client_socket, $response);
            } else {
                # print("ERROR UPDATING USER\n");
                http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_500());
            }
        } else {
            # print("NO USERNAME\n");
            http_utils::send_http_response($client_socket, HTTP_RESPONSE::REDIRECT_303_WITH_COOKIE($referer, "language=$language"));
        }
    }
}

sub post_dark_mode {
    my ($client_socket, $request) = @_;

    my $referer = request_utils::get_referer($request);
    if (!$referer) {
        $referer = "/";
    }

    my $cookie_data = request_utils::get_cookie_data($request);
    

    my $scheme;
    my $username;

    if ($cookie_data) {
        $username = $cookie_data->{username};
        $scheme = $cookie_data->{scheme};
    }

    # print("COOKIE SCHEME: $scheme\n");
    my $cookie_scheme;

    if ($username) {
        $scheme = user_utils::get_user_stat($username, "preferences")->{scheme};
    }

    # print("USERNAME SCHEME: $scheme\n");

    if (!$scheme) {
        $scheme = "dark";
        $cookie_scheme = "scheme=dark";
        $main::scheme = "dark";
    } else {
        if ($scheme eq "light") {
            # print("SCHEME IS LIGHT $scheme\n");
            $scheme = "dark";
            $main::scheme = "dark";
            $cookie_scheme = "scheme=dark";
        } else {
            # print("SCHEME IS DARK $scheme\n");
            $scheme = "light";
            $main::scheme = "light";
            $cookie_scheme = "scheme=light";

        }
    }
    # print("SWAPPED SCHEME: $scheme\n");



    if ($username) {
        if (user_utils::update_user_values($username, "preferences", {scheme => $scheme})) {
            my $response = HTTP_RESPONSE::REDIRECT_303($referer);
            http_utils::send_http_response($client_socket, $response);
        } else {
            # print("ERROR UPDATING USER\n");
            http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_500());
        }
    } else {
        # print("NO USERNAME\n");
        http_utils::send_http_response($client_socket, HTTP_RESPONSE::REDIRECT_303_WITH_COOKIE($referer, $cookie_scheme));
    }

}

1;