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

sub post_admin_update_log_edit {
    my ($client_socket, $request) = @_;

    if (!admin_utils::check_if_admin_and_logged_in($client_socket)) {
        return;
    }

    print($request);
    my ($update_log_id, $update_point_id, $content) = update_log::parse_edit_request($request);

    print($update_point_id);
    print("update_log_id: $update_log_id\n");
    if (!defined($update_point_id)) {
        $update_point_id = undef;
    }
    print("update_point_id: $update_point_id\n");
    print("content: $content\n");

    if (!$update_log_id || !$content) {
        my $response = HTTP_RESPONSE::ERROR_400("Bad Request");
        http_utils::send_http_response($client_socket, $response);
        return;
    }

    if (!update_log::edit_update_log($update_log_id, $update_point_id, $content)) {
        return 0;
    }
}

sub post_admin_update_log_delete {
    my ($client_socket, $request) = @_;

    if (!admin_utils::check_if_admin_and_logged_in($client_socket)) {
        return;
    }

    my $update_log_id = update_log::parse_delete_request($request);

    if (!$update_log_id) {
        return 0;
    }

    if (!update_log::delete_update_log($update_log_id)) {
        return 0;
    }

}

1;