package admin_utils;

use strict;
use warnings;

sub return_buttons {
    my $return_buttons = <<HTML;
    <span class="admin_return">
        <a href="/admin/users">Return to users</a>
        <a href="/admin">Return to admin</a>
        <a href="/">Return to index</a>
    </span>
HTML
    
    return $return_buttons;
}

1;