package get_shutdown_page;

use strict;
use warnings;

sub get_shutdown {
    $byebye::is_shutdown = 1;
    return shutdown_html::get_shutdown();
}

1;