package game_utils;

use strict;
use warnings;

my %game_types = (
    "memory" => \&memory_game_utils::handle_memory,
);


sub handle_game_index {
    my ($message, $client_socket) = @_;

    # print("HANDLING GAME INDEX\n");

    foreach my $game (keys %game_types) {
        if ($message->{"game"} eq $game) {
            return $game_types{$game}->($message, $client_socket);
        }
    }
}

sub get_spectate_games {
    my ($game) = @_;

    my @spectate_games;
    foreach my $game_id (keys %memory::spectate_games) {
        push(@spectate_games, $game_id);
        # print("SPECTATE GAMES: $game_id\n");
    }


    return @spectate_games;
}

1;