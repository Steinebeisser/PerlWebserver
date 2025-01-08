package upload_utils;

use strict;
use warnings;
use Cwd;
use JSON;

my %locations = (
    "streaming/upload" => \&create_streaming_path,
    "/profile/ploud/upload" => \&create_ploud_path
);

my %upload_name_list = (
    "title" => "metadata",
    "description" => "metadata",
    "thumbnail" => "thumbnail"
);

my $client; 


sub handle_upload {
    my ($client_fd) = @_;

    $client = $epoll::clients{$client_fd};

    my $content_length = $epoll::clients{$client_fd}{content_length};

    if ($epoll::clients{$client_fd}{error}) {
        die "Error";
        return;
    }

    if (!$epoll::clients{$client_fd}{finished_metadata} && !$epoll::clients{$client_fd}{error}) {
        print("GETTING METADATA\n");
        get_metadata($client_fd);
        $epoll::clients{$client_fd}{write_file} = $epoll::clients{$client_fd}{filepath};
    }

    if ($epoll::clients{$client_fd}{finished_metadata} && !$epoll::clients{$client_fd}{finished} && !$epoll::clients{$client_fd}{error}) {
        # print("WRITING FILE\n");
        write_file_until_boundary($client_fd);
    }

    if ($epoll::clients{$client_fd}{finished}) {
        print("FINISHED UPLOAD\n");
        create_meta_data($client_fd);
        my $referer = $epoll::clients{$client_fd}{referer};
        print("REFERER: $referer\n");
        if (!$referer) {
            $referer = "/";
        }
        my $response = HTTP_RESPONSE::REDIRECT_303($referer);
        print("RESPOSE: $response\n");
        http_utils::send_http_response($epoll::clients{$client_fd}{socket}, $response);
    }
}

sub look_for_extra_data {
    my ($client_fd) = @_;
    # print("LOOoking eXtra data\n");

    my $bytes_read = sysread($epoll::clients{$client_fd}{socket}, my $buffer, 1024);
    if ($bytes_read == 0) {
        print("NO BYTES READ\n");
        return;
    }
    
    if ($buffer =~ /--$epoll::clients{$client_fd}{boundary}--/) {
        $epoll::clients{$client_fd}{complete_finished} = 1;
        return;
    }
}

sub create_meta_data {
    my ($client_fd) = @_;

    my $filename = $epoll::clients{$client_fd}{filename};
    my $content_type = $epoll::clients{$client_fd}{content_type};
    my $name = $epoll::clients{$client_fd}{name};

    my $file_path = $epoll::clients{$client_fd}{filepath};
    my $dir_path = $epoll::clients{$client_fd}{dir_path};
    print("DIR PATH: $dir_path\n");
    my $filepath = "$dir_path/metadata.json";
    my $base_dir = getcwd;
    my ($trimmed_filepath) = $file_path =~ /$base_dir\/(.*)/; 

    my %meta_data = (
        filename => $filename,
        filepath => $trimmed_filepath,
        uploaded_at => time(),
        size => -s $file_path
    );

    if ($epoll::clients{$client_fd}{video}) {
        $meta_data{enabled} = 1;
        $meta_data{views} = 0;
        $meta_data{likes} = 0;
        $meta_data{dislikes} = 0;
        $meta_data{video_id} = $epoll::clients{$client_fd}{video_id};
        $meta_data{channel_uuid} = $main::user->{uuid};

        my $base_dir = getcwd;
        my $streaming_path = "$base_dir/Data/Streaming";
        if (!-d $streaming_path) {
            mkdir $streaming_path or die "Cannot create directory: $!";
        }
        my $video_path = "$streaming_path/Videos";
        if (!-d $video_path) {
            mkdir $video_path or die "Cannot create directory: $!";
        }
        my $videos_file = "$video_path/videos.txt";
        print("VIDEOS FILE: $videos_file\n");
        my ($trimmed_filepath) = $filepath =~ /$base_dir\/(.*)/;
        open my $fh, '>>', $videos_file or die "Cannot open file: $!";
        binmode $fh; 
        print $fh "$trimmed_filepath\n";
        close $fh;

        my $user_path = "$base_dir/Data/UserData/Users/$main::user->{uuid}";
        if (!-d $user_path) {
            return;
        }
        my $user_videos_file = "$user_path/streaming/videos.txt";
        print("USER VIDEOS FILE: $user_videos_file\n");
        open my $user_fh, '>>', $user_videos_file or die "Cannot open file: $!";
        print($user_fh "$trimmed_filepath\n");
        close $user_fh;
    } else {

    }

    my $skip;
    my $upload_meta_data_file = "/tmp/upload_meta_data_$client_fd";
    open my $meta_fh, '<', $upload_meta_data_file or do 
    {
        $skip = 1;
    };
    if (!$skip) {
        binmode $meta_fh;
        local $/;
        my %upload_meta_data = %{ decode_json(<$meta_fh>) };
        close $meta_fh;
        foreach my $key (keys %upload_meta_data) {
            $meta_data{$key} = $upload_meta_data{$key};
        }
    }

    if (!$epoll::clients{$client_fd}{video}) {
        user_utils::update_user_metadata($main::user->{uuid}, \%meta_data);
    }

    open my $fh, '>', $filepath or die "Cannot open file: $!";
    binmode $fh; 
    print $fh encode_json(\%meta_data);
    close $fh;
}

sub get_metadata {
    my ($client_fd) = @_;

    print("GETTING METADATA\n");
    if (!$epoll::clients{$client_fd}{upload_tries} > 3) {
        # ! KILL CONNECTION
        die "Too many tries";
    }
    if (!$epoll::clients{$client_fd}{read_temp_file}) {
        my $data = body_utils::load_temp_file($epoll::clients{$client_fd}{temp_file});
        $epoll::clients{$client_fd}{read_temp_file} = 1;
        if ($data =~ /\r\n\r\n/) {
            my ($metadata, $file_data) = split(/\r\n\r\n/, $data, 2);
            print("DATA123: $file_data\n");
            extract_metadata($metadata, $client_fd, $file_data);
            $epoll::clients{$client_fd}{finished_metadata} = 1;
        } else {
            return;
        }
    } else {
        my $data = body_utils::load_temp_file($epoll::clients{$client_fd}{temp_file});
        my $bytes_read = sysread($epoll::clients{$client_fd}{socket}, my $buffer, 1024);
        $data .= $buffer;
        if ($bytes_read == 0) {
            return;
        }
        if ($data =~ /\r\n\r\n/) {
            my ($metadata, $file_data) = split(/\r\n\r\n/, $data, 2);
            print("DATA123: $file_data\n");
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

    my $filepath;
    my $dir_path;

    foreach my $key (keys %locations) {
        if ($epoll::clients{$client_fd}{location} =~ /$key/) {
            ($filepath, $dir_path) = $locations{$key}($client_fd, $user_path);
            last
        } 
    }    

    if (!$filepath) {
        http_utils::serve_error($epoll::clients{$client_fd}{socket}, HTTP_RESPONSE::ERROR_404());
        return;
    }

    # if (-e $filepath) {
    #     http_utils::serve_error($epoll::clients{$client_fd}{client_socket}, HTTP_RESPONSE::ERROR_409("File already exists"));
    #     $epoll::clients{$client_fd}{error} = 1;
    #     return;
    # }

    print("CREATING FILEPATH: $filepath\n");

    $epoll::clients{$client_fd}{filepath} = $filepath;
    $epoll::clients{$client_fd}{dir_path} = $dir_path;

    print("FILE DATA: $file_data\n");

    open my $fh, '>', $filepath or die "Cannot open file: $!";
    binmode $fh; 
    print $fh $file_data;
    close $fh;
}

sub create_ploud_path {
    my ($client_fd, $user_path, $file_data) = @_;

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


    return ($filepath, $dir_path);
}

sub create_streaming_path {
    my ($client_fd, $user_path, $file_data) = @_;

    my $streaming_path = "$user_path/streaming";
    print("STREAMING PATH: $streaming_path\n");
    if (!-d $streaming_path) {
        mkdir $streaming_path or die "Cannot create directory: $!";
    }
    my $video_id = video_utils::create_new_video_id();
    my $dir_path = "$streaming_path/$video_id";
    if (!-d $dir_path) {
        mkdir $dir_path or die "Cannot create directory: $!";
    }
    my $filepath = "$dir_path/$epoll::clients{$client_fd}{filename}";
    print("FILEPATH: $filepath\n");

    $epoll::clients{$client_fd}{video} = 1;
    $epoll::clients{$client_fd}{video_id} = $video_id;


    return ($filepath, $dir_path);
}

# my $sysread_bytes = 0;
sub write_file_until_boundary {
    my ($client_fd) = @_;
    my $client = $epoll::clients{$client_fd};
    
    my $bytes_read = sysread($client->{socket}, my $buffer, 1024*256);
    if ($bytes_read == 0) {
        die "Client disconnected";
        $client->{error} = 1;
        return;
    }
    # print("SYSREAD BYTES: $bytes_read\n");
    # $sysread_bytes = $bytes_read;

    $client->{buffer} .= $buffer;

    process_buffer($client_fd);
}
my $save_length = 50;
sub process_buffer {
    my ($client_fd) = @_;
    my $client = $epoll::clients{$client_fd};
    my $boundary = "--$client->{boundary}";
    my $buffer = $client->{buffer};
    if (!$buffer) {
        die "No buffer";
    }

    if ($buffer !~ /$boundary/) {
        # print("BUFFER LENGTH: ". length($buffer) ."\n");
        # my ($write_data, $save_data) = $buffer =~ /^(.*)(\r(?!.*\r).*$)/s;
        my $write_data = substr($buffer, 0, -$save_length);
        my $save_data  = substr($buffer, -$save_length);
        # print("Write data length: " . length($write_data) . "\n");
        if (!$write_data && !$save_data) {
            print("WRITE = BUFFER\n");
            $write_data = $buffer;
        }
        write_to_file($client_fd, $write_data);
        if ($save_data) {
            # print("SAVING DATA\n");
            $client->{buffer} = $save_data;
            return;
        } else {
            $client->{buffer} = '';
            return;
        }
    } else {
        # print("BOUNDARY FOUND\n");
    }
    while ($buffer =~ /(.*?)((?:\r\n)?$boundary(?:--)?(?:\r\n)?)(.*)/s) {
        my ($before_boundary, $buffer_boundary, $remaining) = ($1, $2, $3, $4, $5);
        # print("REMAINING: $remaining\n");
        write_to_file($client_fd, $before_boundary) if $before_boundary;

        if ($buffer_boundary =~ /--\r\n/) {
            # warn "Final boundary detected. Ending processing.";
            finalize_processing($client_fd);
            $client->{buffer} = '';
            return;
        }

        $buffer = $remaining;
        my $keep_buffer;
        my $need_one_more = 0;
        my $keep_buffer_need = 0;
        while ($buffer =~ /^(.*?\r\n\r\n)(.*?)(?=((?:\r\n)?$boundary(--\r\n)?)|$)(.*)/s) {
            my ($metadata, $body, $boundary_data, $ending, $after_boundary) = ($1, $2, $3, $4, $5);
            handle_form_metadata($client_fd, $metadata, $body);
            if ($boundary_data && $boundary_data =~ /$boundary/) {
                $need_one_more = 1;
                $keep_buffer = $boundary_data . $after_boundary;
            } elsif ($boundary_data && $boundary_data !~ /$boundary/) {
                $keep_buffer = $boundary_data;
                $keep_buffer_need = 1;
                last;
            } elsif (!$boundary_data) {
                $keep_buffer = '';
                $keep_buffer_need = 0;
                $need_one_more = 0;
            }
            if ($ending) {
                finalize_processing($client_fd);
                $client->{buffer} = '';
                return;
            }
            $buffer =~ s/^(.*?\r\n\r\n)(.*?)(?=$boundary|$)//s; 
        }

        if ($need_one_more || $keep_buffer_need) {
            # print("NEED ONE MORE\n");
            # print("KEEP BUFFER: $keep_buffer\n");
            # print("BUFFER: $buffer\n");
            $client->{buffer} = $keep_buffer;

            return;
        }

        if ($buffer !~ /^\s*$/) {
            # print("BUFFER: $buffer\n");
            $client->{buffer} = $buffer;
            warn "Incomplete data detected, saving for next chunk.";
            return;
        }
    }

    # print("LEFTOVER DATA: $buffer\n");
    $client->{buffer} = $buffer;
}
# my $total_bytes = 0;
sub write_to_file {
    my ($client_fd, $data) = @_;
    my $client = $epoll::clients{$client_fd};

    if (!$data) {
        return;
    }

    open my $fh, '>>', $client->{write_file} or die "Cannot open file: $!";
    binmode $fh;
    print $fh $data;
    close $fh;

    # $total_bytes += length($data);

    # warn "Wrote data to file: " . length($data) . " bytes.";
    # if (length($data) != $sysread_bytes) {
    #     warn "total bytes: $total_bytes";
    #     die "Wrong length";
    # }
}


sub handle_form_metadata {
    my ($client_fd, $metadata, $body) = @_;
    my $client = $epoll::clients{$client_fd};

    chomp($metadata);
    print($metadata);
    push @{$client->{forms}}, $metadata;
    
    if ($metadata =~ /Content-Disposition: form-data; name="([^"]+)"/) {
        my $name = $1;
        my $todo = $upload_name_list{$name};
        if (!$todo) {
            warn "No action defined for form data: $name";
            return;
        }
        print("TODO: $todo\n");
        print("NAME: $name\n");
        my $upload_meta_data_file = "/tmp/upload_meta_data_$client_fd";
        if (!-e $upload_meta_data_file) {
            open my $fh, '>', $upload_meta_data_file or die "Cannot open file: $!";
            binmode $fh;
            print $fh "{}";
            close $fh;
        }

        open my $meta_fh, '<', $upload_meta_data_file or warn "Cannot open file: $!";
        local $/;
        my %upload_meta_data = %{ decode_json(<$meta_fh>) };
        close $meta_fh;

        if ($todo eq "metadata") {
            # ! if body is not done by end of request, doesnt work, needs fix
            if (!$body) {
                die "No body";
            }
            print("Writing metadata: $name => $body\n");
            $upload_meta_data{$name} = $body;
            $client->{write_file} = "/tmp/noUse";
        } elsif ($todo eq "thumbnail") {
            if ($metadata =~ /filename="(.*)"/) {
                my $filename = $1;
                my $base_dir = getcwd;
                my $file_path = "$client->{dir_path}/$filename";
                my ($trimmed_filepath) = $file_path =~ /$base_dir\/(.*)/; 
                $client->{write_file} = $trimmed_filepath;
                $upload_meta_data{$name} = $client->{write_file};

                open my $fh, '>', $client->{write_file} or die "Cannot open file: $!";
                binmode $fh;
                print $fh $body;
                close $fh;
                print("Thumbnail saved to $client->{write_file}\n"); 
                # print("BODY: $body\n");
            } else {
                print("NO FILENAME\n");
                die;
            }
        } 
        open my $meta_fh, '>', $upload_meta_data_file or die "Cannot open file: $!";
        binmode $meta_fh;
        print $meta_fh encode_json(\%upload_meta_data);
        close $meta_fh;
    }
}

sub finalize_processing {
    my ($client_fd) = @_;
    my $client = $epoll::clients{$client_fd};
    $client->{finished} = 1;

    # Output processed form metadata
    foreach my $form (@{$client->{forms}}) {
        print "=========== FORM METADATA ===========\n";
        print($form."\n");
        print "=====================================\n";
    }
}


# sub write_to_file {
#     my ($client_fd, $buffer) = @_;
#     my $client = $epoll::clients{$client_fd};

#     open my $fh, '>>', $client->{write_file} or die "Cannot open file: $!";
#     binmode $fh;
#     print $fh $buffer;
#     close $fh;
# }


# sub write_file_until_boundary {
#     my ($client_fd) = @_;
#     my $client = $epoll::clients{$client_fd};

#     my $bytes_read = sysread($client->{socket}, my $buffer, 1024);
#     if ($bytes_read == 0) {
#         die "Client disconnected";
#         $client->{error} = 1;
#         return;
#     }

#     my $data_buffer = check_for_boundary($client_fd, $buffer);

    
#     if ($finish_write_data) {
#         $buffer = $finish_write_data;
#     }
#     my $write_buffer = substr($buffer, 0, -30);
#     $client->{last_buffer} = substr($buffer, -30);
    
#     open my $fh, '>>', $client->{write_file} or die "Cannot open file: $!";
#     binmode $fh;
#     print $fh $write_buffer;
#     close $fh;
#     if ($client->{write_file2}) {
#         $client->{write_file} = $client->{write_file2};
#         $client->{write_file2} = "";
#     }
# }

# sub check_for_boundary {
#     my ($client_fd, $buffer) = @_;

#     if ($buffer !~ /--$client->{boundary}/) {
#         return $buffer;
#     }

#     $buffer =~ /(.*?)--$client->{boundary}(.*)/s;
#     my ($file_data, $remaining_data) = ($1, $2);

#     my $data_buffer = check_for_boundary($client_fd, $remaining_data);

#     print("REMAINING DATA: $data_buffer\n");

#     if ($remaining_data eq "--\r\n") {
#         $client->{finished} = 1;
#         $client->{complete_finished} = 1;
#         print("FINISHED PROCESSING\n");
#         $buffer = user_utils::create_random_string(30) . $file_data;
#         last;
#     }

#         $buffer = $remaining_data;
#         $client->{last_buffer} = $buffer;
#         print("REM DATA: $remaining_data\n");
        
#         if ($buffer =~ /Content-Disposition: form-data; name="([^"]+)"/) {
#             my $name = $1;
#             print("NAME: $name\n");
#             my $todo = $upload_name_list{$name};
#             if (!$todo) {
#                 #! idk
#                 print("NO TODO\n");
#                 print("REMAINING DATA: $remaining_data\n");
#                 print("NAME: $name\n");
#                 die;
#             }
#             my $upload_meta_data_file = "/tmp/upload_meta_data_$client_fd";
#             if (!-e $upload_meta_data_file) {
#                 open my $fh, '>', $upload_meta_data_file or die "Cannot open file: $!";
#                 binmode $fh;
#                 print $fh "{}";
#                 close $fh;
#             }

#             open my $meta_fh, '<', $upload_meta_data_file or warn "Cannot open file: $!";
#             local $/;
#             my %upload_meta_data = %{ decode_json(<$meta_fh>) };
#             close $meta_fh;

#             if ($todo eq "metadata") {
#                 if (my ($value) = $file_data =~ /name=".*"\r\n\r\n(.*)/) {
#                     print("Writing metadata: $name => $value\n");
#                     $upload_meta_data{$name} = $value;
#                     $client->{write_file2} = "/tmp/noUse";
#                 }
#                 open my $meta_fh, '>', $upload_meta_data_file or die "Cannot open file: $!";
#                 binmode $meta_fh;
#                 print $meta_fh encode_json(\%upload_meta_data);
#                 close $meta_fh;
#             } elsif ($todo eq "thumbnail") {
#                 if ($remaining_data =~ /filename="(.*)"/) {
#                     my $filename = $1;
#                     $client->{write_file2} = "$client->{dir_path}/$filename";
#                     $upload_meta_data{$name} = $client->{write_file2};

#                     my ($write_data) = $remaining_data =~ /Content-Type: (.*)\r\n\r\n(.*)/s;
#                     open my $fh, '>', $client->{write_file2} or die "Cannot open file: $!";
#                     binmode $fh;
#                     print $fh $write_data;
#                     close $fh;
#                     print("Thumbnail saved to $client->{write_file2}\n"); 
#                 } else {
#                     print("NO FILENAME\n");
#                     die;
#                 }
#             } else {
#                 print("NO TODO\n");
#                 die;
#             }
#         }
#     }
# }
#     # Save remaining data to a file
#     $client->{last_buffer} = substr($buffer, -30);
#     $buffer = substr($buffer, 0, -30) if length($buffer) > 1024;

#     open my $fh, '>>', $client->{write_file} or die "Cannot open file: $!";
#     binmode $fh;
#     print $fh $buffer;
#     close $fh;

#     # Switch files if needed
#     if ($client->{write_file2}) {
#         print("Switching files from $client->{write_file} to $client->{write_file2}\n");
#         $client->{write_file} = $client->{write_file2};
#         $client->{write_file2} = "";
#     }
# }
# sub write_file_until_boundary {
#     my ($client_fd) = @_;
#     # print("CLIENT SOCKET: $epoll::clients{$client_fd}{socket}\n");
    
#     my $bytes_read = sysread($epoll::clients{$client_fd}{socket}, my $buffer, 1024);
#     if ($bytes_read == 0) {
#         return;
#     }
#     my $last_buffer = $epoll::clients{$client_fd}{last_buffer};
#     if ($last_buffer) {
#         $buffer = $last_buffer . $buffer; # if BOUNDARY is split between two buffers
#     }
#     # print("BUFFER: $buffer\n");
#     my $i = 0;
#     if ($buffer =~ /--$epoll::clients{$client_fd}{boundary}/) {
#         my $buffer_copy = $buffer;
#         my ($write_data) = $buffer =~ /(.*?)--$epoll::clients{$client_fd}{boundary}/s;
#         while ($buffer =~ /(.*?)--$epoll::clients{$client_fd}{boundary}(.*)/s) {
#             my ($file_data, $remaining_data) = ($1, $2);

#             if ($remaining_data eq "--\r\n") {
#                 $epoll::clients{$client_fd}{finished} = 1;
#                 $epoll::clients{$client_fd}{complete_finished} = 1;
#                 print("FINITO\n");
#                 $buffer = user_utils::create_random_string(30);
#                 $buffer .= $file_data;
#                 last;
#             } 

#             if ($remaining_data =~ /Content-Disposition: form-data; name="([^"]+)"/) {
#                 my $name = $1;
#                 my $todo = $upload_name_list{$name};
#                 my $upload_meta_data_file = "/tmp/upload_meta_data_$client_fd";
#                 if (!-e $upload_meta_data_file) {
#                     open my $fh, '>', $upload_meta_data_file or die "Cannot open file: $!";
#                     binmode $fh;
#                     print $fh "{}";
#                     close $fh;
#                 }
#                 open my $meta_fh, '<', $upload_meta_data_file or do {
#                     warn "Cannot open file: $!";
#                 };
#                 binmode $meta_fh;
#                 local $/;
#                 my %upload_meta_data = %{ decode_json(<$meta_fh>) };
#                 close $meta_fh;
#                 if (!$todo) {
#                     #! idk
#                 } elsif ($todo eq "metadata") {
#                     print("METADATA\n");
#                     print("NAME: $name\n");
#                     my ($value) = $file_data =~ /name=".*"\r\n\r\n(.*)/;
#                     print("METADATANAME: WRITING: $value\n");
#                     $upload_meta_data{$name} = $value;
#                     $epoll::clients{$client_fd}{write_file2} = "/tmp/noUse";
#                 } elsif ($todo eq "thumbnail") {
#                     print($remaining_data);
#                     if ($remaining_data =~ /filename="(.*)"/) {
#                         my $filename = $1;
#                         $epoll::clients{$client_fd}{write_file2} = "$epoll::clients{$client_fd}{dir_path}/$filename";
#                         $upload_meta_data{$name} = $epoll::clients{$client_fd}{write_file2};
#                         my ($content_type, $data) = $remaining_data =~ /Content-Type: (.*)\r\n\r\n(.*)/; 
#                         open my $fh, '>', $epoll::clients{$client_fd}{write_file2} or die "Cannot open file: $!";
#                         binmode $fh;
#                         print $fh $data;
#                         print("THUMBNAIL: WRITING $data to $epoll::clients{$client_fd}{write_file2}\n");
#                         print("start\n$file_data\nend\n");
#                         close $fh;
#                     } else {
#                         #! idk
#                         die;
#                     }
#                 }
#                 open my $meta_fh, '>', $upload_meta_data_file or die "Cannot open file: $!";
#                 binmode $meta_fh;
#                 print $meta_fh encode_json(\%upload_meta_data);
#                 close $meta_fh;
#             }
            
#             $buffer =~ s/(.*)--$epoll::clients{$client_fd}{boundary}//;
#         } 
#         $buffer = $write_data;
#     }
#     $epoll::clients{$client_fd}{last_buffer} = substr($buffer, -30);
#     if (length($buffer) > 1024) {
#         $buffer = substr($buffer, 0, -30);
#     }
#     open my $fh, '>>', $epoll::clients{$client_fd}{write_file} or die "Cannot open file: $!";
#     binmode $fh;
#     print $fh $buffer;
#     close $fh;
#     if ($epoll::clients{$client_fd}{write_file2}) {
#         print("SWITCHING FILES\n");
#         print("FILE1: $epoll::clients{$client_fd}{write_file}\n");
#         print("FILE2: $epoll::clients{$client_fd}{write_file2}\n");
#         $epoll::clients{$client_fd}{write_file} = $epoll::clients{$client_fd}{write_file2};
#         $epoll::clients{$client_fd}{write_file2} = "";
#     }
# }

1;