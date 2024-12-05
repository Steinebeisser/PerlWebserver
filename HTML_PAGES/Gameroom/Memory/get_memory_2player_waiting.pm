package get_memory_2player_waiting; 

use strict;
use warnings;

use Cwd;

sub get_memory_2player_waiting {
    my ($game_id) = @_;

    my $translations = language_utils::load_language("gameroom");

    my $html = <<HTML;
    <h1>Memory</h1>
    <br>

HTML
    $html .= html_utils::create_breadcrumbs("gameroom, memory");

    $html .=<<HTML;
    <h2>Waiting for player 2</h2>
    <br>
    <br>
    <a href="/gameroom">$translations->{back}</a>
HTML

    my $base_dir = getcwd();
    my $script_path = $base_dir . "/Utils/JavaScript/Queue/memory_queue.js";
    open my $fh, "<", $script_path or do
    {
        print "Can't open file $script_path: $!";
        return;
    };
    my $script = do { local $/; <$fh> };
    close $fh;

    $script =~ s/game_id_placeholder/$game_id/g;


    $html .=<<SCRIPT;
    <script>
        $script
    </script>
SCRIPT
    
    my $html_content = html_structure::get_html($html, "Memory");

    return $html_content;
}

1;