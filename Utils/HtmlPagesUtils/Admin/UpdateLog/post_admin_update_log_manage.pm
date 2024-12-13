package post_admin_update_log_manage;

use strict;
use warnings;

sub post_admin_update_log_add {
    my ($client_socket, $request) = @_;

    if (!admin_utils::check_if_admin_and_logged_in($client_socket)) {
        return;
    }

    update_log::add_update_log($request);

    my $referer = request_utils::get_referer($request);
    if (!$referer) {
        $referer = "/admin/update_log";
    }
    my $response = HTTP_RESPONSE::REDIRECT_303($referer);
    http_utils::send_http_response($client_socket, $response);
}

1;