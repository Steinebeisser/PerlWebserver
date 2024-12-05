package blog_utils;

use strict;
use warnings;
use Cwd;
use JSON;

my $timeoutTime = 60*60;

sub get_official_announcements {
    my ($get_all) = @_;

    my $base_path = getcwd();
    my $announcement_path = "$base_path/Data/Blog/Announcements";
    unless (-d $announcement_path) {
        die "Directory $announcement_path does not exist";
    }
    my @announcements = glob("$announcement_path/*.json");
    if (!@announcements) {
        # print("No announcement files found in $announcement_path\n");
    } else {
        # print("ANNOUNCEMENTS: @announcements\n");
    }
    my @active_announcements;
    foreach my $announcement (@announcements) {
        $announcement = user_utils::read_file($announcement);
        $announcement = decode_json($announcement);
        if (!$get_all) {
            if ($announcement->{active} eq "true") {
                push(@active_announcements, $announcement);
            }
        } else {
            push(@active_announcements, $announcement);
        }
    }

    return @active_announcements;
}

sub get_blog_posts {
    my ($page, $sorting) = @_;

    # print("SORTING: $sorting\n");
    $sorting = "views" if !$sorting;

    my $base_path = getcwd();
    my $blog_path = "$base_path/Data/Blog/Posts";
    my @paged_posts;
    unless (-d $blog_path) {
        mkdir($blog_path);
        warn "Directory $blog_path does not exist";
    }
    my @posts;
    my $count = 0;
    my $from_count = ($page-1)*15;
    my $to_count = $page*15;

    if ($sorting eq "newest") {
        my $upload_date_file = "$base_path/Data/Blog/upload_date.txt";
        open my $fh, "<", $upload_date_file or do  {
            warn "Could not open file $upload_date_file: $!"
        };
        while (my $line = <$fh>) {
            if ($count >= $from_count && $count <= $to_count) {
                # print("LINE: $line\n");
                my $file_path = ("$base_path/$line");
                push(@posts, $file_path);
            }
            $count++;
            if ($count > $to_count) {
                last;
            }
            # print("POSTS: @posts\n");
            # print("COUNT: $count\n");
        }
        close $fh;
    } elsif ($sorting eq "oldest") {
        my $upload_date_file = "$base_path/Data/Blog/upload_date.txt";
        open my $fh, "<", $upload_date_file or do  {
            warn "Could not open file $upload_date_file: $!"
        };
        my @lines = <$fh>;
        close $fh;
        @lines = reverse @lines;
        foreach my $line (@lines) {
            # print("LINE234: $line\n");
            if ($count >= $from_count && $count <= $to_count) {
                # print("LINE123: $line\n");
                my $file_path = ("$base_path/$line");
                push(@posts, $file_path);
            }
            $count++;
            if ($count > $to_count) {
                last;
            }
        }
    } elsif ($sorting eq "views") {
        my $views_file = "$base_path/Data/Blog/views.txt";
        open my $fh, "<", $views_file or do  {
            warn "Could not open file $views_file: $!"
        };
        while (my $line = <$fh>) {
            if ($count >= $from_count && $count <= $to_count) {
                my $post_path = (split ' ', $line)[0];
                # print("LINE: $line\n");
                push(@posts, $post_path);
            }
            $count++;
            if ($count > $to_count) {
                last;
            }
        }
        close $fh;
    } else {
        opendir(my $dir, $blog_path) or die "Could not open directory $blog_path: $!";

        foreach my $file (readdir($dir)) {
            next if ($file eq '.' or $file eq '..');
            if ($file =~ /\.json$/) {
                if ($count >= $from_count && $count <= $to_count) {
                    # print("PUSHED $file\n");
                    push(@posts, $blog_path . "/" . $file);
                }
                $count++;
            }
        }
        closedir($dir);      
    }

    # my @posts = glob("$blog_path/*.json");
    if (!@posts) {
        # print("No post files found in $blog_path\n");
    } else {
        # print("POSTS FOUND\n");
    }

    if (scalar @posts < 15) {
        opendir(my $dir, $blog_path) or die "Could not open directory $blog_path: $!";

        foreach my $file (readdir($dir)) {
            my $skip_file = 0;
            next if ($file eq '.' or $file eq '..');
            foreach my $exist_file (@posts) {
                if ($exist_file eq "$blog_path/$file") {
                    # print "PRINT REMOVED $file\n";
                    $skip_file = 1;
                    last;
                }
            }
            if ($file =~ /\.json$/) {
                if ($skip_file) {
                    next;
                }
                if ($count >= $from_count && $count <= $to_count) {
                    # print("PUSHED $file\n");
                    push(@posts, $blog_path . "/" . $file);
                }
                $count++;
            }
        }
        closedir($dir); 
    }
    
    my $posts_per_page = 15;
    my $start_index = ($page - 1) * $posts_per_page;
    my $end_index = $start_index + $posts_per_page - 1;
    $count = 0;

    foreach my $post (@posts) {
        # print("POST: $post\n");
        $post = user_utils::read_file($post);
        if (!$post) {
            # print("EMPTY POST\n");
            next;
        }
        $post = decode_json($post);
        if ($post->{active} eq "true") {
            push(@paged_posts, $post);
        }
    }
    # print("PAGED POSTS: @paged_posts\n");

    return @paged_posts;
}

sub get_blog_data {
    my ($blog_name, $is_announcement) = @_;
    my $base_path = getcwd();
    my $blog_path;
    print("IS ANNOUNCEMENT: $is_announcement\n");
    print("BLOG NAME: $blog_name\n");
    if ($is_announcement) {
        $blog_path = "$base_path/Data/Blog/Announcements/$blog_name.json";
    } else {
        $blog_path = "$base_path/Data/Blog/Posts/$blog_name.json";
    }

    if (!-f $blog_path) {
        warn "File $blog_path does not exist";
        return 0;
    }

    my $blog_data = user_utils::read_file("$blog_path");
    $blog_data = decode_json($blog_data);
    return $blog_data;
}

sub update_blog_data {
    my ($blog_name, $new_data, $is_announcement) = @_;

    my $base_path = getcwd();
    my $blog_path;
    if ($is_announcement) {
        $blog_path = "$base_path/Data/Blog/Announcements/$blog_name.json";
    } else {
        $blog_path = "$base_path/Data/Blog/Posts/$blog_name.json";
    }

    if (!-f $blog_path) {
        warn "File $blog_path does not exist";
        return 0;
    }

    $new_data = encode_json($new_data);
    user_utils::write_file($blog_path, $new_data);
}
sub add_view {
    my ($blog_name, $is_announcement) = @_;
    # print("ADDING VIEW TO $blog_name\n");
    my $is_timeout = 0;
    if (is_user_in_timeout($blog_name)) {
        # print("USER IN TIMEOUT\n");
        $is_timeout = 1;
        return 0;
    }
    my $blog_data = blog_utils::get_blog_data($blog_name, $is_announcement);
    $blog_data->{views}++;
    # print("VIEWS: $blog_data->{views}\n");
    my $base_path = getcwd();

    my $blog_path;
    if ($is_announcement) {
        $blog_path = "$base_path/Data/Blog/Announcements/$blog_name.json";
    } else {
        $blog_path = "$base_path/Data/Blog/Posts/$blog_name.json";
    }
    if (!-f $blog_path) {
        warn "File $blog_path does not exist";
        return 0;
    }

    $blog_data = encode_json($blog_data);
    user_utils::write_file($blog_path, $blog_data);
    if (!$is_timeout) {
        add_user_to_timeouts($blog_name);
    }

    if ($is_announcement) {
        return 1;
    }
    my $views_file = "$base_path/Data/Blog/views.txt";
    my $post_path = "$base_path/Data/Blog/Posts/$blog_name.json";
    open my $fh, "<", $views_file or do warn "Could not open file $views_file: $!";
    my @lines = <$fh>;
    close $fh;

    $blog_data = decode_json($blog_data);
    my $new_line = "$post_path $blog_data->{views}\n";
    my @new_lines;
    my $inserted = 0;

    foreach my $line (@lines) {
        my ($name, $views) = split ' ', $line;
        if (!$inserted && $blog_data->{views} > $views) {
            push @new_lines, $new_line;
            $inserted = 1;
        }
        push @new_lines, $line unless $name eq $blog_name;
    }

    push @new_lines, $new_line unless $inserted;

    open $fh, ">", $views_file or die "Could not open file $views_file: $!";
    print $fh @new_lines;
    close $fh;
    # print("ADDED VIEW TO $blog_path\n");
}

sub add_user_to_timeouts {
    my ($blog_name) = @_;
    my $blog_data = blog_utils::get_blog_data($blog_name);
    my $base_path = getcwd();
    my $timeout_path_dir = "$base_path/Data/Blog/Timeouts";
    my $timeout_path = "$timeout_path_dir/$blog_name.json";
    unless (-d $timeout_path_dir) {
        mkdir($timeout_path_dir);
    }
    if (!-f $timeout_path) {
        open my $fh, ">", $timeout_path or die "Could not open file $timeout_path: $!";
        close $fh;
    }

    my $timeout_data = user_utils::read_file($timeout_path);
    if (!$timeout_data) {
        $timeout_data = {};
    } else {
        $timeout_data = decode_json($timeout_data);
    }
    my $user = $main::user->{username};
    if (!$timeout_data->{$user}) {
        $timeout_data->{$user} = time();
    }

    $timeout_data->{$user} = time();
    $timeout_data = encode_json($timeout_data);
    user_utils::write_file($timeout_path, $timeout_data);
}

sub is_user_in_timeout {
    my ($blog_name) = @_;
    my $blog_data = blog_utils::get_blog_data($blog_name);
    my $base_path = getcwd();
    my $timeout_path = "$base_path/Data/Blog/Timeouts/$blog_name.json";
    if (!-f $timeout_path) {
        do {
            warn "File $timeout_path does not exist";
            return 0;
        } 
    
    }
    my $timeout_data = user_utils::read_file($timeout_path);
    if (!$timeout_data) {
        return 0;
    }
    # print("TIMEOUT DATA: $timeout_data\n");
    $timeout_data = decode_json($timeout_data);
    my $user = $main::user->{username};
    if ($timeout_data->{$user}) {
        # print("USER IN TIMEOUT123\n");
        my $timeout = $timeout_data->{$user};
        my $current_time = time();
        my $time_passed = $current_time - $timeout;
        # print("TIME PASSED: $time_passed\n");
        if ($time_passed > ($timeoutTime)) {
            return 0;
        } else {
            return 1;
        }
    }
    return 0;
}

sub delete_blog {
    my ($blog_name, $is_announcement) = @_;
    my $base_path = getcwd();
    my $blog_path;
    if ($is_announcement) {
        $blog_path = "$base_path/Data/Blog/Announcements/$blog_name.json";
    } else {
        $blog_path = "$base_path/Data/Blog/Posts/$blog_name.json";
    }
    if (-f $blog_path) {
        if (unlink $blog_path) {
            return 1;
        } else {
            return 0;
        }
    }

    main::serve_error($main::client_socket, HTTP_RESPONSE::ERROR_404("Blog not found"));
    return 0;
}
1;