package get_admin_page;

use strict;
use warnings;

sub get_admin {
    my ($client_socket, $request) = @_;
    my $html = admin_html::get_admin();
    if (!$html) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_401("You are no admin<h1>peasant</h1><br><a href=\"/ \">Return to index</a><br><a href=\"/login\">Login</a>"));
    }
    if (admin_utils::check_if_admin_and_logged_in($client_socket)) {
        return $html;
    } else {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_401("You are no admin<h1>peasant</h1><br><a href=\"/ \">Return to index</a><br><a href=\"/login\">Login</a>"));
    }
    
    return $html;
}

1;