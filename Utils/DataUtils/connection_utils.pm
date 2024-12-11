package connection_utils;

use strict;
use warnings;

sub get_client_data {
    my ($client_fd, $client_socket) = @_;
    # print("HELLOOOOOO\n");

    my $buffer;
    
    recv($client_socket, $buffer, 1024, 0);

    my $request = $buffer;

    if ($request =~ /Content-Length: (\d+)/) {
        $epoll::clients{$client_fd}{"content_length"} = $1;
    }
    if ($request =~ /Sec-WebSocket-Key: (.*)\r\n/) {
        websocket_utils::handle_websocket_request($client_socket, $request);
        return;
    }
    if (length($buffer) < 1024) {
        $epoll::clients{$client_fd}{"more"} = 0;
    }
    $epoll::clients{$client_fd}{"request"} = $request;
    if ($request =~ /\r\n\r\n/) {
        my ($header, $body) = split(/\r\n\r\n/, $request, 2);
        my $content_length = $epoll::clients{$client_fd}{"content_length"};
        my $bytes_read = length($body);
        $epoll::clients{$client_fd}{"header"} = $header;
        $epoll::clients{$client_fd}{"body"} = $body;
        $epoll::clients{$client_fd}{"bytes_read"} = $bytes_read;
        $epoll::clients{$client_fd}{"content_length"} = $content_length;
    
        my $cookie_data = request_utils::get_cookie_data($header);
        my $username;
        if ($cookie_data) {
            $username = $cookie_data->{username};
            # http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_401("You are not logged in<br><a href=\"/ \">Return to index</a><br><a href=\"/login\">Login</a>"));
            # return;
        }

        # if (!$username) {
        #     http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_401("You are not logged in<br><a href=\"/ \">Return to index</a><br><a href=\"/login\">Login</a>"));
        # } elsif ($username ne $username) {
        #     http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_401("You are not allowed to view this page<br><a href=\"/ \">Return to index</a>"));
        # }

        if ($content_length) {
            print("CONTENT LENGTH: $content_length\n");
            print("MAX STORAGE: $main::max_storage\n");

            if ($username) {
                my $max_storage = user_utils::get_user_max_storage($username);
                my $max_file_size = $max_storage - user_utils::get_current_used_storage($username);
                my $max_server_size = user_utils::get_max_server_size();
                if ($max_file_size > $max_server_size * $server::storage_bottleneck) {
                    print("SERVER STORAGE EXCEEDED\n");
                    http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_413("Server storage exceeded"));
                    return;
                }
                if ($content_length > $max_file_size) {
                    print("File too large\n");

                    print("CURRENT USED STORAGE: ".user_utils::get_current_used_storage($username)."\n");
                    print("MAX FILE SIZE: $max_file_size\n");
                    print("CONTENT LENGTH: $content_length\n");
                    http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_413("File too large"));
                    return;
                }
            }
        }
    }
    # print("FINITO GETTING DATA\n");
}

sub handle_client_data {
    my ($client_fd, $client_socket) = @_;

    my $buffer;
    # print("HANDLE CLIENT DATA\n");

    if ($epoll::clients{$client_fd}{"content_length"} && $epoll::clients{$client_fd}{"bytes_read"} < $epoll::clients{$client_fd}{"content_length"}) {
        recv($client_socket, $buffer, 1024, 0);
        $epoll::clients{$client_fd}{"body"} .= $buffer;
        $epoll::clients{$client_fd}{"bytes_read"} += length($buffer);
        $epoll::clients{$client_fd}{"request"} .= $buffer;
        # print("+ ".length($buffer)."\n");
        # print("BYTES READ: $epoll::clients{$client_fd}{bytes_read}\n");
        # print("CONTENT LENGTH: $epoll::clients{$client_fd}{content_length}\n");
        if ($epoll::clients{$client_fd}{"bytes_read"} >= $epoll::clients{$client_fd}{"content_length"}) {
            # print("FINISHED READING REQUEST\n");
            main::handle_normal_request($client_fd, $epoll::clients{$client_fd}{"request"});
            main::remove_client($client_fd);
            # epoll_ctl($epoll, EPOLL_CTL_DEL, $client_fd, 0) >= 0 || die "Can't remove client socket from epoll: $!";
            # close($client_socket);
            # delete $epoll::clients{$client_fd};
        }
    } else {
        # print("REQUEST: $epoll::clients{$client_fd}{request}\n");
        # print("FINItO REQUEST\n");
        main::handle_normal_request($client_fd, $epoll::clients{$client_fd}{request});
        main::remove_client($client_fd);
        # epoll_ctl($epoll, EPOLL_CTL_DEL, $client_fd, 0) >= 0 || die "Can't remove client socket from epoll: $!";
        # close($client_socket);
        # delete $epoll::clients{$client_fd};
    }
}

1;