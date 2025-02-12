package get_admin_game_launcher;

use strict;
use warnings;

use Cwd;
use JSON;

sub get_admin_game_launcher {
    my ($client_socket) = @_;

    if ($main::user) {
        my $role = user_utils::get_role();
        if ($role ne "admin") {
            return 0;
        }
    } else {
        return 0;
    }

    my $html_content = get_admin_game_launcher_html::get_admin_game_launcher;
    if ($html_content) {
        return $html_content;
    }
}

sub get_admin_game_launcher_add {
    my ($client_socket) = @_;

    if ($main::user) {
        my $role = user_utils::get_role();
        if ($role ne "admin") {
            return 0;
        }
    } else {
        return 0;
    }

    my $html_content = get_admin_game_launcher_add::get_admin_game_launcher_add;
    if ($html_content) {
        return $html_content;
    }
}

1;