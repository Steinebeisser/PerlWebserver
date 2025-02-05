package post_profile_pages;

use strict;
use warnings;

use Cwd;
use JSON;
use IO::Epoll;

sub post_profile_ploud_upload {
    my ($client_socket, $route, $temp_file) = @_;

    my $referer = request_utils::get_referer($main::header);
    if (!$referer) {
        $referer = "/";
    }
    # reload_page($client_socket, $referer);
    # print("SENDING REDIRECT\n");
    my $response = HTTP_RESPONSE::REDIRECT_303($referer);
    # print("I GOT REDIRECT\n");
    http_utils::send_http_response($client_socket, $response);
    # my $meta_data = get_meta_data($request, $client_socket);
}

sub get_meta_data {
    my ($request, $client_socket) = @_;

    if ($request =~ /Content-Type: multipart\/form-data; boundary=(.*)\r\n/) {
        my $boundary = $1;
        my $meta_data = {};
        # print("BOUNDARY123 START: $boundary\nBOUNDARY END\n");
        my @parts = split(/--\Q$boundary\E/, $request);

        foreach my $part (@parts) {
            $part =~ s/^\s+|\s+$//g; 
            next if $part =~ /^\s*$/;

            if ($part =~ /Content-Disposition: form-data; name="(.*?)"; filename="(.*?)"/) {
                my $name = $1;
                my $filename = $2;

                my ($headers, $data) = split(/\r\n\r\n/, $part, 2);
                $data =~ s/\r\n$//; 
                $data =~ s/--\r\n//;  
                my $end_boundary = "--$boundary--";
                # print("DATA123: $data\n");
                # print("END BOUNDARY: $end_boundary\n");
                $data =~ $end_boundary;
                # print("DATA123: $data\n");
                
                $filename =~ s/[^\w\.-]+/_/g;
                if ($filename eq '') {
                    $filename = 'untitled';
                }

                my $base_dir = getcwd;
                my $user_path = "$base_dir/Data/UserData/Users/$main::user->{uuid}";
                # print("USER PATH: $user_path\n");
                if (!-d $user_path) {
                    # print("WADAFUCK\n");
                    mkdir $user_path or die "Cannot create directory: $!";
                }
                my $ploud_path = "$user_path/ploud";
                # print("PLOUD PATH: $ploud_path\n");
                if (!-d $ploud_path) {
                    mkdir $ploud_path or die "Cannot create directory: $!";
                }
                my $dir_path = "$ploud_path/$filename";
                if (!-d $dir_path) {
                    mkdir $dir_path or die "Cannot create directory: $!";
                }
                my $filepath = "$dir_path/$filename";
                # print("FILEPATH: $filepath\n");

                if (-e $filepath) {
                    # print "File already exists: $filepath\n";
                    http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_409("File already exists"));
                }

                open my $fh, '>', $filepath or die "Cannot open file: $!";
                binmode $fh; 
                print $fh $data;
                close $fh;

                create_meta_data($name, $filename, $filepath, $dir_path);

                # print "File saved as $filepath\n";
            }
        }
    }
}

sub create_meta_data {
    my ($name, $filename, $filepath, $dir_path) = @_;
    my %meta_data = (
        filename => $filename,
        filepath => $filepath,
        uploaded_at => time(),
        size => -s $filepath
    );

    user_utils::update_user_metadata($main::user->{uuid}, \%meta_data);

    open my $fh, '>', "$dir_path/metadata.json" or die "Cannot open file: $!";
    binmode $fh; 
    print $fh encode_json(\%meta_data);
    close $fh;
}

sub post_profile_ploud_download {
    my ($client_socket, $route, $temp_file) = @_;
    my $filename;

    my $uuid = $main::user->{uuid};

    if ($route =~ /profile\/ploud\/download\/(.*)/) {
        $filename = $1;
    }
    if (!$filename) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_404());
    }

    my $base_dir = getcwd;
    my $filepath = "$base_dir/Data/UserData/Users/$uuid/ploud/$filename/$filename";
    # print("FILEPATH: $filepath\n");
    if (!-e $filepath) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_404("File not found"));
        return;
    }

    if (!$main::user) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_401("You are not logged in<br><a href=\"/ \">Return to index</a><br><a href=\"/login\">Login</a>"));
    }
    
    open my $fh, '<', $filepath or die "Cannot open file: $!";
    binmode $fh;

    my $file_size = -s $filepath;
    my $header = HTTP_RESPONSE::OK_WITH_DATA_HEADER($file_size, $filename);
    send($client_socket, $header, 0);

    my $chunk_size = 1024*128;
    $epoll::clients{fileno $client_socket}{filestream} = {
        file => $fh,
        file_size => $file_size,
        file_pos => 0,
        chunk_size => $chunk_size,
    };
    epoll_ctl($main::epoll, EPOLL_CTL_MOD, fileno $client_socket, EPOLLIN | EPOLLOUT) >= 0 || die "Can't add client socket to main::epoll: $!";
    $epoll::clients{fileno $client_socket}{"has_out"} = 1;
    # print("Added client socket to writeepoll\n");

    main::handle_filestream(fileno $client_socket);
    # main::epoll_loop();
    # my $response = HTTP_RESPONSE::OK_WITH_DATA($data, $filename);
    # http_utils::send_http_response($client_socket, $response);
}

sub post_profile_ploud_delete {
    my ($client_socket, $route) = @_;
    my $filename;

    my $uuid = $main::user->{uuid};

    if ($route =~ /profile\/ploud\/delete\/(.*)/) {
        $filename = $1;
    }
    if (!$filename) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_404("File not found"));
    }

    my $base_dir = getcwd();
    my $dir_path = "$base_dir/Data/UserData/Users/$uuid/ploud/$filename";

    my $filepath = "$base_dir/Data/UserData/Users/$uuid/ploud/$filename/$filename";
    # print("FILEPATH: $filepath\n");
    if (!-e $filepath) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_404());
    }

    if (!$main::user) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_401("You are not logged in<br><a href=\"/ \">Return to index</a><br><a href=\"/login\">Login</a>"));
    }
    

    foreach my $file (glob "$dir_path/*") {
        # print("FILE: $file\n");
        my $file_to_check = $dir_path . "/" . $filename;
        if ($file eq $file_to_check) {
            my $filesize = -s $file;
            # print("FILESIZE: $filesize\n");
            my %data = (
                size => $filesize,
                subtract => 1
            );
            user_utils::update_user_metadata($uuid, \%data);
        }
        unlink $file or do { 
            # warn "Cannot delete file: $!";
            return;
        };
    }

    rmdir $dir_path or do 
    {
        # warn "Cannot delete directory: $!";
        return;
    };

    my $referer = request_utils::get_referer($main::header);
    my $response = HTTP_RESPONSE::REDIRECT_303($referer);
    http_utils::send_http_response($client_socket, $response);

}



sub post_profile_ploud_upgrade {
    my ($client_socket, $route) = @_;
    my $rank;
    if (!$main::user) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_401("You are not logged in<br><a href=\"/ \">Return to index</a><br><a href=\"/login\">Login</a>"));
    }

    if ($route =~ /profile\/ploud\/upgrade\/(.*)/) {
        $rank = $1;
    }
    if (!$rank) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_404("Rank not found"));
    }

    my $uuid = $main::user->{uuid};
    my $rank_id = user_utils::get_rank_id($rank);
    if (!$rank_id) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_404("Rank not found"));
    }

    my $current_rank_id = user_utils::get_user_stat($uuid, "rank_id");
    if ($current_rank_id >= $rank_id) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_409("You already have this rank or a better one"));
    }

    upgrade_rank($uuid, $rank, $rank_id);

    my $referer = request_utils::get_referer($main::header);
    if (!$referer) {
        $referer = "/";
    }

    my $response = HTTP_RESPONSE::REDIRECT_303($referer);
    http_utils::send_http_response($client_socket, $response);
}

sub upgrade_rank {
    my ($uuid, $rank, $rank_id) = @_;

    my $rank_stats = user_utils::get_rank_stats($rank_id, "benefits");
    user_utils::update_rank_stats($uuid, "name", $rank);
    user_utils::update_rank_stats($uuid, "id", $rank_id);
    user_utils::update_rank_stats($uuid, "max_storage", $rank_stats->{max_storage});

}

1;