package get_memory_2player;

use strict;
use warnings;

sub get_memory_2player {
    my ($game_id, $player1, $player2) = @_;

    $player1 = user_utils::decode_uri($player1);
    $player2 = user_utils::decode_uri($player2);
    my $myUsername = user_utils::decode_uri($main::user->{username});
    my $translations = language_utils::load_language("gameroom");

    my $html = <<HTML;
    <h1>Memory</h1>
    <br>

HTML
    $html .= html_utils::create_breadcrumbs("gameroom, memory");

    $html .= html_utils::get_game_online_status($translations);


    # print("CREATING NEW\n");
    my $file_name = "$game_id.json";
    my $is_multiplayer = 1;
    $html .= <<HTML;
    <div class="memory_frame">
        <div class="player1_container">
            <div class="player1">$translations->{player1}</div>
            <div class="player1_name">$player1</div>
            <div class="player1_score">0</div>
        </div>
HTML
    my $game = memory_utils::new($file_name, $is_multiplayer);
    if (!$game) {
        # print("LOADING CUZ ALREADY EXISTS\n");
        $game = memory_utils::load($file_name, $is_multiplayer);
    }
    if (!$game) {
        return "Game not found";
    }

    $html .= $game;
    
    $html .= <<HTML;
        <div class="player2_container">
            <div class="player2">$translations->{player2}</div>
            <div class="player2_name">$player2</div>
            <div class="player2_score">0</div>
        </div>
    </div>
    <div class="hidden">
        <div class="my_username">$myUsername</div>
        <div class="game_id">$game_id</div>
    </div>
HTML

    # $html .= html_utils::get_memory_restart_button($translations);

    $html .= html_utils::get_wait_connection_layer($translations);

    $html .= html_utils::get_ping_display($translations);

    my $html_content = html_structure::get_html($html, "Memory");

    return $html_content;
}

1;
