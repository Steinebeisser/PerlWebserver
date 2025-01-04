package upload_utils;

use strict;
use warnings;
use Cwd;
use JSON;

sub handle_upload {
    my ($client_fd) = @_;

    my $content_length = $epoll::clients{$client_fd}{content_length};

    if ($epoll::clients{$client_fd}{error}) {
        return;
    }

    if (!$epoll::clients{$client_fd}{finished_metadata} && !$epoll::clients{$client_fd}{error}) {
        print("GETTING METADATA\n");
        get_metadata($client_fd);
    }

    if ($epoll::clients{$client_fd}{finished_metadata} && !$epoll::clients{$client_fd}{finished} && !$epoll::clients{$client_fd}{error}) {
        # print("WRITING FILE\n");
        write_file_until_boundary($client_fd);
    }

    if ($epoll::clients{$client_fd}{finished}) {
        create_meta_data($client_fd);
        my $referer = $epoll::clients{$client_fd}{referer};
        print("REFERER: $referer\n");
        if (!$referer) {
            $referer = "/profile/ploud/upload";
        }
        my $response = HTTP_RESPONSE::REDIRECT_303($referer);
        http_utils::send_http_response($epoll::clients{$client_fd}{socket}, $response);
    }
}


sub create_meta_data {
    my ($client_fd) = @_;

    my $filename = $epoll::clients{$client_fd}{filename};
    my $content_type = $epoll::clients{$client_fd}{content_type};
    my $name = $epoll::clients{$client_fd}{name};

    my $file_path = $epoll::clients{$client_fd}{filepath};
    my ($dir_path) = $file_path =~ /(.*)\//;
    print("DIR PATH: $dir_path\n");
    my $filepath = "$dir_path/metadata.json";

    my %meta_data = (
        $name => {
            filename => $filename,
            filepath => $filepath,
            uploaded_at => time(),
            size => -s $file_path
        }
    );

    user_utils::update_user_metadata($main::user->{uuid}, $meta_data{$name});

    open my $fh, '>', $filepath or die "Cannot open file: $!";
    binmode $fh; 
    print $fh encode_json(\%meta_data);
    close $fh;
}

sub get_metadata {
    my ($client_fd) = @_;

    if (!$epoll::clients{$client_fd}{upload_tries} > 3) {
        # ! KILL CONNECTION
        die;
    }
    if (!$epoll::clients{$client_fd}{read_temp_file}) {
        my $data = body_utils::load_temp_file($epoll::clients{$client_fd}{temp_file});
        $epoll::clients{$client_fd}{read_temp_file} = 1;
        if ($data =~ /\r\n\r\n/) {
            my ($metadata, $file_data) = split(/\r\n\r\n/, $data, 2);
            # print("DATA123: $data\n");
            extract_metadata($metadata, $client_fd, $file_data);
            $epoll::clients{$client_fd}{finished_metadata} = 1;
        } else {
            return;
        }
    } else {
        my $data = body_utils::load_temp_file($epoll::clients{$client_fd}{temp_file});
        my $bytes_read = sysread($epoll::clients{$client_fd}{client_socket}, my $buffer, 1024);
        $data .= $buffer;
        if ($bytes_read == 0) {
            return;
        }
        if ($data =~ /\r\n\r\n/) {
            my ($metadata, $file_data) = split(/\r\n\r\n/, $data, 2);
            # print("DATA123: $data\n");
            extract_metadata($metadata, $client_fd, $file_data);
            $epoll::clients{$client_fd}{finished_metadata} = 1;
        }
    }

    if (!$epoll::clients{$client_fd}{finished_metadata}) {
        $epoll::clients{$client_fd}{upload_tries}++;
    }
}

sub extract_metadata {
    my ($metadata, $client_fd, $file_data) = @_;
    # print("METADATA: $metadata\n");
    # die;
    my ($filename) = $metadata =~ /filename="(.*)"/;
    $filename = user_utils::encode_uri($filename);
    my ($content_type) = $metadata =~ /Content-Type: (.*)/; 
    my ($name) = $metadata =~ /name="(.*)"; filename/;
    $epoll::clients{$client_fd}{filename} = $filename;
    $epoll::clients{$client_fd}{content_type} = $content_type;
    $epoll::clients{$client_fd}{name} = $name;

    # print("FILE DATA: $file_data\n");
    create_file($client_fd, $file_data);
}

sub create_file {
    my ($client_fd, $file_data) = @_;

    my $uuid = $main::user->{uuid};

    if (!$uuid) {
        http_utils::serve_error($epoll::clients{$client_fd}{socket}, HTTP_RESPONSE::ERROR_401());
        return;
    }

    my $base_dir = getcwd;
    my $user_path = "$base_dir/Data/UserData/Users/$uuid";
    print("USER PATH: $user_path\n");
    if (!-d $user_path) {
        print("WADAFUCK\n");
        mkdir $user_path or die "Cannot create directory: $!";
    }
    my $ploud_path = "$user_path/ploud";
    print("PLOUD PATH: $ploud_path\n");
    if (!-d $ploud_path) {
        mkdir $ploud_path or die "Cannot create directory: $!";
    }
    my $dir_path = "$ploud_path/$epoll::clients{$client_fd}{filename}";
    if (!-d $dir_path) {
        mkdir $dir_path or die "Cannot create directory: $!";
    }
    my $filepath = "$dir_path/$epoll::clients{$client_fd}{filename}";
    print("FILEPATH: $filepath\n");

    # if (-e $filepath) {
    #     http_utils::serve_error($epoll::clients{$client_fd}{client_socket}, HTTP_RESPONSE::ERROR_409("File already exists"));
    #     $epoll::clients{$client_fd}{error} = 1;
    #     return;
    # }

    $epoll::clients{$client_fd}{filepath} = $filepath;

    open my $fh, '>', $filepath or die "Cannot open file: $!";
    binmode $fh; 
    print $fh $file_data;
    close $fh;
}

sub write_file_until_boundary {
    my ($client_fd) = @_;
    # print("CLIENT SOCKET: $epoll::clients{$client_fd}{socket}\n");

    my $bytes_read = sysread($epoll::clients{$client_fd}{socket}, my $buffer, 1024);
    if ($bytes_read == 0) {
        return;
    }
    # print("BUFFER: $buffer\n");
    if ($buffer =~ /--$epoll::clients{$client_fd}{boundary}/) {
        ($buffer, my $boundary) = split(/--$epoll::clients{$client_fd}{boundary}--/, $buffer, 2);
        # print("BOUNDARY: $boundary\n");
        $epoll::clients{$client_fd}{finished} = 1;
    }
    open my $fh, '>>', $epoll::clients{$client_fd}{filepath} or die "Cannot open file: $!";
    binmode $fh;
    print $fh $buffer;
    close $fh;
}

1;