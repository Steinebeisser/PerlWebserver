package websocket_utils;

use strict;
use warnings;
use IO::Epoll;
use JSON;
use Cwd;

my %memory_types = (
    "flip_card" => \&flip_card,
    "join_queue" => \&join_queue,
    "multi_start_game" => \&multi_start_game,
);

sub receive_msg {
    my ($client_socket) = @_;
    my $client_fd = fileno $client_socket;
    print("RECEIVING FOR CLIENT $client_fd\n");

    my $message = $epoll::clients{$client_fd}{"request"};
    if ($epoll::clients{$client_fd}{"more"} != 0) {
        print("RECEIVING MESSAGE\n");
        recv($client_socket, my $buffer, 1024, 0);
        $message .= $buffer;
        $epoll::clients{$client_fd}{"request"} .= $buffer;
        if (length($buffer) < 1024) {
            $epoll::clients{$client_fd}{"more"} = 0;
        }
    }

    if (!$message) {
        print("REMOVING DISCONNECTED CLIENT ".($client_fd)."\n");
        close($client_socket);
        delete $epoll::clients{$client_fd};
        remove_from_games($client_fd);
        return;
    }

    print("RAW MESSAGE: " . unpack("H*", $message) . ".\n");

    # my $message;
    # while (1) {
    #     recv($client_socket, my $buffer, 1024, 0);
    #     $message .= $buffer;
    #     print("BONJOUR\n");
    #     last if length($buffer) < 1024;
    # }

    if ($epoll::clients{$client_fd}{"more"} != 0) {
        return;
    }

    print("MESSAGE: $message\n");
    my $decoded_message = decode_frame($message, $client_socket);
    print("DECODED MESSAGE: $decoded_message\n");

    # my $answer_frame = encode_frame("Hello from server");
    # send($client_socket, $answer_frame, 0);

    return $decoded_message;
}

sub encode_frame {
    my ($message) = @_;

    my $message_length = length($message);
    my $frame = "";

    if ($message_length < 125) {
        print("ENCODING MSG UNDER 125\n");
        my $byte1 = pack("C", 0b10000001);
        $frame = pack("C", 0b10000001) . pack("C", $message_length) . $message;
    } elsif ($message_length < 65536) {
        print("ENCODING MSG UNDER 65536\n");
        $frame = pack("C", 0b10000001) . pack("C", 126) . pack("n", $message_length) . $message;
    } else {
        print("ENCODING MSG OVER 65536\n");
        $frame = pack("C", 0b10000001) . pack("C", 127) . pack("Q>", $message_length) . $message;
    }

    print("FRAME: $frame\n");
    print("DECODED FRAME: " . unpack("H*", $frame) . "\n");

    return $frame;
}

sub decode_frame {
    my ($message, $client_socket) = @_;

    if (!$message) {
        return;
    }

    my $encoded_msg = unpack("H*", $message);
    # print("ENCODED MSG: $encoded_msg\n");

    my $byte1 = unpack("C", substr($message, 0, 1));
    # print("BYTE1: $byte1\n");
    my $fin = ($byte1 >> 7) & 0b00000001;
    my $rsv1 = ($byte1 >> 6) & 0b00000001;
    my $rsv2 = ($byte1 >> 5) & 0b00000001;
    my $rsv3 = ($byte1 >> 4) & 0b00000001;
    my $opcode = $byte1 & 0b00001111;

    # print("FIN: $fin\n");
    print("RSV1: $rsv1\n");
    # print("RSV2: $rsv2\n");
    # print("RSV3: $rsv3\n");
    print("OPCODE: $opcode\n");

    if ($opcode == 0x8) {
        print("CLOSING CONNECTION\n");
        send($client_socket, pack("C", 0x88), 0);
        close($client_socket);
        return;
    }

    my $mask = unpack("C", substr($message, 1, 1)) >> 7 & 0b00000001;
    # print("MASK: $mask\n");

    if (!$mask) {
        # print("No mask\n");
        no_mask_error($client_socket); # ! maski error machen 1002 protocol error close
        return;
    }
    my ($payload_length, $last_byte) = get_payload_length($message);

    # print("LAST BYTE: $last_byte\n");
    # print("PAYLOAD LENGTH: $payload_length\n");

    my @masking_key = get_masking_key($message, $last_byte);
    # print("MASKING KEY: @masking_key\n");

    my $encode_data = substr($message, $last_byte+5, $payload_length);

    my $decoded_data = decode_data($encode_data, @masking_key, $payload_length);
    # print("DECODED DATA: $decoded_data\n");
    
    return $decoded_data;
}

sub no_mask_error {
    my ($client_socket) = @_;
    my $error_frame = encode_frame("1002 Protocol Error");
    print("NO MASK\n");
    send($client_socket, $error_frame, 0);
    close($client_socket);
    warn "Protocol error: No mask present in the frame";
}

sub decode_data {
    my ($encoded_data, @masking_key, $payload_length) = @_;

    my $decoded_data = "";

    # print("ENCODED DATA: $encoded_data\n");
    my $hex_encoded = unpack("H*", $encoded_data);
    # print("ENCODED DATA: $hex_encoded\n");
    # print("LENGTH: " . length($encoded_data) . "\n");

    for (my $i = 0; $i < length($encoded_data); $i++) {
        my $byte = substr($encoded_data, $i, 1);
        my $mask_byte = $masking_key[$i % 4];
        my $decoded_byte = $byte ^ $mask_byte;
        $decoded_data .= $decoded_byte;
        # print("BYTE: " . unpack("H2", $byte) . " MASK BYTE: " . unpack("H2", $mask_byte) . " DECODED BYTE: " . unpack("H2", $decoded_byte) . "\n");
    }
    # print("DECODED DATA: $decoded_data\n");

    return $decoded_data;
}

sub get_payload_length {
    my ($message) = @_;

    my $byte2 = unpack("C", substr($message, 1, 1));
    # print("BYTE2: $byte2\n");

    my $length;
    my $last_byte;

    my $payload_length = $byte2 & 0b01111111;
    # print("PAYLOAD LENGTH: $payload_length\n");
    if ($payload_length <= 125) {
        $length = $payload_length;
        $last_byte = 1;
    } elsif ($payload_length == 126) {
        my $byte3and4 = unpack("n", substr($message, 2, 2));
        # print("BYTE3AND4: $byte3and4\n");
        $length = $byte3and4;
        $last_byte = 3;
    } elsif ($payload_length == 127) {
        my $bytes3to10 = unpack("Q", substr($message, 2, 8));
        # print("BYTES3TO10: $bytes3to10\n");
        $length = $bytes3to10;
        $last_byte = 9;
    }
    
    return ($length, $last_byte);
}

sub get_masking_key {
    my ($message, $last_byte) = @_;

    my @masking_key;
    @masking_key[0] = substr($message, $last_byte+1, 1);
    @masking_key[1] = substr($message, $last_byte+2, 1);
    @masking_key[2] = substr($message, $last_byte+3, 1);
    @masking_key[3] = substr($message, $last_byte+4, 1);
    
    foreach my $key (@masking_key) {
        # print("KEY: $key\n");
        # print("Masking Key: ", unpack("H*", $key), "\n");
    }

    return @masking_key;
}

sub handle_websocket_request {
    my ($client_socket, $request) = @_;

    # print("WEBSOCKET REQUEST\n");
    # print("REQUEST: $request\n");
    if ($request =~ /Sec-WebSocket-Version: (.*)\r\n/) {
        my $version = $1;
        if ($version ne "13") {
            http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_400_WEBSOCKET_VERSION("Unsupported WebSocket version"));
            return;
        }
    }
    if ($request =~ /Sec-WebSocket-Key: (.*)\r\n/) {
        my $key = $1;

        my $response = HTTP_RESPONSE::SWITCHING_PROTOCOLS_101($key);
        http_utils::send_response($client_socket, $response);
        
        
        # epoll_ctl($main::epoll, EPOLL_CTL_ADD, fileno $client_socket, EPOLLIN) >= 0 || die "Can't add client socket to epoll: $!";

        
    
        print("WEBSOCKET UPGRADED\n");

        main::epoll_loop();
    }
}

sub handle_websocket_communication {
    my ($client_fd) = @_;

    print("HANDLING WEBSOCKET COMMUNICATION\n");
    my $client_socket = $epoll::clients{$client_fd}{"socket"};

    # send($client_socket, "Hello from server", 0) or die "send: $!";

    my $message = websocket_utils::receive_msg($client_socket);
    if (!$message) {
        return;
    }
    print("MESSAGE: $message\n");

    my $message_hash;
    eval {
        $message_hash = decode_json($message);
        1;
    } or do {
        warn "Invalid JSON string: $message";
    };

    my $response;

    if (!$message_hash) {
        $response = "msg: BONJOUR";
    } else {
        print("GETTING RESPONSE\n");
        $response = get_response($message_hash, $client_socket);
    }


    if ($response && $response eq "NO RESPONSE") {
        return;
    }

    $response = encode_json($response);

    print("ENCODED RESPONSE: $response\n");
    $response = websocket_utils::encode_frame($response);
    print("SENDING RESPONSE: $response to CLIENT SOCKET $client_socket\n");
    send($client_socket, $response, 0) or warn "Failed to send response: $!";
    # my $client_socket = $epoll::clients{$client_fd};
    # my $response = HTTP_RESPONSE::OK("HELLO");
    # close($client_socket);
}


sub get_response {
    my ($message, $client_socket) = @_;
    if (ref($message) ne "HASH") {
        return("HELLO FROM SERVER");
    }

    if ($message->{"game"} eq "memory") {
        return handle_memory($message, $client_socket);
    }
}

sub handle_memory {
    my ($message, $client_socket) = @_;

    print("HANDLIN MEMORY\n");

    my @sorted_types = sort { length($b) <=> length($a) } keys %memory_types;

    # print("SORTED TYPES: @sorted_types\n");

    foreach my $type (@sorted_types) {
        if ($message->{"type"} eq $type) {
            print("HANDLING MEMORY TYPE: $type\n");
            return $memory_types{$type}->($message, $client_socket);
        }
    }
}

sub join_queue {
    my ($message, $client_socket) = @_;
    print("JOINING QUEUE\n");
    my $game_id = $message->{"game_id"};

    if ($memory::spectate_games{$game_id} && $memory::spectate_games{$game_id} == 1) {
        return "spectate game: $game_id";
    }
    
    if ($memory::open_games{$game_id} && $memory::open_games{$game_id} == 1) {
        print("STARTING GAME\n");
        my $response = start_game($game_id, $client_socket);
        if ($response eq "Same player") {
            add_to_queue_again($game_id, $client_socket);
        }
    } else {
        print("CREATING GAME\n");
        create_game($game_id, $client_socket);
    } 
}

sub add_to_queue_again {
    my ($game_id, $client_socket) = @_;
    $memory::user_in_queue{$game_id} = $client_socket;
    main::epoll_loop();
}

sub start_game {
    my ($game_id, $client_socket) = @_;

    my $player1 = $memory::user_in_queue{$game_id};
    print("PLAYER1: $player1\n");
    my $player2 = $client_socket;


    if (!$player1) {
        print("NO PLAYER 1\n");
        return;
    }

    if ($player1 == $player2) {
        print("SAME PLAYER\n");
        return;
    }

    my $cookie_data = request_utils::get_cookie_data($main::header);
    if (!$cookie_data) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_400("No cookie data"));
        return;
    }
    my $username = $cookie_data->{"username"};
    if ($username eq $memory::game_info{$game_id}{"player1"}) {
        print("SAME PLAYER\n");
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
    # add_to_spectate_games_route($game_id);
    $memory::joining_games{$game_id} = 1;


    $memory::game_controllers{"game_id"} = {};
    $memory::game_controllers{"game_id"}{$game_id} = {};
    # $memory::game_controllers{$game_id}{"player1"} = $player1;
    # $memory::game_controllers{$game_id}{"player2"} = $player2;

    my %response = (
        type => "start_game",
        game_id => $game_id,
    );
    send_to_game_players(\%response, $game_id, $player1, $player2, $client_socket);
}

sub multi_start_game {
    my ($message, $client_socket) = @_;

    print("MULTI START GAME\n");
    my $game_id = $message->{"game_id"};

    if (!$memory::game_controllers{"game_id"}{$game_id}{"player1"}) {
        $memory::game_controllers{"game_id"}{$game_id}{"player1"} = $client_socket;    
    } elsif (!$memory::game_controllers{"game_id"}{$game_id}{"player2"}) {
        $memory::game_controllers{"game_id"}{$game_id}{"player2"} = $client_socket;    
    }

    print("PLAYER 1: $memory::game_controllers{$game_id}{player1}\n");
    print("PLAYER 2: $memory::game_controllers{$game_id}{player2}\n");

    return("NO RESPONSE");
}

sub send_to_game_players {
    my ($response_ref, $game_id, $player1, $player2, $client_socket) = @_;
    my %response = %$response_ref;

    my $json_response = encode_json(\%response);
    print("GAME MOOVE ENCODED RESPONSE: $json_response\n");
    my $frame_response = websocket_utils::encode_frame($json_response);
    if (!$player1 || !$player2) {
        $player1 = $memory::game_controllers{"game_id"}{$game_id}{"player1"};
        $player2 = $memory::game_controllers{"game_id"}{$game_id}{"player2"};
    }
    if (!$player1 || !$player2) {
        if ($client_socket) {
            print("SENDING TO SOLO GUY\n");
            send($client_socket, $frame_response, 0);
        } else {
            print("BOHOOOO\n");
        }
        return;
    }


    print("SENDING TO PLAYERS\n");
    print("PLAYER1: $player1, $memory::game_info{$game_id}{player1}\n");
    print("PLAYER2: $player2, $memory::game_info{$game_id}{player2}\n");
    print("RESPONSE: $frame_response\n");

    send($player1, $frame_response, 0) or warn "Failed to send to player1: $!";
    send($player2, $frame_response, 0) or warn "Failed to send to player2: $!";
}

sub create_game {
    my ($game_id, $client_socket) = @_;

    print("CREATING GAME\n");
    my $filename = "$game_id.json";

    my $base_dir = getcwd();
    my $game_path = "$base_dir/HTML_PAGES/Gameroom/Memory/activeGames/$filename";

    if (-f $game_path) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_400("Game already exists"));
    }

    memory_utils::new($filename, 1, 1);

    my $cookie_data = request_utils::get_cookie_data($main::header);
    if (!$cookie_data) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_400("No cookie data"));
        return;
    }
    my $username = $cookie_data->{"username"};
    if (!$username) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_400("No username"));
        return;
    }
    
    $memory::game_info{$game_id} = {};
    $memory::game_info{$game_id}{"player1"} = $username; 
    

    $memory::user_in_queue{$game_id} = $client_socket;
    $memory::open_games{$game_id} = 1;

    print($memory::open_games{$game_id});

    my $response = "created queue: $game_id";
    return $response;
}

sub move_waiting_player {
    my ($game_id ,$response) = @_;

    my $waiting_player_socket = $memory::user_in_queue{$game_id};

    if (!$waiting_player_socket) {
        return;
    }



    $response = encode_json($response);
    print("MOVING ENCODING RESPONSE: $response\n");
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

sub remove_from_games {
    my ($client_fd) = @_;

    foreach my $game_id (keys %memory::game_controllers) {
        if ($memory::game_controllers{$game_id}{"player1"} == $client_fd) {
            delete $memory::game_controllers{$game_id}{"player1"};
        } elsif ($memory::game_controllers{$game_id}{"player2"} == $client_fd) {
            delete $memory::game_controllers{$game_id}{"player2"};
        }
    }
}

1;