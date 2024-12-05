package scheme_utils;

use strict;
use warnings;

sub set_scheme {
    if ($main::user) {
        my $username = $main::user->{username};
        my $preferences = user_utils::get_user_stat($username, "preferences");
        if ($preferences) {
            my $scheme = $preferences->{scheme};
            if ($scheme) {
                $main::scheme = $scheme;
            }
        }
    } elsif ($main::cookie_dark_mode) {
        $main::scheme = $main::cookie_dark_mode;
    }
}

1;