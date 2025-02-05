package post_blog_pages;

use strict;
use warnings;

use Cwd;
use JSON;

sub post_announcement_create {
    my ($client_socket, $request, $temp_file) = @_;

    my $user = $main::user;
    if (!$user) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_401("You are not logged in<br><a href=\"/ \">Return to index</a><br><a href=\"/login\">Login</a>"));
    }
    if ($user->{role} ne "admin") {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_401("You are not an admin<br><a href=\"/ \">Return to index</a><br><a href=\"/login\">Login</a>"));
    }

    my $is_announcement = 1;
    post_blog_create($client_socket, $request, $temp_file, $is_announcement);
}

sub post_blog_create {
    my ($client_socket, $route, $temp_file, $is_announcement) = @_;
    # print("BLOG CREATE\n");
    # print("IS ANNOUNCEMENT: $is_announcement\n");

    my $blog_name;
    my $blog_content;

    my $author = $main::user->{username};
    
    if (!$author) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_401("You are not logged in<br><a href=\"/ \">Return to index</a><br><a href=\"/login\">Login</a>"));
        return;
    }

    if ($main::user->{username} ne $author) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_401("You are not allowed to post this<br><a href=\"/ \">Return to index</a>"));
        return;
    }

    if ($is_announcement) {
        if ($main::user->{role} ne "admin") {
            http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_401("You are not allowed to post announcements<br><a href=\"/ \">Return to index</a>"));
            return;
        }
    }


    my $request = body_utils::load_temp_file($temp_file);
    if ($request =~ /title=(.*)&content=(.*)/) {
        $blog_name = $1;
        $blog_content = $2;
    }

    $blog_content =~ s/\+/ /g;
    $blog_name =~ s/\+/ /g;

    if (!$blog_name || !$blog_content) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_400("Title or content missing"));
        return;
    }


    my $title = user_utils::encode_uri($blog_name);
    my $base_dir = getcwd();

    $blog_content = user_utils::decode_uri($blog_content);

    # print("CONTENT: $blog_content\n");
    if ($blog_content =~ /</) {
        # print("ENCODE CHARACTERS\n");
        $blog_content =http_utils::encode_characters($blog_content);
    }

    my $blog_path;
    my $date_upload_sort = "$base_dir/Data/Blog/upload_date.txt";

    if ($is_announcement) {
        $blog_path = "$base_dir/Data/Blog/Announcements";
    } else {
        $blog_path = "$base_dir/Data/Blog/Posts";
    }
    
    if (-f $blog_path."/$title.json") {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_409("Blog already exists"));
        return;
    }

    my $blog_data = {};

    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime();
    my $formatted_time = sprintf("%02d.%02d.%04d %02d:%02d:%02d", $mday, $mon + 1, $year + 1900, $hour, $min, $sec);


    $blog_data->{active} = "true";
    $blog_data->{author} = $author;
    $blog_data->{title} = $blog_name;
    $blog_data->{content} = $blog_content;
    $blog_data->{date} = $formatted_time;
    $blog_data->{lastEdited} = "";
    $blog_data->{views} = 0;
    $blog_data->{lastEditedBy} = "";

    my $json = encode_json($blog_data);
    my $file_path = "Data/Blog/Posts/";

    if (length($title) > 50) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_400("Title too long"));
    }

    open(my $file, ">", $blog_path . "/$title.json") || do 
        {
            warn "Could not create blog file: $!";
            http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_500("Internal Server Error"));
            return;
        };
    print $file $json;
    close $file;

    if (!$is_announcement) {
        open my $fh, '<', "$date_upload_sort" or do warn "Cannot open file: $!";
        my $data;
        {
            local $/;
            $data = <$fh>;
        }
        close $fh;

        open $fh, '>', "$date_upload_sort" or die "Cannot open file: $!";
        print $fh "$file_path/$title.json\n";
        print $fh $data;
        close $fh;
    }

    

    my $referer = request_utils::get_referer($main::header);
    # if (!$referer) {
    if ($is_announcement) {
        $referer = "/blog/announcements/manage";
    } else {
        $referer = "/blog";
    }
    # }

    my $response = HTTP_RESPONSE::REDIRECT_303($referer);
    http_utils::send_http_response($client_socket, $response);
}

1;