package get_index_page;

use strict;
use warnings;

sub get_index {
    my ($client_socket, $request) = @_;
    # print("HI\n");
    if (admin_utils::check_if_admin($client_socket)) {
        return index_html::new(1);
    } 
    # print("HI\n");
    return index_html::new(0);
}

1;