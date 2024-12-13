package get_update_log_page;

use strict;
use warnings;

sub get_update_log {
    my $html = update_log_html::update_log_html();
    return $html;
}



1;