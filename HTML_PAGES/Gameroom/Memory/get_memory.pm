package get_memory;

use strict;
use warnings;

sub get_memory {

    my $translations = language_utils::load_language("gameroom");

    my $html = <<'HTML';
    <h1>Memory</h1>
    <br>

HTML

    $html .= html_utils::create_breadcrumbs("gameroom, memory");

    $html .= html_utils::get_game_online_status($translations);

    $html .= <<HTML;
    <br>
    <div class="choose_mode">
        <div class="one_player">
            <a href="/gameroom/memory/alone">$translations->{onePlayer}</a>
        </div>
HTML
    if ($main::user->{username}) {
        $html .= <<'HTML';
        <div class="two_players">
HTML
    } else {
        $html .= <<'HTML';
        <div class="two_players_disabled" style="pointer-events: none;">
HTML
    }
    $html .= <<HTML;
            <a href="/gameroom/memory/2player/waiting">$translations->{twoPlayers}</a>
        </div>
        <br>
        <div class="spectate_game">
            <a href="/gameroom/memory/spectate">$translations->{spectate}</a>
        </div>
    </div>

HTML

    my $html_content = html_structure::get_html($html, "Memory");

    return $html_content;
}

1;