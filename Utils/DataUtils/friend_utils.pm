package friend_utils;

use strict;
use warnings;

use JSON;
use Cwd;

sub send_friend_request {
    my ($client_socket, $route, $temp_file) = @_;

    my $sender_uuid = $main::user->{uuid};

    my $body = body_utils::load_temp_file($temp_file);

    my $json = decode_json($body);

    my $friend_username = $json->{username};

    
    my $friend_uuid = user_utils::get_uuid_by_username($friend_username);
    if (!$friend_uuid) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_400("User Not Found"));
        return;
    }

    # if ($sender_uuid eq $friend_uuid) {
    #     http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_400("Cannot send friend request to yourself"));
    #     return;
    # }

    my $base_dir = getcwd();
    my $friend_path = "$base_dir/Data/UserData/Users/$friend_uuid/Friends";
    if (!-d $friend_path) {
        mkdir($friend_path) or do {
            http_utils::send_http_response($client_socket, HTTP_RESPONSE::ERROR_500("Internal Server Error"));
            return;
        };
    }

    my $requests_file = "$friend_path/received_requests.json";
    if (!-e $requests_file) {
        open my $fh, '>', $requests_file or do {
            http_utils::send_http_response($client_socket, HTTP_RESPONSE::ERROR_500("Internal Server Error"));
            return;
        };
        print $fh "[]";
        close($fh);
    }

    open my $fh, '<', $requests_file;
    my $requests_data = do { local $/; <$fh> };
    close $fh;

    my $requests = decode_json($requests_data);

    my %request = (
        UserId => $sender_uuid,
        TimeSentTimestamp => time()
    );

    push @$requests, \%request;

    open $fh, '>', $requests_file;
    print $fh encode_json($requests);
    close $fh;

    my $sender_path = "$base_dir/Data/UserData/Users/$sender_uuid/Friends";
    if (!-d $sender_path) {
        mkdir($sender_path) or do {
            http_utils::send_http_response($client_socket, HTTP_RESPONSE::ERROR_500("Internal Server Error"));
            return;
        };
    }

    my $sent_requests_file = "$sender_path/sent_requests.json";
    if (!-e $sent_requests_file) {
        open $fh, '>', $sent_requests_file or do {
            http_utils::send_http_response($client_socket, HTTP_RESPONSE::ERROR_500("Internal Server Error"));
            return;
        };
        print $fh "[]";
        close($fh);
    }

    open $fh, '<', $sent_requests_file;
    my $sent_requests_data = do { local $/; <$fh> };
    close $fh;

    my $sent_requests = decode_json($sent_requests_data);

    my %sent_request = (
        UserId => $friend_uuid,
        TimeSentTimestamp => time()
    );

    push @$sent_requests, \%sent_request;

    open $fh, '>', $sent_requests_file;
    print $fh encode_json($sent_requests);
    close $fh;
}

sub get_received_requests {
    my ($client_socket, $path) = @_;

    my $base_dir = getcwd();
    my $friend_path = "$base_dir/Data/UserData/Users/$main::user->{uuid}/Friends";
    if (!-d $friend_path) {
        http_utils::send_http_response($client_socket, HTTP_RESPONSE::OK("{}"));
        return;
    }

    my $requests_file = "$friend_path/received_requests.json";
    if (!-e $requests_file) {
        http_utils::send_http_response($client_socket, HTTP_RESPONSE::OK("{}"));
        return;
    }


    open my $fh, '<', $requests_file;
    my $requests_data = do { local $/; <$fh> };
    close $fh;	
    my $requests_data = decode_json($requests_data);

    my @requests;
    foreach my $request (@$requests_data) {
        my $uuid = $request->{UserId};
        my %request = (
            UserId => $uuid,
            UserName => user_utils::get_username_by_uuid($uuid),
            DisplayName => user_utils::get_displayname_by_uuid($uuid),
            TimeSentTimestamp => $request->{TimeSentTimestamp}
        );
        push @requests, \%request;
    }

    my $response = HTTP_RESPONSE::OK_WITH_DATA(encode_json(\@requests), "received_requests.json");
    http_utils::send_http_response($client_socket, $response);
}

sub get_sent_requests {
    my ($client_socket, $path) = @_;

    my $base_dir = getcwd();
    my $friend_path = "$base_dir/Data/UserData/Users/$main::user->{uuid}/Friends";
    if (!-d $friend_path) {
        http_utils::send_http_response($client_socket, HTTP_RESPONSE::OK("{}"));
        return;
    }

    my $requests_file = "$friend_path/sent_requests.json";
    if (!-e $requests_file) {
        http_utils::send_http_response($client_socket, HTTP_RESPONSE::OK("{}"));
        return;
    }


    open my $fh, '<', $requests_file;
    my $requests_data = do { local $/; <$fh> };
    close $fh;	
    my $requests_data = decode_json($requests_data);

    my @requests;
    foreach my $request (@$requests_data) {
        my $uuid = $request->{UserId};
        my %request = (
            UserId => $uuid,
            UserName => user_utils::get_username_by_uuid($uuid),
            DisplayName => user_utils::get_displayname_by_uuid($uuid),
            TimeSentTimestamp => $request->{TimeSentTimestamp}
        );
        push @requests, \%request;
    }

    my $response = HTTP_RESPONSE::OK_WITH_DATA(encode_json(\@requests), "sent_requests.json");
    http_utils::send_http_response($client_socket, $response);
}

sub accept_friend_request {
    my ($client_socket, $route, $temp_file) = @_;

    my $body = body_utils::load_temp_file($temp_file);
    my $json = decode_json($body);
    my $friend_uuid = $json->{userId};
    if (!$friend_uuid) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_400("Invalid Request"));
        return;
    }

    if (!user_utils::user_exists($client_socket, $friend_uuid)) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_400("User not found"));
        return;
    }

    remove_sent_friend_request($main::user->{uuid}, $friend_uuid, $client_socket);

    remove_received_friend_request($friend_uuid, $main::user->{uuid}, $client_socket);

    add_friend($main::user->{uuid}, $friend_uuid, $client_socket);

    add_friend($friend_uuid, $main::user->{uuid}, $client_socket);

    http_utils::send_http_response($client_socket, HTTP_RESPONSE::OK("Friend Request Accepted"));
}

sub cancel_friend_request {
    my ($client_socket, $route, $temp_file) = @_;

    my $body = body_utils::load_temp_file($temp_file);
    my $json = decode_json($body);
    my $friend_uuid = $json->{userId};
    if (!$friend_uuid) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_400("Invalid Request"));
        return;
    }

    if (!user_utils::user_exists($client_socket, $friend_uuid)) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_400("User not found"));
        return;
    }

    remove_sent_friend_request($main::user->{uuid}, $friend_uuid, $client_socket);

    remove_received_friend_request($friend_uuid, $main::user->{uuid}, $client_socket);

    http_utils::send_http_response($client_socket, HTTP_RESPONSE::OK("Friend Request Cancelled"));
}

sub remove_received_friend_request {
    my ($receiver_uuid, $sender_uuid, $client_socket) = @_;

    my $base_dir = getcwd();
    my $receiver_path = "$base_dir/Data/UserData/Users/$receiver_uuid/Friends";
    if (!-d $receiver_path) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_500("Internal Server Error"));
        return;
    }
    my $requests_file = "$receiver_path/received_requests.json";
    if (!-e $requests_file) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_500("Internal Server Error"));
        return;
    }


    open my $fh, '<', $requests_file;
    my $requests_data = do { local $/; <$fh> };
    close $fh;

    my $requests = decode_json($requests_data);

    my @new_requests;
    my $found = 0;
    foreach my $request (@$requests) {
        if ($request->{UserId} eq $sender_uuid) {
            $found = 1;
        } else {
            push @new_requests, $request;
        }
    }

    open $fh, '>', $requests_file;

    print $fh encode_json(\@new_requests);
    close $fh;
}

sub remove_sent_friend_request {
    my ($sender_uuid, $receiver_uuid, $client_socket) = @_;

    my $base_dir = getcwd();
    my $sender_path = "$base_dir/Data/UserData/Users/$sender_uuid/Friends";
    if (!-d $sender_path) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_500("Internal Server Error"));
        return;
    }
    my $friend_requests_file = "$sender_path/sent_requests.json";
    if (!-e $friend_requests_file) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_500("Internal Server Error"));
        return;
    }

    open my $fh, '<', $friend_requests_file;
    my $friend_requests_data = do { local $/; <$fh> };
    close $fh;

    my $friend_requests = decode_json($friend_requests_data);

    my @new_friend_requests;

    foreach my $request (@$friend_requests) {
        if ($request->{UserId} ne $receiver_uuid) {
            push @new_friend_requests, $request;
        }
    }

    open $fh, '>', $friend_requests_file;
    print $fh encode_json(\@new_friend_requests);
    close $fh;
}

sub add_friend {
    my ($uuid, $friend_uuid, $client_socket) = @_;

    my $base_dir = getcwd();
    my $friend_path = "$base_dir/Data/UserData/Users/$uuid/Friends";
    if (!-d $friend_path) {
        mkdir($friend_path) or do {
            http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_500("Internal Server Error"));
            return;
        };
    }
    my $friends_file = "$friend_path/friends.json";
    if (!-e $friends_file) {
        open my $fh, '>', $friends_file or do {
            http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_500("Internal Server Error"));
            return;
        };
        print $fh "[]";
        close($fh);
    }

    open my $fh, '<', $friends_file;
    my $friends_data = do { local $/; <$fh> };
    close $fh;

    my $friends = decode_json($friends_data);

    my %friend = (
        UserId => $friend_uuid,
        TimeAddedTimestamp => time()
    );

    push @$friends, \%friend;

    open $fh, '>', $friends_file;
    print $fh encode_json($friends);
    close $fh;
}
1;