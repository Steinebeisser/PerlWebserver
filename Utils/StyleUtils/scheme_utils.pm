package scheme_utils;

use strict;
use warnings;

sub set_scheme {
    if ($main::user) {
        my $uuid = $main::user->{uuid};
        # print("SCHEME1: $scheme\n");
        my $preferences = user_utils::get_user_stat($uuid, "preferences");
        if ($preferences) {
            # print("SCHEME1: $scheme\n");
            my $scheme = $preferences->{scheme};
            print("SCHEME1: $scheme\n");
            if ($scheme) {
                $main::scheme = $scheme;
            }
        } else {
            $main::scheme = request_utils::get_scheme_by_cookie($main::request);
        }
    } else {
        $main::scheme = request_utils::get_scheme_by_cookie($main::request);
    }

    if (!$main::scheme) {
        $main::scheme = "light";
    }
}

1;