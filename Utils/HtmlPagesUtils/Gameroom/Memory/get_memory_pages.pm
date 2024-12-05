package get_memory_pages;

use strict;
use warnings;

use Cwd;

my $empty_memory_cookie = "memory=; expires=Thu, 01 Jan 1970 00:00:00 GMT";
# %memory::open_games,
# %memory::joining_games;
# %memory::game_controllers;
# %memory::game_info;



sub get_memory {
    my ($client_socket, $request) = @_;

    my $html = get_memory::get_memory();

    return $html;
}

sub get_memory_alone {
    my ($client_socket, $request) = @_;

    my $filename;
    my $filename_string;
    my $cookie_data = request_utils::get_cookie_data($request);

    if ($cookie_data) {
        $filename_string = $cookie_data->{memory};
        # print("FOUND EXISTING MEMORY: $filename_string\n");
        if (!$filename_string) {
            $filename_string = user_utils::create_random_string(5);
        }
        $filename = $filename_string . ".json";
    }

    my $cookie = "memory=$filename_string";

    my $html = get_memory_alone::get_memory_alone($filename);
    my $response = HTTP_RESPONSE::OK_WITH_COOKIE($html, $cookie);
    http_utils::send_http_response($client_socket, $response);
    return;
}

sub get_memory_src {
    my ($client_socket, $request) = @_;

    my $response;

    $request =~ /\/memory\/src\/(.*) HTTP/ || $request =~ /\/memory\/src\/card\/2player\/(.*) HTTP/;
    my $card = $1;

    # print("CARD: $card\n");
    my $base_dir = getcwd();
    my $card_path = "$base_dir/HTML_PAGES/Gameroom/Memory/src/$card";
    # print("CARD PATH: $card_path\n");
    
    if (-e $card_path) {
        open my $fh, '<', $card_path or die "Cannot open file: $!";
        binmode $fh;
        my $card_name;
        {
        local $/;
        $card_name = <$fh>;
        }
        close $fh;

        $response = HTTP_RESPONSE::OK_WITH_DATA_AND_CACHE($card_name, $card);
        http_utils::send_http_response($client_socket, $response);
    } else {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_404("Card not found"));
    }

    return $response;
}

sub get_memory_src_card {
    my ($client_socket, $request) = @_;

    $request =~ /\/memory\/src\/card\/(.*) HTTP/;
    my $card = $1;
    if (!$card) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_404("Card not found"));
    }

    my $cookie_data = request_utils::get_cookie_data($request);
    my $filename_string = $cookie_data->{memory};
    if (!$filename_string) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_401("You are not allowed to view this page"));
    }

    my $filename = $filename_string . ".json";

    my $base_dir = getcwd();
    my $game_path = "$base_dir/HTML_PAGES/Gameroom/Memory/activeGames/$filename";

    if (!-f $game_path) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_404("Game not found"));
    }

    open my $fh, '<', $game_path or die "Cannot open file: $!";
    my $json = do { local $/; <$fh> };
    close $fh;

    my $data = decode_json($json);

    if (!$data->{$card}) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_404("Card not found"));
    }

    my $card_name = $data->{$card};
    if (!$card_name) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_404("Card not found"));
    }

    return $card_name;
}

sub get_memory_restart {
    my ($client_socket, $request) = @_;

    my $cookie_data = request_utils::get_cookie_data($request);

    my $filename_string = $cookie_data->{memory};

    if (!$filename_string) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_401("You are not allowed to view this page"));
    }

    my $filename = $filename_string . ".json";

    my $base_dir = getcwd();
    my $game_path = "$base_dir/HTML_PAGES/Gameroom/Memory/activeGames/$filename";

    if (!-f $game_path) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_404("Game not found"));
    }

    unlink($game_path);

    my $referer = request_utils::get_referer($request);
    if (!$referer) {
        $referer = "/memory/alone";
    }
    my $response = HTTP_RESPONSE::REDIRECT_303_WITH_COOKIE($referer, $empty_memory_cookie);
    http_utils::send_http_response($client_socket, $response);
}

sub get_memory_2player {
    my ($client_socket, $request) = @_;


    my $cookie_data = request_utils::get_cookie_data($request);
    if (!$cookie_data) {
        print("COOKIE DATA EROR\n");
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_401("You are not allowed to view this page"));
        return;
    }
    my $game_id = $cookie_data->{memory};
    if (!$game_id) {
        print("GAME ID EROR\n");
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_401("You are not allowed to view this page"));
        return;
    }

    
    if (!$memory::joining_games{$game_id}) {
        print("NO JOINING GAMES\n");
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_401("You are not allowed to view this page"));
        return;
    }

    if (!$memory::game_controllers{"game_id"}{$game_id}) {
        print("NO GAME CONTROLLERS\n");
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_401("You are not allowed to view this page"));
        return;
    }

    my $player1 = $memory::game_info{$game_id}{player1};
    my $player2 = $memory::game_info{$game_id}{player2};

    if (!$player1 || !$player2) {
        print("NO PLAYERS\n");
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_401("You are not allowed to view this page"));
        return;
    }
    # if (!$memory::game_controllers{"game_id"}{$game_id}{"player1"}) {
    #     $memory::game_controllers{"game_id"}{$game_id}{"player1"} = $client_socket;    
    # } elsif (!$memory::game_controllers{"game_id"}{$game_id}{"player2"}) {
    #     $memory::game_controllers{"game_id"}{$game_id}{"player2"} = $client_socket;    
    # }


    my $html = get_memory_2player::get_memory_2player($game_id, $player1, $player2);


    return $html;
}

sub get_memory_2player_waiting {
    my ($client_socket, $request) = @_;

    my $game_id;
    if ($request =~ /\/memory\/2player\/waiting\/(.*) HTTP/) {
        $game_id = $1;
    }

    if (!$game_id) {
        print("NO GAME ID\n");
        foreach my $open_game_id (keys %memory::open_games) {
            print("OPEN GAME ID2: $open_game_id\n");
            if ($memory::open_games{$open_game_id} == 1) {
                print("OPEN GAME ID: $open_game_id\n");
                $game_id = $open_game_id;
                last;
            }
        }

        if (!$game_id) {
            $game_id = user_utils::create_random_string(6);
            # $memory::open_games{$game_id} = 1; 
        }
    }

    if (!$game_id) {
        $game_id = user_utils::create_random_string(6);
    }

    my $html = get_memory_2player_waiting::get_memory_2player_waiting($game_id);

    my $cookie = "memory=$game_id";
    http_utils::send_http_response($client_socket, HTTP_RESPONSE::OK_WITH_COOKIE($html, $cookie));
    # return $html;
}

1;