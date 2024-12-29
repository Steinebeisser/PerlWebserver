package memory_game_utils;

use strict;
use warnings;

use Cwd;
use JSON;

$memory::game_controllers{"game_id"} = {};

my %memory_types = (
    "flip_card" => \&flip_card,
    "join_queue" => \&join_queue,
    "multi_start_game" => \&multi_start_game,
    "solved_cards" => \&update_solved_cards,
    "alone_start" => \&alone_start,
    "opponent_not_connected" => \&remove_from_game,
);


sub handle_memory {
    my ($message, $client_socket) = @_;

    # print("HANDLIN MEMORY\n");

    my @sorted_types = sort { length($b) <=> length($a) } keys %memory_types;

    # print("SORTED TYPES: @sorted_types\n");

    foreach my $type (@sorted_types) {
        if ($message->{"type"} eq $type) {
            # print("HANDLING MEMORY TYPE: $type\n");
            my $answer = undef;
            if ($type eq "opponent_not_connected") {
                $answer = "opponent_not_connected";
            }
            return $memory_types{$type}->($message, $client_socket, $answer);
        }
    }
}



sub alone_start {
    my ($message, $client_socket) = @_;

    my $game_id = $message->{"game_id"};
    # print("ALONE START\n");
    # print("GAME ID: $game_id\n");

    $memory::game_info{$game_id} = {};
    $memory::game_info{$game_id}{"alone"} = 1;
    my $alone = 1;
    send_both_connected_message($game_id, $alone, $client_socket);
}

sub join_queue {
    my ($message, $client_socket) = @_;
    # print("JOINING QUEUE\n");
    my $game_id = $message->{"game_id"};

    if ($memory::spectate_games{$game_id} && $memory::spectate_games{$game_id} == 1) {
        return "spectate game: $game_id";
    }
    
    if ($memory::open_games{$game_id} && $memory::open_games{$game_id} == 1) {
        # print("STARTING GAME\n");
        my $response = start_game($game_id, $client_socket);
        if ($response eq "Same player") {
            remove_old_queue_and_start_again($game_id, $client_socket, $message);
        }
    } else {
        # print("CREATING GAME\n");
        create_game($game_id, $client_socket);
    } 
}

sub remove_old_queue_and_start_again {
    my ($game_id, $client_socket, $message) = @_;

    delete $memory::user_in_queue{$game_id};
    delete $memory::open_games{$game_id};
    delete_game_file($game_id);

    join_queue($message, $client_socket);
}

sub add_to_queue_again {
    my ($game_id, $client_socket) = @_;
    $memory::user_in_queue{$game_id} = $client_socket;
    main::epoll_loop();
}

sub start_game {
    my ($game_id, $client_socket) = @_;

    my $player1 = $memory::user_in_queue{$game_id};
    # print("PLAYER1: $player1\n");
    my $player2 = $client_socket;


    if (!$player1) {
        print("NO PLAYER 1\n");
        return;
    }

    if ($player1 == $player2) {
        # print("p1 $player1\np2 $player2\n");
        print("SAME PLAYER\n");
        return;
    }

    my $username = $main::user->{username};
    
    if ($username eq $memory::game_info{$game_id}{"player1"}) {
        # print("SAME PLAYER\n");
        # http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_400("You are already in the queue"));
        return "Same player";
    }
    if (!$username) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_400("No username"));
        return;
    }

    $memory::game_info{$game_id}{"player2"} = $username;

    delete $memory::user_in_queue{$game_id};
    delete $memory::open_games{$game_id};
    $memory::spectate_games{$game_id} = 1;
    $memory::joining_games{$game_id} = 1;

    $memory::game_controllers{"game_id"}{$game_id} = {};

    my %response = (
        type => "start_game",
        game_id => $game_id,
    );
    send_to_game_players(\%response, $game_id, $player1, $player2, $client_socket);
}

sub multi_start_game {
    my ($message, $client_socket) = @_;

    # print("MULTI START GAME\n");
    my $game_id = $message->{"game_id"};

    if (!$memory::game_controllers{"game_id"}{$game_id}{"player1"}) {
        $memory::game_controllers{"game_id"}{$game_id}{"player1"} = $client_socket;    
    } elsif (!$memory::game_controllers{"game_id"}{$game_id}{"player2"}) {
        $memory::game_controllers{"game_id"}{$game_id}{"player2"} = $client_socket;    
        send_both_connected_message($game_id);
    }

    return("NO RESPONSE");
}

sub send_both_connected_message {
    my ($game_id, $alone, $client_socket) = @_;

    my %response = (
        type => "both_connected",
        game_id => $game_id
    );

    if (!$alone) {
        my $player1 = $memory::game_controllers{"game_id"}{$game_id}{"player1"};
        my $player2 = $memory::game_controllers{"game_id"}{$game_id}{"player2"};
        websocket_utils::add_to_active_connections($player1, "Memory Game: $game_id");
        websocket_utils::add_to_active_connections($player2, "Memory Game: $game_id");
    }
    send_to_game_players(\%response, $game_id, undef, undef, $client_socket);
}

sub send_to_game_players {
    my ($response_ref, $game_id, $player1, $player2, $client_socket) = @_;
    my %response = %$response_ref;

    my $json_response = encode_json(\%response);
    # print("GAME MOOVE ENCODED RESPONSE: $json_response\n");
    my $frame_response = websocket_utils::encode_frame($json_response);
    if (!$player1 || !$player2) {
        $player1 = $memory::game_controllers{"game_id"}{$game_id}{"player1"};
        $player2 = $memory::game_controllers{"game_id"}{$game_id}{"player2"};
    }
    if (!$player1 || !$player2) {
        if ($client_socket) {
            # print("SENDING TO SOLO GUY\n");
            send($client_socket, $frame_response, 0);
        } else {
            print("DIDNT FIND PLAYERS\n");
        }
        return;
    }


    # print("SENDING TO PLAYERS\n");
    # print("PLAYER1: $player1, $memory::game_info{$game_id}{player1}\n");
    # print("PLAYER2: $player2, $memory::game_info{$game_id}{player2}\n");
    # print("RESPONSE: $frame_response\n");

    send($player1, $frame_response, 0) or warn "Failed to send to player1: $!";
    send($player2, $frame_response, 0) or warn "Failed to send to player2: $!";
}

sub create_game {
    my ($game_id, $client_socket) = @_;

    websocket_utils::add_to_active_connections($client_socket, "Memory Queue: $game_id");

    # my @connections = websocket_utils::get_active_connections($client_socket);
    # foreach my $connection (@connections) {
    #     print("CONNECTION: @$connection\n");
    #     foreach my $key (@$connection) {
    #         print("KEY: $key\disc");
    #     }
    # }

    # print("CREATING GAME\n");
    my $filename = "$game_id.json";

    my $base_dir = getcwd();
    my $game_path = "$base_dir/HTML_PAGES/Gameroom/Memory/activeGames/$filename";

    if (-f $game_path) {
        print("GAME ALREADY EXISTS\n");
        # http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_400("Game already exists"));
        return "Game already exists";
    }

    memory_utils::new($filename, 1, 1);

        # print("COOKIE DATA EROR\n");
        # http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_400("No cookie data"));

    # foreach my $key (keys %$cookie_data) {
        # print("KEY: $key\n");
    # }
    # print("COOKIE DATA: $cookie_data\n");
    # print("USERNAME: $username\n");
    my $uuid = $main::user->{uuid};
    my $username = user_utils::get_username_by_uuid($uuid);
    if (!$username) {
        # print("USERNAME EROR\n");
        # http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_400("No username"));
        return;
    }
    
    $memory::game_info{$game_id} = {};
    $memory::game_info{$game_id}{"player1"} = $username; 
    
    $memory::user_in_queue{$game_id} = $client_socket;
    $memory::open_games{$game_id} = 1;

    # print($memory::open_games{$game_id});

    my $response = "created queue: $game_id";
    # print("RESPONSE CREATING GAME: $response\n");
    return $response;
}

sub move_waiting_player {
    my ($game_id ,$response) = @_;

    my $waiting_player_socket = $memory::user_in_queue{$game_id};

    if (!$waiting_player_socket) {
        return;
    }

    $response = encode_json($response);
    # print("MOVING ENCODING RESPONSE: $response\n");
    $response = websocket_utils::encode_frame($response);

    send($waiting_player_socket, $response, 0);
}

# sub add_to_spectate_games_route {
#     my ($game_id) = @_;

#     $index_router{"/gameroom/memory/2player/spectate/$game_id"} = \&spectate_game;
# }


sub flip_card {
    my ($message, $client_socket) = @_;
    my $game_id = $message->{"game_id"};
    my $card_id = $message->{"card_id"};

    my $filename = "$game_id.json";

    my $base_dir = getcwd();
    my $game_path = "$base_dir/HTML_PAGES/Gameroom/Memory/activeGames/$filename";

    if (!-f $game_path) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_404("Game not found"));
    }

    open my $fh, '<', $game_path or die "Cannot open file $game_path: $!";
    my $json = do { local $/; <$fh> };
    close $fh;

    my $data = decode_json($json);

    if (!$data->{$card_id}) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_404("Card not found"));
    }

    my $card_name = $data->{$card_id};
    if (!$card_name) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_404("Card not found"));
    }

    $memory::game_info{$game_id}{"moves"} += 1;

    my %response = (
        type => "flipped_card",
        card_flipped => $card_id,
        card_name => $card_name,
        game_id => $game_id
    );

    send_to_game_players(\%response, $game_id, undef, undef, $client_socket);

    # my $response;
    # return $card_name;
    return "NO RESPONSE";
}

sub update_solved_cards {
    my ($message, $client_socket) = @_;
    my $solved_cards = $message->{"solved_cards"};
    my $player = $message->{"player"};
    my $game_id = $message->{"game_id"};

    print("SOLVI CARDI $solved_cards\n");
    print("PLAYER: $player\n");
    print("GAME ID: $game_id\n");

    my $filename = "$game_id.json";
    my $base_dir = getcwd();
    my $game_path = "$base_dir/HTML_PAGES/Gameroom/Memory/activeGames/$filename";

    if (!-f $game_path) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_404("Game not found"));
    }

    open my $fh, '<', $game_path or die "Cannot open file $game_path: $!";
    my $json = do { local $/; <$fh> };
    close $fh;

    my $data = decode_json($json);

    # $player = user_utils::encode_uri($player);

    $data->{$player}{solved_cards} .= $solved_cards;
    $data->{$player}{solved_cards_amount} += 1;

    $memory::game_info{$game_id}{solved_cards} += 1;
    if ($memory::game_info{$game_id}{alone}) {
        $memory::game_info{$game_id}{solved_cards} += 1;
    }
    if ($memory::game_info{$game_id}{solved_cards} == 16) {
        $memory::game_info{$game_id}{finished} = 1;
        my %response = (
            type => "game_end",
            game_id => $game_id,
            player => $player
        );
        send_to_game_players(\%response, $game_id, undef, undef, $client_socket);
    }

    my $encoded_data = encode_json($data);

    open $fh, '>', $game_path or die "Cannot open file $game_path: $!";
    print $fh $encoded_data;
    close $fh;

    my %response = (
        type => "solved_cards",
        solved_cards => $solved_cards,
        player => $player,
        game_id => $game_id
    );
    
    send_to_game_players(\%response, $game_id, undef, undef, $client_socket);
    return "NO RESPONSE";
}

sub remove_from_queue {
    my ($client_socket, $connection) = @_;

    # print("CONNECTIOOOON: $connection\n");
    if ($connection =~ /Memory Queue: (.*)/) {
        # print("REMOVING FROM QUEUE\n");
        my $game_id = $1;
        delete $memory::user_in_queue{$game_id};
        delete $memory::open_games{$game_id};
        delete_game_file($game_id);
    }
    # print("DONE REMOVING FROM QUEUE\n");
}

sub delete_game_file {
    my ($game_id) = @_;

    my $filename = "$game_id.json";
    my $base_dir = getcwd();
    my $game_path = "$base_dir/HTML_PAGES/Gameroom/Memory/activeGames/$filename";

    if (-f $game_path) {
        unlink $game_path;
    }
}

sub remove_from_game {
    my ($client_socket, $connection, $message) = @_;

    if (!$message) {
        $message = "opponent_disconnected";
    }
    print("CONNECTIOOOON: $connection\n");
    if ($connection =~ /Memory Game: (.*)/) {
        print("REMOVING FROM GAME\n");
        my $game_id = $1;
        inform_opponents($game_id, $client_socket, $message);
        delete $memory::game_controllers{"game_id"}{$game_id};
        delete $memory::spectate_games{$game_id};
        if (!$memory::game_info{$game_id}{finished}) {
            delete $memory::game_info{$game_id};
        }
        move_game_file($game_id);
    }
    print("DONE REMOVING FROM GAME\n");
}

sub move_game_file {
    my ($game_id) = @_;

    my $filename = "$game_id.json";
    my $base_dir = getcwd();
    my $game_path = "$base_dir/HTML_PAGES/Gameroom/Memory/activeGames/$filename";
    my $game_path2 = "$base_dir/HTML_PAGES/Gameroom/Memory/oldGames/$filename";

    if (!-d $game_path2) {
        mkdir $game_path2;
    }

    if (-f $game_path) {
        rename $game_path, $game_path2;
    }
}

sub inform_opponents {
    my ($game_id, $client_socket, $message) = @_;

    my $player1 = $memory::game_controllers{"game_id"}{$game_id}{"player1"};
    my $player2 = $memory::game_controllers{"game_id"}{$game_id}{"player2"};

    my $myUsername;
    my $opponentUsername;
    if ($player1 == $client_socket) {
        # print("PLAYER1: $player1\nCLIENT: $client_socket\n");
        $myUsername = $memory::game_info{$game_id}{"player1"};
        $opponentUsername = $memory::game_info{$game_id}{"player2"};
    } else {
        $myUsername = $memory::game_info{$game_id}{"player2"};
        $opponentUsername = $memory::game_info{$game_id}{"player1"};
    }

    # print("myUsername: $myUsername\n");
    # print("opponentUsername: $opponentUsername\n");

    # print("MESSAGE: $message\n");
    my %msg = (
        type => $message,
        game_id => $game_id,
        player => $myUsername
    );

    send_to_game_players(\%msg, $game_id);
}
1;