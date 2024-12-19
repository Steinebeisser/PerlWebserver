package get_profile_pages;

use strict;
use warnings;

sub get_profile {
    my ($client_socket, $request) = @_;
    my $html = profile_html::get_profile();
    if (!$html) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_401("You are not logged in<br><a href=\"/ \">Return to index</a><br><a href=\"/login\">Login</a>"));
    }
    return $html;
}

sub get_profile_ploud {
    my ($client_socket, $request) = @_;
    my $username;

    if (!$main::user) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_401("You are not logged in<br><a href=\"/ \">Return to index</a><br><a href=\"/login\">Login</a>"));
    }
    my $html = get_profile_ploud::get_profile_ploud($main::user->{username});
    return $html;
}

sub get_profile_ploud_upload {
    my ($client_socket, $request) = @_;

    if (!$main::user) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_401("You are not logged in<br><a href=\"/ \">Return to index</a><br><a href=\"/login\">Login</a>"));
    }
    my $html = get_profile_ploud_upload::get_profile_ploud_upload($main::user->{username});
    return $html;
}

sub get_profile_ploud_upgrade {
    my ($client_socket, $request) = @_;
    my $rank;
    if (!$main::user) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_401("You are not logged in<br><a href=\"/ \">Return to index</a><br><a href=\"/login\">Login</a>"));
    }

    if ($request =~ /profile\/ploud\/upgrade\/(.*) HTTP\/1.1/) {
        $rank = $1;
    }
    if (!$rank) {
        my $html = get_profile_ploud_upgrade::get_profile_ploud_upgrade();
        return $html;
    } 

    my $html = get_profile_ploud_upgrade_rank::get_profile_ploud_upgrade_rank($rank, $main::user->{username});

    return $html;
}

1;