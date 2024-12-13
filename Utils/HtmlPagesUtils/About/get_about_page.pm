package get_about_page;

use strict;
use warnings;

sub get_about {
    my $html = about_html::get_about();
    return $html;
}
1;