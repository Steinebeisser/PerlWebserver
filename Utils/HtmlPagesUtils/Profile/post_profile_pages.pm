package post_profile_pages;

use strict;
use warnings;

sub post_profile_ploud_upload {
    my ($client_socket, $request) = @_;

    my $referer = request_utils::get_referer($request);
    if (!$referer) {
        $referer = "/";
    }
    # reload_page($client_socket, $referer);
    # print("SENDING REDIRECT\n");
    my $response = HTTP_RESPONSE::REDIRECT_303($referer);
    # print("I GOT REDIRECT\n");
    http_utils::send_http_response($client_socket, $response);
    my $meta_data = get_meta_data($request, $client_socket);
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

                my $ploud_path = "UserData/$main::user->{username}/ploud";
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
        $name => {
            filename => $filename,
            filepath => $filepath,
            uploaded_at => time(),
            size => -s $filepath
        }
    );

    user_utils::update_user_metadata($main::user->{username}, $meta_data{$name});

    open my $fh, '>', "$dir_path/metadata.json" or die "Cannot open file: $!";
    binmode $fh; 
    print $fh encode_json(\%meta_data);
    close $fh;
}

sub post_profile_ploud_download {
    my ($client_socket, $request) = @_;
    my $username;
    my $filename;

    my $cookie_data = request_utils::get_cookie_data($request);
    $username = $cookie_data->{username};

    if ($request =~ /profile\/ploud\/download\/(.*) HTTP\/1.1/) {
        $filename = $1;
    }
    if (!$filename) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_404());
    }

    my $filepath = "UserData/$username/ploud/$filename/$filename";
    # print("FILEPATH: $filepath\n");
    if (!-e $filepath) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_404());
        return;
    }

    if (!$main::user) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_401("You are not logged in<br><a href=\"/ \">Return to index</a><br><a href=\"/login\">Login</a>"));
    } elsif ($main::user->{username} ne $username) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_401("You are not allowed to view this page<br><a href=\"/ \">Return to index</a>"));
    }

    my $meta_data = get_meta_data($request, $client_socket);

    my $referer = request_utils::get_referer($request);
    
    open my $fh, '<', $filepath or die "Cannot open file: $!";
    binmode $fh;
    my $data;
    {
        local $/;
        $data = <$fh>;
    }
    close $fh;
    my $response = HTTP_RESPONSE::OK_WITH_DATA($data, $filename);
    http_utils::send_http_response($client_socket, $response);

}

sub post_profile_ploud_delete {
    my ($client_socket, $request) = @_;
    my $username;
    my $filename;

    my $cookie_data = request_utils::get_cookie_data($request);
    $username = $cookie_data->{username};

    if ($request =~ /profile\/ploud\/delete\/(.*) HTTP\/1.1/) {
        $filename = $1;
    }
    if (!$filename) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_404("File not found"));
    }

    my $dir_path = "UserData/$username/ploud/$filename";

    my $filepath = "UserData/$username/ploud/$filename/$filename";
    # print("FILEPATH: $filepath\n");
    if (!-e $filepath) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_404());
    }

    if (!$main::user) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_401("You are not logged in<br><a href=\"/ \">Return to index</a><br><a href=\"/login\">Login</a>"));
    } elsif ($main::user->{username} ne $username) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_401("You are not allowed to view this page<br><a href=\"/ \">Return to index</a>"));
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
            user_utils::update_user_metadata($username, \%data);
        }
        unlink $file or die "Cannot delete file: $!";
    }

    rmdir $dir_path or die "Cannot delete directory: $!";

    my $referer = request_utils::get_referer($request);
    my $response = HTTP_RESPONSE::REDIRECT_303($referer);
    http_utils::send_http_response($client_socket, $response);

}



sub post_profile_ploud_upgrade {
    my ($client_socket, $request) = @_;
    my $rank;
    if (!$main::user) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_401("You are not logged in<br><a href=\"/ \">Return to index</a><br><a href=\"/login\">Login</a>"));
    }

    if ($request =~ /profile\/ploud\/upgrade\/(.*) HTTP\/1.1/) {
        $rank = $1;
    }
    if (!$rank) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_404("Rank not found"));
    }

    my $username = $main::user->{username};
    my $rank_id = user_utils::get_rank_id($rank);
    if (!$rank_id) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_404("Rank not found"));
    }

    my $current_rank_id = user_utils::get_user_stat($username, "rank_id");
    if ($current_rank_id >= $rank_id) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_409("You already have this rank or a better one"));
    }

    upgrade_rank($username, $rank, $rank_id);

    my $referer = request_utils::get_referer($request);
    if (!$referer) {
        $referer = "/";
    }

    my $response = HTTP_RESPONSE::REDIRECT_303($referer);
    http_utils::send_http_response($client_socket, $response);
}

sub upgrade_rank {
    my ($username, $rank, $rank_id) = @_;

    my $rank_stats = user_utils::get_rank_stats($rank_id, "benefits");
    user_utils::update_rank_stats($username, "name", $rank);
    user_utils::update_rank_stats($username, "id", $rank_id);
    user_utils::update_rank_stats($username, "max_storage", $rank_stats->{max_storage});

}

1;