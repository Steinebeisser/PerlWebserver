package channel_utils;

use strict;
use warnings;

use Cwd;
use JSON;

my %items = (
    "title" => \&update_video_title,
    "description" => \&update_video_description,
    "thumbnail" => \&update_video_thumbnail,
    "channel_icon" => \&update_channel_icon,
    "channel_banner" => \&update_channel_banner,
);

my %channel_items = (
    "channel_icon" => \&update_channel_icon,
    "channel_banner" => \&update_channel_banner,
    "about" => \&update_channel_about,
    "displayname" => \&update_channel_displayname,
);

my %categories = (
    "Videos" => \&update_video,
    "Channel" => \&update_channel,
);

my %categories_server_style = (
    "videos" => "Videos",
    "channel" => "Channel",
);
sub update_channel_item {
    my ($username, $category, $video_id, $update_item, $temp_file, $client_socket) = @_;


    my $category = $categories_server_style{$category};
    if (!has_manage_access(user_utils::get_uuid_by_username($username))) {
        return;
    }
    
    if (!$categories{$category}) {
        die;
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_404("Category not found"));
        return;
    }

    $categories{$category}->($username, $video_id, $update_item, $temp_file, $client_socket);
}

sub update_channel {
    my ($username, $video_id, $update_item, $temp_file, $client_socket) = @_;


    if (!$channel_items{$update_item}) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_404("Item not found"));
        return;
    }

    $channel_items{$update_item}->($username, $video_id, $update_item, $temp_file, $client_socket);
}

sub update_channel_displayname {
    my ($username, $video_id, $update_item, $temp_file, $client_socket) = @_;

    my $data = body_utils::load_temp_file($temp_file);
    my $json = decode_json($data);
    my $new_displayname = $json->{displayname};
    print("NEW DISPLAYNAME: $new_displayname\n");
    if (user_utils::is_wide($new_displayname)) {
        $new_displayname = user_utils::encode_uri($new_displayname);
    }
    
    
    my $old_displayname = user_utils::get_displayname_with_uuid($main::user->{uuid});

    if (!$new_displayname) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_400("Displayname not provided"));
        return;
    }

    if ($new_displayname eq $old_displayname) {
        return 1;
    }

    my $base_dir = getcwd();
    my $displayname_file = "$base_dir/Data/UserData/displaynames.json";
    if (!-e $displayname_file) {
        open my $fh, ">", $displayname_file;
        print $fh "{ \"displaynames\": {}, \"uuid_to_displayname\": {} }";
        close $fh;
    }

    open my $fh, "<", $displayname_file;
    $data = do { local $/; <$fh> };
    close $fh;

    $json = decode_json($data);
    my $displaynames = $json->{displaynames};
    my $uuid_to_displayname = $json->{uuid_to_displayname};

    if ($uuid_to_displayname->{$main::user->{uuid}}) {
        if ($displaynames->{$old_displayname}) {
            my $user = $displaynames->{$old_displayname};
            my @keeping_uuids;
            foreach my $uuid (@$user) {
                if ($uuid eq $main::user->{uuid}) {
                    next;
                }
                push @keeping_uuids, $uuid;
            }
            if (@keeping_uuids) {
                $displaynames->{$old_displayname} = \@keeping_uuids;
            } else {
                delete $displaynames->{$old_displayname};
            }
        }
    }

    if ($displaynames->{$new_displayname}) {
        push @{$displaynames->{$new_displayname}}, $main::user->{uuid};
    } else {
        $displaynames->{$new_displayname} = [$main::user->{uuid}];
    }

    $uuid_to_displayname->{$main::user->{uuid}} = $new_displayname;

    open my $fh, ">", $displayname_file;
    print $fh encode_json($json);
    close $fh;
}

my %update_video_items = (
    "title" => \&update_video_title,
    "description" => \&update_video_description,
    "thumbnail" => \&update_video_thumbnail,
    "enable" => \&enable_video,
    "disable" => \&disable_video,
    "private" => \&make_video_private,
    "public" => \&make_video_public,
    "delete" => \&delete_video,
);

sub update_video {
    my ($category_folder, $video_id, $update_item, $temp_file, $client_socket) = @_;
    my $video_file = "$category_folder/$video_id";
    if (!-e $video_file) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_404("Video not found"));
        return;
    }

    # print("CLIENT SOCKET: $client_socket\n");

    $update_video_items{$update_item}->($video_file, $temp_file, $client_socket);
}

sub enable_video {
    my ($video_file, $temp_file, $client_socket) = @_;

    my $meta_data_file = "$video_file/metadata.json";
    open my $fh, "<", $meta_data_file;
    my $data = do { local $/; <$fh> };
    close $fh;
    # print("DATA: $data\n");
    my $json = decode_json($data);
    # print("JSON: $json\n");
    open my $fh, ">", $meta_data_file;
    $json->{enabled} = 1;
    print $fh encode_json($json);
    close $fh;
}

sub update_video_title {
    my ($video_file, $temp_file, $client_socket) = @_;

    my $data = body_utils::load_temp_file($temp_file);
    my $json = decode_json($data);
    my $new_title = $json->{video_title};
    # print("NEW TITLE: $new_title\n");
    if (!$new_title) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_400("Title not provided"));
        return;
    }
    my $meta_data_file = "$video_file/metadata.json";
    open my $fh, "<", $meta_data_file;
    my $data = do { local $/; <$fh> };
    close $fh;
    my $json = decode_json($data);
    $json->{title} = $new_title;
    open my $fh, ">", $meta_data_file;
    print $fh encode_json($json);
    close $fh;
}

sub update_video_description {
    my ($video_file, $temp_file, $client_socket) = @_;

    my $data = body_utils::load_temp_file($temp_file);
    my $json = decode_json($data);
    my $new_description = $json->{video_description};
    # print("NEW DESCRIPTION: $new_description\n");
    if (!$new_description) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_400("Description not provided"));
        return;
    }
    my $meta_data_file = "$video_file/metadata.json";
    open my $fh, "<", $meta_data_file;
    my $data = do { local $/; <$fh> };
    close $fh;
    my $json = decode_json($data);
    $json->{description} = $new_description;
    open my $fh, ">", $meta_data_file;
    print $fh encode_json($json);
    close $fh;
}

sub disable_video {
    my ($video_file, $temp_file, $client_socket) = @_;

    my $meta_data_file = "$video_file/metadata.json";
    open my $fh, "<", $meta_data_file;
    my $data = do { local $/; <$fh> };
    close $fh;
    # print("DATA: $data\n");
    my $json = decode_json($data);
    # print("JSON: $json\n");
    open my $fh, ">", $meta_data_file;
    $json->{enabled} = 0;
    print $fh encode_json($json);
    close $fh;
}

sub make_video_public {
    my ($video_file, $temp_file, $client_socket) = @_;

    my $meta_data_file = "$video_file/metadata.json";
    open my $fh, "<", $meta_data_file;
    my $data = do { local $/; <$fh> };
    close $fh;
    # print("DATA: $data\n");
    my $json = decode_json($data);
    # print("JSON: $json\n");
    open my $fh, ">", $meta_data_file;
    $json->{private} = 0;
    print $fh encode_json($json);
    close $fh;
}

sub make_video_private {
    my ($video_file, $temp_file, $client_socket) = @_;

    my $meta_data_file = "$video_file/metadata.json";
    open my $fh, "<", $meta_data_file;
    my $data = do { local $/; <$fh> };
    close $fh;
    # print("DATA: $data\n");
    my $json = decode_json($data);
    # print("JSON: $json\n");
    open my $fh, ">", $meta_data_file;
    $json->{private} = 1;
    print $fh encode_json($json);
    close $fh;
}

sub delete_video {
    my ($video_file, $temp_file, $client_socket) = @_;

    my ($channel_uuid) = $video_file =~ /\/Data\/UserData\/Users\/(.*)\/Streaming\/Videos\/(.*)/; 
    my $channel_name = user_utils::get_username_by_uuid($channel_uuid);
    if (!$channel_name) {
        # print("no channel name\n");
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_500("Failed to delete video"));
        return;
    }
    if(!user_utils::delete_files_recursive($video_file)) {
        # print("FAILED TO DELETE VIDEO\n");
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_500("Failed to delete video"));
        return;
    } else {
        remove_from_index($video_file);
        # print("DELETED VIDEO\n");
        # print("CLIENT SOCKET: $client_socket\n");
        # print("HTTP RESPONSE: " . HTTP_RESPONSE::REDIRECT_303("/streaming/manage/channel/$channel_name/videos") . "\n");
        http_utils::send_http_response($client_socket, HTTP_RESPONSE::REDIRECT_303("/streaming/manage/channel/$channel_name/videos"));
        return;
    }
}

sub remove_from_index {
    my ($video_file) = @_;

    my $base_dir = getcwd();
    my ($user_path) = $video_file =~ /(.*)\/Videos/;
    # print("VIDEO FILE: $video_file\n");
    $video_file =~ s/$base_dir\///;
    my $meta_data_file = "$video_file/metadata.json";
    # print("VIDEO FILE: $video_file\n");
    # print("USER PATH: $user_path\n");
    my $index_file = "$user_path/videos.txt";
    my @videos;
    open my $fh, "<", $index_file;
    while (my $line = <$fh>) {
        chomp $line;
        if ($line eq $meta_data_file) {   
            next;
        }
        push @videos, $line;
    }
    close $fh;
    open my $fh, ">", $index_file;
    foreach my $video (@videos) {
        print $fh "$video\n";
    }
    close $fh;
}

sub has_manage_access {
    my ($manage_uuid) = @_;

    if (!$main::user) {
        return 0;
    }

    if ($main::user->{uuid} eq $manage_uuid) {
        return 1;
    }

    return 0;
}

1;