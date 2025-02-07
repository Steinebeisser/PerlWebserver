package get_users;

use strict;
use warnings;

use JSON;

sub get_users {
    my ($client_socket, $route) = @_;

    my ($fragmentet_user_part) = $route =~ /\/users\/(.*)/;

    my @users = user_utils::get_users($fragmentet_user_part);
    print("ENCODED USERS: " . encode_json(\@users) . "\n");
    return encode_json(\@users);
}

1;