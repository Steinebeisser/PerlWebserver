package get_memory_alone;

use strict;
use warnings;

use List::Util qw(shuffle);
use Cwd;
use JSON;

sub get_memory_alone {
    my ($file_name) = @_;

    my $translations = language_utils::load_language("gameroom");

    my $html = <<HTML;
    <h1>Memory</h1>
    <br>

HTML
    $html .= html_utils::create_breadcrumbs("gameroom, memory");

    $html .= html_utils::get_game_online_status($translations);


    print("CREATING NEW\n");
    my $game = memory_utils::new($file_name);
    if (!$game) {
        print("LOADING CUZ ALREADY EXISTS\n");
        $game = memory_utils::load($file_name);
    }
    if (!$game) {
        return "Game not found";
    }

    $html .= $game;

    $html .= html_utils::get_memory_restart_button($translations);

    $html .= <<HTML;
    <br>
    <form action="/gameroom/memory/alone" method="post">
        <button type="submit">$translations->{restart}</button>
    </form>
HTML

    my $html_content = html_structure::get_html($html, "Memory");

    return $html_content;
}

1;