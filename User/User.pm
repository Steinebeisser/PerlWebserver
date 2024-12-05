package User;

use strict;
use warnings;

sub new {
    my ($self, $user_stats) = @_;

    my $username = $user_stats->{username};
    my $password = $user_stats->{password};
    my $role = $user_stats->{role}; 
    if (!$username || !$password) {
        return 0;
    }
    if (!$role) {
        $role = "user";
    }
    my $User = {
        username => $user_stats->{username},
        password => $user_stats->{password},
        role => $user_stats->{role},
        banned => $user_stats->{banned},
    };

    return $User;
}

1;