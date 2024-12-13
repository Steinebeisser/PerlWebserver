package get_admin_update_log_manage;

use strict;
use warnings;

use Cwd;
use JSON;

sub get_admin_update_log_manage {
    my ($client_socket, $request) = @_;
    if (!admin_utils::check_if_admin_and_logged_in($client_socket)) {
        return;
    } 

    my $html = get_update_log_manage::get_update_log_manage();
    return $html;
}

sub get_admin_update_log_add {
    my ($client_socket, $request) = @_;
    if (!admin_utils::check_if_admin_and_logged_in($client_socket)) {
        return;
    } 
    my $html = get_admin_update_log_add::get_admin_update_log_add();
    return $html;
}


1;