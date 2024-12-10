package game_utils;

use strict;
use warnings;

my %game_types = (
    "memory" => \&memory_game_utils::handle_memory,
);


sub handle_game_index {
    my ($message, $client_socket) = @_;

    print("HANDLING GAME INDEX\n");

    foreach my $game (keys %game_types) {
        if ($message->{"game"} eq $game) {
            return $game_types{$game}->($message, $client_socket);
        }
    }
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