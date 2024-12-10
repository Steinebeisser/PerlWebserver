package get_memory_end;

use strict;
use warnings;

use Cwd;
use JSON;

sub get_memory_end {
    my ($game_id, $client_socket) = @_;

    my $translations = language_utils::load_language("gameroom");

    my $lost;
    my $draw;
    my $won;

    my $user = $main::user;
    my $username = $user->{"username"};

    my $game_file = "$game_id.json";
    my $base_dir = getcwd();
    my $game_path = "$base_dir/HTML_PAGES/Gameroom/Memory/activeGames/$game_file";

    if (!-f $game_path) {
        print("GAME_PATH: $game_path\n");
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_404($translations->{"game_not_found"}));
    }

    open my $fh, '<', $game_path or die "Cannot open file $game_path: $!";
    my $json = do { local $/; <$fh> };
    close $fh;

    my $data = decode_json($json);
    my $my_player = user_utils::decode_uri($username);
    my $opponent;
    my $moves;

    if (!$data) {
        print("DATA: $data\n");
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_404($translations->{"game_not_found"}));
    }

    if (!$memory::game_info{$game_id}) {
        print("GAME_INFO: $memory::game_info{$game_id}\n");
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_404($translations->{"game_not_found"}));
    }

    if (!$memory::game_info{$game_id}{"alone"}) {
        if ($memory::game_info{$game_id}{"player1"} ne $username) {
            if ($memory::game_info{$game_id}{"player2"} ne $username) {
                print("GAME_INFO: $memory::game_info{$game_id}\n");
                http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_404($translations->{"game_not_found"}));
            } else {
                $my_player = $memory::game_info{$game_id}{"player2"};
                $opponent = $memory::game_info{$game_id}{"player1"};
            }
        } else {
            $my_player = $memory::game_info{$game_id}{"player1"};
            $opponent = $memory::game_info{$game_id}{"player2"};
        }

        $my_player = user_utils::decode_uri($my_player);
        $opponent = user_utils::decode_uri($opponent);
    } else {
        $moves = $memory::game_info{$game_id}{"moves"}/2;
    }

    $username = user_utils::encode_uri($my_player);
    $opponent = user_utils::encode_uri($opponent);
    print("USERNAME: $username\n");
    my $solved_cards = $data->{$username}{solved_cards};
    my $solved_cards_amount_self = $data->{$username}{solved_cards_amount}/2;
    my $solved_cards_amount_enemy = $data->{$opponent}{solved_cards_amount}/2;

    if (!$memory::game_info{$game_id}{"alone"}) {
        if ($solved_cards_amount_self) {
            if ($solved_cards_amount_self < 4) {
                $lost = 1;
            } elsif ($solved_cards_amount_self == 4) {
                $draw = 1;
            } else {
                $won = 1;
            }
        } else {
            $lost = 1;
        }
    } 

    my $html = <<HTML;
    <h1>Memory</h1>
    <br>
    <br>
    <div class="memory_end_frame">
        <h2>$translations->{gameOver}</h2>
        <br>
        <br>
HTML
    if (!$memory::game_info{$game_id}{"alone"}) {
        $html .= <<HTML;
        <div class="vs_frame">
            <div class="p1_frame">

HTML
    }
    $html .= <<HTML;
        <h3>$translations->{player}: $my_player</h3>
        <h3>$translations->{solvedCardsAmount}: $solved_cards_amount_self</h3>
        <br>
HTML
    if (!$memory::game_info{$game_id}{"alone"}) {
        $html .= <<HTML;
            </div>
            <div class="vs">VS</div>
            <div class="p2_frame">
                <h3>$translations->{opponent}: $opponent</h3>
                <h3>$translations->{solvedCardsAmount}: $solved_cards_amount_enemy</h3>
                <br>
            </div>
HTML
    } else {
        $html .= <<HTML;
        <h3>$translations->{moves}: $moves</h3>
HTML
    }
    $html .= <<HTML;
        <br>
        <br>
HTML

    if (!$memory::game_info{$game_id}{"alone"}) {
    my $text;
        if ($lost) {
            $text = $translations->{youLost};
        } elsif ($draw) {
            $text = $translations->{youDrawed};
        } elsif($won) {
            $text = $translations->{youWon};
        } else {
            $text = $translations->{whySeeThis};
        }
    $html .= <<HTML;
        <h3>$text</h3>
HTML
    }
    $html .= <<HTML;
    </div>
    <br>
    <br>
    <br>
    <h1>$translations->{gameId}: $game_id</h1>
    </div>
    <a href="/gameroom/memory">$translations->{backToMemory}</a>
    <br>
    <br>
    <a href="/ \">$translations->{backToIndex}</a>
    <br>
    <br>
HTML
    
    my $end_translation;
    if ($lost) {
        $end_translation = $translations->{lostMemory};
    } elsif ($draw) {
        $end_translation = $translations->{drawMemory};
    } elsif ($won) {
        $end_translation = $translations->{wonMemory};
    } else {
        $end_translation = $translations->{whySeeThis};
    }
    my $html_content = html_structure::get_html($html, $end_translation);
}

1;