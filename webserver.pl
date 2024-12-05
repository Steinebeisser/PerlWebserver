use strict;
use warnings;

use Socket;
use JSON;
use Cwd;
use URI::Escape qw(uri_unescape);
use IO::Epoll;


use lib '.';
use HTTP_RESPONSE;
use html_pages;


my $cookie_language;
$main::max_storage = 1*1024*1024*1024; # 1GB
my $cookie_dark_mode;
my $accept_language;
$cookie::empty_cookie = "username=; expires=Thu, 01 Jan 1970 00:00:00 GMT";
my $is_post;
my $user;
$main::isLoggedIn;
my $is_shutdown = 0;
my $port = 80;
# my %memory::spectate_games;


my %index_router = (
    "/ " => \&get_index_page::get_index,

    "/favicon.ico" => \&get_favicon::get_favicon,
    
    "/login" => \&get_login_page::get_login,
    "/register" => \&get_register_page::get_register,
    "/logout" => \&logout_user::get_logout,
    
    "/profile" => \&get_profile_pages::get_profile,
    "/profile/ploud" => \&get_profile_pages::get_profile_ploud,
    "/profile/ploud/upload" => \&get_profile_pages::get_profile_ploud_upload,
    # "/profile/ploud/download" => \&post_profile_ploud_download,
    # "/profile/ploud/delete" => \&post_profile_ploud_delete,
    "/profile/ploud/upgrade" => \&get_profile_pages::get_profile_ploud_upgrade,
    
    "/blog" => \&get_blog_pages::get_blog_index,
    "/blog/view" => \&get_blog_pages::get_blog_view,
    "/blog/create" => \&get_blog_pages::get_blog_create,
    "/blog/announcement/edit" => \&get_blog_pages::get_announcement_edit,
    "/blog/announcement/deactivate" => \&get_blog_pages::announcement_switch_status,
    "/blog/announcement/activate" => \&get_blog_pages::announcement_switch_status,
    "/blog/announcement/create" => \&get_blog_pages::get_announcement_create,
    "/blog/announcement/delete" => \&get_blog_pages::get_announcement_delete,
    "/blog/announcements/manage" => \&get_blog_pages::get_blog_announcements_manage,

    "/gameroom" => \&get_gameroom_page::get_gameroom,
    "/gameroom/memory" => \&get_memory_pages::get_memory,
    "/gameroom/memory/src" => \&get_memory_pages::get_memory_src,
    "/gameroom/memory/src/card" => \&get_memory_pages::get_memory_src_card,
    "/gameroom/memory/alone" => \&get_memory_pages::get_memory_alone,
    "/gameroom/memory/2player" => \&get_memory_pages::get_memory_2player,
    "/gameroom/memory/2player/waiting" => \&get_memory_pages::get_memory_2player_waiting,
    "/gameroom/memory/restart" => \&get_memory_pages::get_memory_restart,

    "/fonts" => \&load_fonts::get_fonts,
    "/ExternalJS" => \&load_js::get_external_js,

    "/calender" => "WEWINDWOSSSSSSSSSSS",
    
    "/admin" => \&get_admin_page::get_admin,
    "/admin/users" => \&get_admin_users_pages::get_admin_users,
    "/admin/users/edit" => \&get_admin_users_pages::get_admin_edit_user,
    "/admin/users/view" => \&get_admin_users_pages::get_admin_view_user,
    "/admin/users/ban" => \&get_admin_users_pages::get_admin_ban_user,
    "/admin/users/delete" => \&get_admin_users_pages::get_admin_delete_user,


    
    "/shutdown" => \&get_shutdown_page::get_shutdown,
);

my %post_router = (
    "/login" => \&login_user::post_login,
    "/register" => \&register_user::post_register,
    # "/logout" => \&logout_user::post_logout,

    "/profile/ploud/upload" => \&post_profile_pages::post_profile_ploud_upload,
    "/profile/ploud/delete" => \&post_profile_pages::post_profile_ploud_delete,
    "/profile/ploud/download" => \&post_profile_pages::post_profile_ploud_download,
    "/profile/ploud/upgrade" => \&post_profile_pages::post_profile_ploud_upgrade,

    "/blog/create" => \&post_blog_pages::post_blog_create,
    "/blog/announcement/create" => \&post_blog_pages::post_announcement_create,

    # "/shutdown" => \&get_shutdown,

    "/change_language" => \&post_preferences::post_change_language,
    "/dark_mode" => \&post_preferences::post_dark_mode,
    
    "/admin/users" => \&post_admin_user_pages::post_admin_users,
    "/admin/users/edit" => \&post_admin_user_pages::post_admin_edit_user,
    "/admin/users/ban" => \&post_admin_user_pages::post_admin_ban_user,
    "/admin/users/delete" => \&post_admin_user_pages::post_admin_delete_user,
);

print("Creating main::Epoll\n");
$main::epoll = epoll_create(10) || die "Can't create main::epoll: $!";

print("Creating socket\n");
socket(
    my $server, 
    AF_INET, 
    SOCK_STREAM, 
    0) || die "Can't create socket: $!";


print("Setting socket options\n");
setsockopt($server, SOL_SOCKET, SO_REUSEADDR, 1) || die "Can't set socket options: $!";
print("Binding to port $port\n");
bind($server, sockaddr_in($port, INADDR_ANY)) || die "Can't bind: $!";


print("Listening on port $port\n");
listen($server, 5) || die "Can't listen: $!";

print("Accepting connections\n");

epoll_ctl($main::epoll, EPOLL_CTL_ADD, fileno $server, EPOLLIN) >= 0 || die "Can't add server socket to main::epoll: $!";

epoll_loop();

# my %epoll::clients;
my %user_in_queue;

sub epoll_loop {
    while (1) {
        my $events = epoll_wait($main::epoll, 10, -1);
        # print("Waiting for events\n");

        for my $event (@$events) {
            if ($event->[0] == fileno $server) {
                accept(my $client_socket, $server);
                print("ACCEPTED NEW CONNECTION\n");
                # print("CLIENT SOCKET:" .$client_socket . "\n");
                # print("CLIEND FD: " . fileno($client_socket) . "\n");
                $epoll::clients{fileno($client_socket)} = {};
                $epoll::clients{fileno($client_socket)}{"socket"} = $client_socket;
                epoll_ctl($main::epoll, EPOLL_CTL_ADD, fileno $client_socket, EPOLLIN) >= 0 || die "Can't add client socket to main::epoll: $!";

            } else {
                # print("Handling client\n");
                handle_client($event->[0]);
            }
        }
    }
}

close($server);


sub handle_client {
    my ($client_fd) = @_;
    my $client_socket = $epoll::clients{$client_fd}{"socket"};
    # print("CLIENT SOCKET: $client_socket\n");

    if (!$epoll::clients{$client_fd}{"content_length"}) {
        connection_utils::get_client_data($client_fd, $client_socket);
    }
    # print("BYTES READ: $buffer\n");

    if (!$epoll::clients{$client_fd}{"header"}) {
        websocket_utils::handle_websocket_communication($client_fd);
        return;
    }

    if ($epoll::clients{$client_fd}{"header"} =~ /Sec-WebSocket-Version: (.*)\r\n/) {
        websocket_utils::handle_websocket_request($client_socket, $epoll::clients{$client_fd}{"header"});
        return;
    } else {
        connection_utils::handle_client_data($client_fd, $client_socket);
    }

    # if (!$buffer) {
    #     epoll_ctl($main::epoll, EPOLL_CTL_DEL, $client_fd, 0) >= 0 || die "Can't remove client socket from main::epoll: $!";
    #     close($client_socket);
    #     delete $epoll::clients{$client_fd};
    #     return;
    # }
}

sub handle_normal_request {
    my ($client_fd, $request) = @_;
    $main::isLoggedIn = 0;
    $is_post = 0;
    $accept_language = 0;
    $main::user = undef;
    $main::scheme = "light";
    $cookie_language = undef;
    $cookie_dark_mode = undef;

    my $client_socket = $epoll::clients{$client_fd}{"socket"};

    $main::header = $epoll::clients{$client_fd}{"header"};
    
    print("1");
    my ($new_request, $method) = handle_method($client_socket, $request);
    print("2");

    my $cookie = request_utils::get_cookie($main::header);
    print("3");
    
    language_utils::set_language($new_request);
    print("4");

    scheme_utils::set_scheme();
    print("5");

    if ($main::isLoggedIn) {
        user_utils::check_permissions($client_socket);
    }
    print("6");
    

    my $response = handle_index($client_socket, $new_request, $method);
    print("7");

    print("8");
    http_utils::send_response($client_socket, HTTP_RESPONSE::OK($response));
    close($client_socket);


    if ($is_shutdown) {
        close($server);
    }
}


sub handle_method {
    my ($client_socket, $request) = @_;
    my $method;
    if (!$request) {
        return;
    }

    if ($request =~ /^GET /) {
        print "Received a GET request\n";
        $method = "GET";
        substr($request, 0, 4) = "";
    } elsif ($request =~ /POST /) {
        $is_post = 1;
        print "Received a POST request\n";
        $method = "POST";
        substr($request, 0, 5) = "";
    } else {
        print "Received an unknown request\n";
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_405);
    }

    return ($request, $method);
}


sub handle_index {
    my ($client_socket, $request, $method) = @_;
    my $response;

    if ($method eq "GET") {
        $response = handle_get_index($client_socket, $request);
    } elsif ($method eq "POST") {
        $response = handle_post_index($client_socket, $request, $method);
    }

    if (!defined($response)) {
        print "Received an unknown request\n";
        # print("REQUEST: $request\n");
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_404);
    }

    return $response;
}

sub handle_get_index {
    my ($client_socket, $request) = @_;
    my $response;

    my @sorted_routes = sort { length($b) <=> length($a) } keys %index_router;

    if ($request =~ /Sec-WebSocket-Version: (.*)/) {
        handle_websocket_request($client_socket, $request);
        return;
    }

    foreach my $route (@sorted_routes) {
        # print "Checking route $route\n";
        if ($request =~ /^$route/) {
            print "Received a get request for $route\n";
            if ($route eq "/calender") {
                $response = calender_utils::handle_calender($client_socket, $request, $route);
            } else {
                $response = $index_router{$route}->($client_socket, $request, $route);
            }
            last;
        }
    }
    # print("RESPONSE: $response\n");
    return $response;
}



sub handle_post_index {
    my ($client_socket, $request) = @_;
    my $response;

    my @sorted_routes = sort { length($b) <=> length($a) } keys %post_router;

    foreach my $post_rout (@sorted_routes) {
        if ($request =~ /^$post_rout/) {
            # print "Received a post request for $post_rout\n";
            $response = $post_router{$post_rout}->($client_socket, $request);
            # $response = HTTP_RESPONSE::OK("POST request received");
            last;
        }
    }

    return $response;
}