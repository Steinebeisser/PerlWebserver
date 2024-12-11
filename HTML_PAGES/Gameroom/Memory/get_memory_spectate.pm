package get_memory_spectate;

use strict;
use warnings;

sub get_memory_spectate {

    my $translations = language_utils::load_language("gameroom");

    my @spectate_games = game_utils::get_spectate_games("memory");

    my $html;

    $html .= html_utils::create_breadcrumbs("gameroom, memory");

    $html .= html_utils::get_game_online_status($translations);

    foreach my $game_id (@spectate_games) {
    $html = <<"HTML";
    <div class="game_frame">
        <h1>Memory Game</h1>
        $game_id
        <a href="/gameroom/memory/spectate/$game_id">Spectate</a>
    </div>
HTML

    }

    my $html_content = html_structure::get_html($html, "Memory");

    return $html_content;
}

1;