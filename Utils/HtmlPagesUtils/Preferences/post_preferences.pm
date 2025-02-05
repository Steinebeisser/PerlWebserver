package post_preferences;

sub post_change_language {
    my ($client_socket, $route, $temp_file) = @_;
    my $language;
    my $referer;
    my $username;

    $referer = request_utils::get_referer($main::header);


    my $request = body_utils::load_temp_file($temp_file);
    if ($request =~ /language=(.*)/) {
        $language = $1;
    } 

    if (!$language) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_500());
    }

    if (!$referer) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_500());
    }


    if ($language) {
        if ($main::user) {
            my $uuid = $main::user->{uuid};
            my $preferences = user_utils::get_user_stat($uuid, "preferences");
            if ($preferences) {
                $preferences->{language} = $language;
            } else {
                $preferences = {language => $language};
            }
            if (user_utils::update_user_values($uuid, "preferences", $preferences)) {
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
    my ($client_socket) = @_;

    my $referer = request_utils::get_referer($main::header);
    if (!$referer) {
        $referer = "/";
    }

    my $scheme = $main::scheme;
    # my $scheme = request_utils::get_scheme_by_cookie();
    # print("COOKIE SCHEME: $scheme\n");
    
    # print("COOKIE SCHEME: $scheme\n");
    # my $cookie_scheme;

    if (!$scheme) {
        $scheme = "dark";
        $main::scheme = "dark";
    } else {
        if ($scheme eq "light") {
            # print("SCHEME IS LIGHT $scheme\n");
            $scheme = "dark";
            $main::scheme = "dark";
        } else {
            # print("SCHEME IS DARK $scheme\n");
            $scheme = "light";
            $main::scheme = "light";

        }
    }
    # print("SWAPPED SCHEME: $scheme\n");



    if ($main::user) {
        my $uuid = $main::user->{uuid};
        my $preferences = user_utils::get_user_stat($uuid, "preferences");
        if ($preferences) {
            $preferences->{scheme} = $scheme;
        } else {
            $preferences = {scheme => $scheme};
        }
        if (user_utils::update_user_values($uuid, "preferences", $preferences)) {
            my $response = HTTP_RESPONSE::REDIRECT_303($referer, "scheme=$scheme");
            http_utils::send_http_response($client_socket, $response);
        } else {
            # print("ERROR UPDATING USER\n");
            http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_500());
        }
    } else {
        # print("NO USERNAME\n");
        http_utils::send_http_response($client_socket, HTTP_RESPONSE::REDIRECT_303_WITH_COOKIE($referer, "scheme=$scheme"));
    }

}

1;