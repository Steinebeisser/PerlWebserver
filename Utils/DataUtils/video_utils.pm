package video_utils;

use strict;
use warnings;

use Cwd;
use MIME::Base64;
use Digest::SHA qw(sha256_hex);
use JSON;

sub get_top_videos {
    my $base_dir = getcwd();
    my $video_path = "$base_dir/Data/Streaming/Videos";
    my $videos_file = "$video_path/videos.txt";
    
    my @videos = get_videos($videos_file);
    # foreach my $video (@videos) {
    #     print("VIDEO: $video\n");
    # }
    return @videos;
}

sub get_videos {
    my ($videos_file) = @_;

    my $base_dir = getcwd();
    open my $fh, "<", $videos_file or do {
        warn "Could not open file $videos_file: $!";
        return;
    };
    my @videos;
    while (my $line = <$fh>) {
        chomp $line;
        my $meta_data_file = "$base_dir/$line";
        open my $meta_fh, "<", $meta_data_file or do {
            warn "Could not open file $meta_data_file: $!";
            next;
        };
        my $meta_data = do { local $/; <$meta_fh> };
        close $meta_fh;
        my $video = { video_name => $meta_data };
        my $video_data = decode_json($meta_data);
        # print("VIDEO DATA: $video_data\n");
        # print("FILE: $file\n");
        # foreach my $key (keys %$file) {
        #     print("KEY: $key\n");
        #     print("VALUE: $file->{$key}\n");
        # }
        if ($video_data->{enabled}) {
            # $video->{filepath} = $file->{filepath};
            my %new_video_data;

            $new_video_data{title} = user_utils::decode_uri($video_data->{title});
            $new_video_data{thumbnail_path} = "$base_dir/$video_data->{thumbnail_path}";
            $new_video_data{video_id} = $video_data->{video_id};
            $new_video_data{channel_name} = user_utils::decode_uri(user_utils::get_display_name_with_uuid($video_data->{channel_uuid}));
            $new_video_data{channel_username} = user_utils::get_username_by_uuid($video_data->{channel_uuid});
            
            push(@videos, \%new_video_data);
        }

    }
    close $fh;

    return @videos;
}


sub create_new_video_id {
    my $base_dir = getcwd();
    my $video_path = "$base_dir/Data/Streaming/Videos";
    my $video_id_file = "$video_path/video_id.txt";
    
    open my $fh, "<", $video_id_file;
    my $video_id = <$fh>;
    close $fh;
    
    $video_id++;

    if (!$video_id) {
        $video_id = 1;
    }
    
    my $hash = sha256_hex($video_id);
    my $b64 = encode_base64($hash, "");
    my $encoded_id = substr($b64, 0, 11);
    
    open $fh, ">", $video_id_file;
    print $fh $video_id;
    close $fh;
    
    return $encoded_id;
}

my %video_endings = (
    "mp4" => "video/mp4",
    "webm" => "video/webm",
    "ogg" => "video/ogg"
);

sub get_video {
    my ($video_id, $client_socket) = @_;
    # print("GETTING VIDEO\n");
    my $base_dir = getcwd();
    my $video_path = "$base_dir/Data/Streaming/Videos";
    my $videos_file = "$video_path/videos.txt";
    my $full_file_path;
    open my $fh, "<", $videos_file;
    
    while (my $line = <$fh>) {
        chomp $line;
        if ($line !~ /$video_id/) {
            next;
        }
        my $meta_data_file = "$base_dir/$line";
        open my $meta_fh, "<", $meta_data_file;
        my $meta_data = do { local $/; <$meta_fh> };
        close $meta_fh;
        my $video_data = decode_json($meta_data);
        # print("VIDEO DATA: $video_data\n");
        # foreach my $key (keys %$file) {
            # print("KEY: $key\n");
            # print("VALUE: $file->{$key}\n");
        # }
        my $file_path = $video_data->{filepath};
        # print("FILE PATH: $file_path\n");
        $full_file_path = "$base_dir/$file_path";
        # print("Full file path: $full_file_path\n");
        last;
    }
    close $fh;

    if (!$full_file_path) {
        return HTTP_RESPONSE::ERROR_404("Video not found");
    }

    if (!-e $full_file_path) {
        return HTTP_RESPONSE::ERROR_404("Video not found");
    }
    my $file_size = -s $full_file_path;
    # print("FILE SIZE: $file_size\n");
    my $start_range_none = 0;
    my ($start_range, $end_range) = request_utils::get_range($main::header);
    # print("RANGE: $start_range - $end_range\n");
    if ($start_range eq "none") {
        $start_range = 0;
        $start_range_none = 1;
        $end_range = 0;
    }
    
    my $file_ending = $full_file_path;
    $file_ending =~ s/.*\.(.*)/$1/;
    my $content_type = $video_endings{$file_ending};


    if ($start_range eq "0") {
        $start_range = 0;
    }

    if (!$end_range) {
        $end_range = $start_range + 524288;
        # print("END RANGE: $end_range\n");
    }
    
    # print("FULL FILE PATH: $full_file_path\n");
    open my $video_fh, "<", $full_file_path;
    binmode $video_fh;
    if ($start_range) {
        seek($video_fh, $start_range, 0);
    }
    my $video_data = "";
    if ($end_range) {
        # print("SIZE FILE: $file_size\n");
        if ($end_range > $file_size) {
            $end_range = $file_size;
        }
        read($video_fh, $video_data, $end_range - $start_range + 1);
    } else {
        die "No end range";
    }
    close $video_fh;

    if ($start_range_none) {
        http_utils::send_response($client_socket, HTTP_RESPONSE::OK_ACCEPT_RANGE($video_data, $file_size, $content_type));
        return;
    }
    # print("VIDEO DATA: $video_data\n");
    my $partial_content = HTTP_RESPONSE::PARTIAL_CONTENT_206($video_data, $start_range, $end_range, $file_size, $content_type);
    # print("SENDING RESPONSE to $end_range\n");
    http_utils::send_response($client_socket, $partial_content);
}



1;