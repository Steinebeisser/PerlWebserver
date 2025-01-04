package get_admin_update_log_manage;

use strict;
use warnings;

use Cwd;
use JSON;

sub get_admin_update_log_manage {
    my ($client_socket) = @_;
    if (!admin_utils::check_if_admin_and_logged_in($client_socket)) {
        return;
    } 

    my $html = get_update_log_manage::get_update_log_manage();
    return $html;
}

sub get_admin_update_log_add {
    my ($client_socket) = @_;
    if (!admin_utils::check_if_admin_and_logged_in($client_socket)) {
        return;
    } 
    my $html = get_admin_update_log_add::get_admin_update_log_add();
    return $html;
}

sub get_admin_update_log_edit {
    my ($client_socket, $route) = @_;
    if (!admin_utils::check_if_admin_and_logged_in($client_socket)) {
        return;
    } 
    my $update_id;
    if ($route =~ /\/admin\/updateLog\/edit\/(\d+)/) {
        $update_id = $1;
    }
    my $update = update_log::get_update_log_by_id($update_id);
    my $html = get_admin_update_log_edit::get_admin_update_log_edit($update);
    return $html;
}

sub get_admin_update_log_delete {
    my ($client_socket, $route) = @_;
    if (!admin_utils::check_if_admin_and_logged_in($client_socket)) {
        return;
    } 
    my $update_id;
    if ($route =~ /\/admin\/updateLog\/delete\/(\d+)/) {
        $update_id = $1;
    }
    my $update = update_log::get_update_log_by_id($update_id);
    my $html = get_admin_update_log_delete::get_admin_update_log_delete($update);
    return $html;
}
1;