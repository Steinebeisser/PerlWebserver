package get_blog_pages;

use strict;
use warnings;

sub get_blog_index {
    my ($client_socket, $route) = @_;

    my $page = 1;
    my $sort_type;
    # print("REQUEST: $request\n");
    if ($route =~ /\/blog\/\?page=(\d+)/) {
        $page = $1;
        # print("PAGE: $page\n");
    }
    if ($route =~ /\/blog\/\?sort=(.*)/) {
        $sort_type = $1;
        # print("SORT1234: $sort_type\n");
    }
    # print("PAGE: $page\n");
    
    my $html = get_blog::get_blog($page, $sort_type);
    return $html;
}

sub get_blog_view {
    my ($client_socket, $route) = @_;

    my $blog_name;
    my $is_announcement = 0;

    if ($route =~ /\/blog\/view\/(.*)/) {
        $blog_name = $1;
    }

    if ($route =~ /\/blog\/view\/announcement\/(.*)/) {
        $blog_name = $1;
        $is_announcement = 1;
    }

    if (!$blog_name) {
        serve_error($client_socket, HTTP_RESPONSE::ERROR_404("Blog not found"));
    }

    my $html = get_blog_view::get_blog_view($blog_name, $client_socket, $is_announcement);
    if ($html) {
        blog_utils::add_view($blog_name, $is_announcement);
    }
    return $html;
}

sub get_blog_create {
    my ($client_socket) = @_;

    my $html = get_blog_create::get_blog_create();

    return $html;
}

sub get_blog_announcements_manage {
    my ($client_socket) = @_;

    my $html = get_blog_announcements_manage::get_blog_announcements_manage();

    return $html;
}

sub get_announcement_edit {
    my ($client_socket, $route) = @_;

    my $user = $main::user;
    if (!$user) {
        serve_error($client_socket, HTTP_RESPONSE::ERROR_401("You are not logged in<br><a href=\"/ \">Return to index</a><br><a href=\"/login\">Login</a>"));
    }
    if ($user->{role} ne "admin") {
        serve_error($client_socket, HTTP_RESPONSE::ERROR_401("You are not an admin<br><a href=\"/ \">Return to index</a><br><a href=\"/login\">Login</a>"));
    }

    if ($route =~ /\/blog\/announcement\/edit\/(.*)/) {
        my $announcement_name = $1;
        my $html = get_announcement_edit::get_announcement_edit($announcement_name);
        return $html;
    }

    serve_error($client_socket, HTTP_RESPONSE::ERROR_404("Announcement not found"));
}

sub announcement_switch_status {
    my ($client_socket, $route) = @_;
    my $activate;
    my $announcement_name;

    my $user = $main::user;
    if (!$user) {
        serve_error($client_socket, HTTP_RESPONSE::ERROR_401("You are not logged in<br><a href=\"/ \">Return to index</a><br><a href=\"/login\">Login</a>"));
    }
    if ($user->{role} ne "admin") {
        serve_error($client_socket, HTTP_RESPONSE::ERROR_401("You are not an admin<br><a href=\"/ \">Return to index</a><br><a href=\"/login\">Login</a>"));
    }

    if ($route =~ /\/blog\/announcement\/(.*)\/(.*)/) {
        $activate = $1;
        $announcement_name = $2;
    }

    if (!$activate || !$announcement_name) {
        serve_error($client_socket, HTTP_RESPONSE::ERROR_404("Announcement not found<br>Pls contact dev"));
    }

    my $is_announcement = 1;
    my $blog_data = blog_utils::get_blog_data($announcement_name, $is_announcement);

    if (!$blog_data) {
        serve_error($client_socket, HTTP_RESPONSE::ERROR_404("Announcement not found<br>Pls contact dev"));
        return;
    }

    if ($activate eq "activate") {
        $blog_data->{active} = "true";
    } else {
        $blog_data->{active} = "false";
    }

    if (blog_utils::update_blog_data($announcement_name, $blog_data, $is_announcement)) {
        my $referer = request_utils::get_referer($main::header);
        if (!$referer) {
            $referer = "/blog/announcements/manage";
        }

        my $response = HTTP_RESPONSE::REDIRECT_303($referer);
        http_utils::send_http_response($client_socket, $response);
    } else {
        serve_error($client_socket, HTTP_RESPONSE::ERROR_500());
    }

}

sub get_announcement_create {
    my ($client_socket) = @_;
    # print("HIHIHAHAHA\n");

    my $html = get_announcement_create::get_announcement_create();

    return $html;
}



sub get_announcement_delete {
    my ($client_socket, $route) = @_;

    my $user = $main::user;
    if (!$user) {
        serve_error($client_socket, HTTP_RESPONSE::ERROR_401("You are not logged in<br><a href=\"/ \">Return to index</a><br><a href=\"/login\">Login</a>"));
    }
    if ($user->{role} ne "admin") {
        serve_error($client_socket, HTTP_RESPONSE::ERROR_401("You are not an admin<br><a href=\"/ \">Return to index</a><br><a href=\"/login\">Login</a>"));
    }

    if ($route =~ /\/blog\/announcement\/delete\/(.*)/) {
        my $announcement_name = $1;
        if (!blog_utils::delete_blog($announcement_name, 1)) {
            serve_error($client_socket, HTTP_RESPONSE::ERROR_500("Error deleting announcement"));
        }
        my $referer = request_utils::get_referer($main::header);
        if (!$referer) {
            $referer = "/blog/announcements/manage";
        }
        my $html = HTTP_RESPONSE::REDIRECT_303($referer);
        http_utils::send_http_response($client_socket, $html);
        return;
    }

    serve_error($client_socket, HTTP_RESPONSE::ERROR_404("Announcement not found"));
}

1;