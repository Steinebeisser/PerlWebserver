package memory_utils;

use strict;
use warnings;

use Cwd;
use JSON;
use List::Util qw(shuffle);

sub new {
    my ($file_name, $is_multiplayer, $just_create) = @_;

    print("IS1 MULTIPLAYER: $is_multiplayer\n");

    my $base_dir = getcwd();
    my $card_dir = "$base_dir/HTML_PAGES/Gameroom/Memory/activeGames";

    if (!-d $card_dir) {
        mkdir $card_dir;
    }

    if (-f $card_dir . "/" . $file_name) {
        print("GAME ALREADY EXISTS\n");
        return 0;
    }

    my @cards = (
        "src/memory_card1.png", 
        "src/memory_card2.png", 
        "src/memory_card3.png", 
        "src/memory_card4.png", 
        "src/memory_card5.png", 
        "src/memory_card6.png", 
        "src/memory_card7.png", 
        "src/memory_card8.png", 
        "src/memory_card1.png",
        "src/memory_card2.png",
        "src/memory_card3.png",
        "src/memory_card4.png",
        "src/memory_card5.png",
        "src/memory_card6.png",
        "src/memory_card7.png",
        "src/memory_card8.png",
    );

    @cards = shuffle(@cards);
    @cards = shuffle(@cards);
    @cards = shuffle(@cards);
    @cards = shuffle(@cards);
    my %card_pairs = ();
    
    my $html .= create_field(\%card_pairs, \@cards, $is_multiplayer);
    # print("FIELD HTML: $html\n");
    # print("CARD PAIRS:", encode_json(\%card_pairs), "\n");

    open my $fh, ">", "$card_dir/$file_name", or do 
    {
        print "Can't open file $card_dir/$file_name: $!";
        return;
    };
    print $fh encode_json(\%card_pairs);
    close $fh;

    if ($just_create) {
        return 1;
    }

    $html .= <<HTML;
    </div>

HTML

    

    return $html;
}

sub load {
    my ($file_name, $is_multiplayer) = @_;
    my @cards;

    my $base_dir = getcwd();
    my $card_dir = "$base_dir/HTML_PAGES/Gameroom/Memory/activeGames";

    if (!-d $card_dir) {
        return 0;
    }

    if (!-f $card_dir . "/" . $file_name) {
        return 0;
    }

    open my $fh, "<", "$card_dir/$file_name", or do 
    {
        print "Can't open file $card_dir/$file_name: $!";
        return;
    };
    my $json = do { local $/; <$fh> };
    close $fh;

    my %card_pairs = %{decode_json($json)};

    my $html = create_field(\%card_pairs, \@cards, $is_multiplayer);

    $html .= <<HTML;
    </div>

HTML

    return $html;
}

sub create_field {
    my ($card_pairs_ref, $cards_ref, $is_multiplayer) = @_;
    my $card_pairs = $card_pairs_ref;
    my @cards = @$cards_ref;

    my $translations = language_utils::load_language("gameroom");

    print("IS MULTIPLAYER: $is_multiplayer\n");

    my $base_path = getcwd();
    my $script_path;
    if ($is_multiplayer) {
        $script_path = $base_path . "/Utils/JavaScript/memory/multi.js";
    } else {
        $script_path = $base_path . "/Utils/JavaScript/memory/alone.js";
    }
    open my $fh, "<", $script_path or do 
    {
        print "Can't open file: $!";
        return;
    };
    my $script = do { local $/; <$fh> };
    close $fh;

    my $both_script_path = $base_path . "/Utils/JavaScript/memory/both.js";
    open $fh, "<", $both_script_path or do 
    {
        print "Can't open file: $!";
        return;
    };
    my $both_script = do { local $/; <$fh> };
    close $fh;

    $script .= $both_script;

    my @img_loading_cards = (
        "src/memory_card1.png",
        "src/memory_card2.png",
        "src/memory_card3.png",
        "src/memory_card4.png",
        "src/memory_card5.png",
        "src/memory_card6.png",
        "src/memory_card7.png",
        "src/memory_card8.png",
    );

    my $script_v2 = preload_images_script(@img_loading_cards);

    $script .= $script_v2;
    
    my $script_embed = <<SCRIPT;
    <script>
        $script 
    </script>
SCRIPT


    my $html .= <<HTML;
    $script_embed
    <div class="memory_game">
HTML

    for my $i (0..3) {
    $html .= <<HTML;
    <div class="memory_row">
HTML
    for my $j (1..4) {
        my $field_id = $i * 4 + $j;
        $html .= <<HTML;
        <!-- <div class="memory_field" id="memory_field$field_id" onclick="flipCard($field_id)"> -->
        <button class="memory_field" id="memory_field$field_id" onclick="flipCard($field_id)">
            <img class="memory_field_back" src="src/deckblatt.png" alt="$translations->{memoryBackCard}">
        </button>
        <!-- </div> -->
HTML
    if (!$card_pairs->{$field_id}) {
        # print("FIELD ID DOESNT EXIST, ADDING: $field_id\n");
        $card_pairs->{$field_id} = $cards[$field_id - 1];
    }
    }
    
    $html .= <<HTML;
    </div>
HTML
    }


    # $html .= $script;
    
    return $html;
}

sub preload_images_script {
    my (@cards) = @_;
    my $script = "window.onload = function() {\n";
    # print("CARDS: @cards\n");
    foreach my $card (@cards) {
        # print("CARD: $card\n");
        $script .= <<SCRIPT;
        var img = new Image();
        img.src = "$card";
SCRIPT
    }
    $script .= "}\n";
    return $script;
}


1;

