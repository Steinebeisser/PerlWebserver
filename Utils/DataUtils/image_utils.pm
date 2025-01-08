package image_utils;

use strict;
use warnings;

use Cwd;
use JSON;
use IO::Epoll;

sub get_thumbnail {
    my ($video_id, $client_socket) = @_;

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

        my $file_path = $video_data->{thumbnail};

        $full_file_path = "$base_dir/$file_path";
        print("Full file path: $full_file_path\n");
        last;
    }
    close $fh;
    
    get_image($full_file_path, $client_socket);
}

sub get_channel_icon {
    my ($channel_id, $client_socket) = @_;

    my $base_dir = getcwd();
    my $channel_path = "$base_dir/Data/UserData/Users/$channel_id/Streaming";
    if (!-d $channel_path) {
        get_default_channel_icon($client_socket);
        return;
    }
    my $channel_metadata_file = "$channel_path/channel_metadata.txt";
    if (!-e $channel_metadata_file) {
        get_default_channel_icon($client_socket);
        return;
    }
    my $full_file_path;
    open my $fh, "<", $channel_metadata_file;
    my $channel_metadata = do { local $/; <$fh> };
    close $fh;
    my $channel_data = decode_json($channel_metadata);
    my $file_path = $channel_data->{channel_icon};
    $full_file_path = "$base_dir/$file_path";
    if (!-e $full_file_path) {
        get_default_channel_icon($client_socket);
        return;
    }
    get_image($full_file_path, $client_socket);
}

sub get_default_channel_icon {
    my ($client_socket) = @_;

    my $base_dir = getcwd();
    my $file_path = "$base_dir/Data/Streaming/Images/default_channel_icon.png";
    if (!-e $file_path) {
        my $error = HTTP_RESPONSE::ERROR_404("Image not found");
        http_utils::send_response($client_socket, $error);
        return;
    }
    get_image($file_path, $client_socket);
}

sub get_channel_banner {
    my ($channel_id, $client_socket) = @_;

    my $base_dir = getcwd();
    my $channel_path = "$base_dir/Data/UserData/Users/$channel_id/Streaming";
    if (!-d $channel_path) {
        get_default_channel_banner($client_socket);
        return;
    }
    my $channel_metadata_file = "$channel_path/channel_metadata.txt";
    if (!-e $channel_metadata_file) {
        get_default_channel_banner($client_socket);
        return;
    }
    my $full_file_path;
    open my $fh, "<", $channel_metadata_file;
    my $channel_metadata = do { local $/; <$fh> };
    close $fh;
    my $channel_data = decode_json($channel_metadata);
    my $file_path = $channel_data->{channel_banner};
    $full_file_path = "$base_dir/$file_path";
    if (!-e $full_file_path) {
        get_default_channel_banner($client_socket);
        return;
    }
    get_image($full_file_path, $client_socket);
}

sub get_default_channel_banner {
    my ($client_socket) = @_;

    my $base_dir = getcwd();
    my $file_path = "$base_dir/Data/Streaming/Images/default_channel_banner.png";
    if (!-e $file_path) {
        my $error = HTTP_RESPONSE::ERROR_404("Image not found");
        http_utils::send_response($client_socket, $error);
        return;
    }
    get_image($file_path, $client_socket);
}

sub get_image {
    my ($full_file_path, $client_socket) = @_;

    my $file_size = -s $full_file_path;
    open my $fh, '<', $full_file_path or die "Cannot open file: $!";
    $epoll::clients{fileno $client_socket}{filestream} = {
        file => $fh,
        file_size => $file_size,
        file_pos => 0,
        chunk_size => 4096,
    };
    epoll_ctl($main::epoll, EPOLL_CTL_MOD, fileno $client_socket, EPOLLIN | EPOLLOUT) >= 0 || die "Can't add client socket to main::epoll: $!";
    $epoll::clients{fileno $client_socket}{"has_out"} = 1;
    print("Added client socket to writeepoll\n");

    main::handle_filestream(fileno $client_socket);
}
1;