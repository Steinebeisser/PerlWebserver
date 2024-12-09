package user_utils;

use strict;
use warnings;
use User::User;
use JSON;
use URI::Escape;

my $empty_cookie = "username=; expires=Thu, 01 Jan 1970 00:00:00 GMT";


sub get_username {
    if ($main::user) {
        # print("User logged in\n");
        # print("USERNAME: $main::user->{username}\n");
        if (is_encoded($main::user->{username})) {
            # print("FOUND USERNAME: $main::user->{username}\n");
            return decode_uri($main::user->{username});
        }
        # print("FOUND USERNAME: $main::user->{username}\n");
        return $main::user->{username};
    } else {
        # print("User not logged in\n");
    }
    return undef;  
}

sub get_password {
    if ($main::user) {
        # print("User logged in\n");
        return $main::user->{password};
    } else {
        # print("User not logged in\n");
    }
    return undef;  
}

sub get_username_and_role {
    my ($filename) = @_;
    my $username = get_username_from_filename($filename);

    my $role = get_user_stat($username, "role");

    return ($username, $role);
}

sub get_username_from_filename {
    my ($filename) = @_;
    # print("FILENAME123: $filename\n");
    return substr($filename, 9, -6);
}

sub get_role {
    if ($main::user) {
        # print("User logged in\n");
        return $main::user->{role};
    } else {
        # print("User not logged in\n");
    }
    return undef;  
}

sub get_all_users2 {
    if ($main::user) {
        my $role = user_utils::get_role();
        if ($role ne "admin") {
            return 0;
        }
    } else {
        return 0;
    }
    my @users = ();
    foreach my $folder (glob("UserData/*")) {
        # print("FOLDER123: $folder\n");
        my $username =~ /UserData\/(.*)/;
        my $filename = $folder . "/" . $username . ".json";
        my ($username2, $role) = get_username_and_role($filename);
        if (!$username2 ne $username) {
            # print("ERROR: $username2 ne $username\n");
            die;
        }
        push @users, { username => $username, role => $role };
    }
    return @users;
}

sub get_all_users {
    my ($start_index, $user_per_page) = @_;
    
    if ($main::user) {
        my $role = user_utils::get_role();
        if ($role ne "admin") {
            return 0;
        }
    } else {
        return 0;
    }

    my @users = ();
    my $count = 0;
    
    foreach my $folder (glob("UserData/*")) {
        $folder =~ /UserData\/(.*)/;
        my $username = $1;
        my $filename = $folder . "/" . $username . ".json";

        if ($count < $start_index) {
            $count++;
            next;
        }

        last if @users >= $user_per_page;

        my ($role) = get_user_stat($username, "role");
        push @users, { username => $username, role => $role };

        # my ($username2, $role) = get_username_and_role($filename);
        # if (!$username2 ne $username) {
        #     print("ERROR: $username2 ne $username\n");
        #     die;
        # }

        # if ($count >= $start_index && $count < $start_index + $user_per_page) {
        #     push @users, { username => $username, role => $role };
        # }
        # $count++;
        
    }

    return @users;
}


sub check_if_admin_and_logged_in {
    my ($client_socket) = @_;
    if (!$main::user) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_401("You are not logged in<br><a href=\"/ \">Return to index</a><br><a href=\"/login\">Login</a>"));
        return 0;
    } 
    my $role = get_role();
    if ($role ne "admin") {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_401("You are not an admin<br><a href=\"/ \">Return to index</a><br><a href=\"/login\">Login</a>"));
        return 0;
    }
    else {
        return 1;
    }
}

sub check_permissions {
    my ($client_socket, $username) = @_;

    if (is_banned($client_socket, $username)) {
        return 0;
    }

    if (!is_account($username)) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_401_WITH_COOKIE("Account does not exist<br><a href=\"/ \">Return to index</a><br><a href=\"/login\">Login</a>", $empty_cookie));
        return 0;
    }

    return 1;
}

sub is_account {
    my ($username) = @_;
    
    # print("USERNAME1: $username\n");
    if (!$username) {
        eval {
            $username = get_username();
        } or do {
            return 0;
        };
        my $data = get_json_data($username);
        if (!$data) {
            return 0;
        }
    }
    

    $username = check_uri_and_decode_encode($username);
    # print("USERNAME4: $username\n");

    if (!-e "UserData/$username/$username.json") {
        # print("UserData/$username/$username.json does not exist\n");
        # print("Account does not exist\n");
        return 0;
    }
    return $username;
}

sub check_uri_and_decode_encode {
    my ($username) = @_;
    my $username_encode;
    my $username_decode;


    if (!-e "UserData/$username/$username.json") {
        $username_encode = encode_uri($username);
        # print("USERNAME2: $username_encode\n");
        if (-e "UserData/$username_encode/$username_encode.json") {
            $username = $username_encode;
        }
    }

    if (!-e "UserData/$username/$username.json" && !$username_encode) {
        $username_decode = decode_uri($username);
        # print("USERNAME3: $username_decode\n");
        if (-e "UserData/$username_decode/$username_decode.json") {
            $username = $username_decode;
        }
    }

    return $username;
}
sub is_banned {
    # print("BANE TEST\n");
    my ($client_socket, $username) = @_;

    if (!$username) {
        # print("Trying to get username...\n");
        eval {
            $username = get_username();
            # print("POGGERS: Got username - $username\n");
        } or do {
            # print("Catch block executed: $!\n");
            http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_500("Failed to check your permissions"));
            return 1;
        };
        
    }

    # my $username = get_username();
    my $data = get_json_data($username);

    if (!$data) {
        return 0;
    }

    if ($data->{banned}->{status} eq "0") {
        return 0;
    }

    if ($data->{banned}->{banned_until} < time()) {
        unban_user($username);
        return 0;
    }

    http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_401_WITH_COOKIE("You are banned until " . parse_time($data->{banned}->{banned_until}) . "<br>Reason: " . $data->{banned}->{reason} . "<br><a href=\"/ \">Return to index</a><br><a href=\"/login\">Login</a>", $empty_cookie));
    return 1;
}

sub get_all_roles {
    my @roles = ();
    foreach my $filename (glob("User/Roles/*.pm"))
    {
        # print("FILENAME: $filename\n");
        if ($filename =~ /User\/Roles\/(.*)\./) {
            my $role = $1;
            push @roles, $role;
        } else {
            push @roles, "ERROR FETCHING ROLE";
        }
    }
    return @roles;
}

sub update_user_values {
    my ($username, $key, $value) = @_;
    my $filename = "UserData/$username/$username.json";
    my $data = get_json_data($username);
    $data->{$key} = $value;
    my $json = encode_json($data);
    open(my $file, '>', $filename) or return 0;
    print $file $json;
    close($file);
    return 1;
}

sub get_user_stat {
    my ($username, $key) = @_;
    # print("USERNAME: $username\n");
    my $data = get_json_data($username);
    if (!$data) {
        # print("CANT FETCH DATA FOR $username\n");
        return 0;
    }
    if (!$data->{$key}) {
        # print("CANT FETCH DATA FOR $username\n");
        return 0;
    }
    return $data->{$key};
}

sub get_json_data {
    my ($username) = @_;

    $username = is_account($username);
    if (!$username) {
        return 0;
    }

    my $filename = "UserData/$username/$username.json";
    open(my $file, '<', $filename) or do {
        # print("Error opening file $filename\n");
        return 0;
    };
    my $json_text = do {
        local $/;
        <$file>
    };
    close($file);
    my $data = eval { decode_json($json_text) };
    if ($@) {
        # print("Error decoding JSON: $@\n");
        return 0;
    }
    return $data;
}

sub compare_values {
    my ($username, $key, $value) = @_;
    my $data = get_json_data($username);
    if (!$data) {
        return 0;
    }
    if ($data->{$key} eq $value) {
        return 1;
    }
    return 0;
}

sub ban_user {
    my ($username, $reason, $time_until) = @_;

    my $data = get_json_data($username);

    if (!$data) {
        return 0;
    }


    $data->{banned}->{status} = "1";
    $data->{banned}->{reason} = $reason;
    $data->{banned}->{banned_until} = $time_until;

    write_json_data($username, $data);
}

sub unban_user {
    my ($username) = @_;

    my $data = get_json_data($username);

    if (!$data) {
        return 0;
    }

    $data->{banned}->{status} = "0";
    $data->{banned}->{reason} = "";
    $data->{banned}->{banned_until} = 0;

    write_json_data($username, $data);
}

sub write_json_data {
    my ($username, $data) = @_;
    my $filename = "UserData/$username/$username.json";
    open(my $file, '>', $filename) or return 0;
    print $file encode_json($data);
    close($file);
    return 1;
}

sub parse_time {
    my ($time) = @_;
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($time);
    
    return sprintf("%02d.%02d.%04d %02d:%02d:%02d", $mday, $mon + 1, $year + 1900, $hour, $min, $sec); 
}

sub is_encoded {
    my ($string) = @_;
    if (!$string) {
        return 0;
    }
    if ($string =~ /%[0-9A-Fa-f]{2}/) {
        return 1;
    }
    return 0;
}

sub decode_uri {
    my ($uri) = @_;
    $uri = uri_unescape($uri);
    return $uri;
}

sub delete_user {
    my ($username) = @_;
    # print("DELETING USER: $username\n");
    $username = is_account($username);
    if (!$username) {
        return 0;
    }
    # print("DELETING USER: $username\n");
    my $role = get_user_stat($username, "role");
    if ($role eq "admin") {
        return 0;
    }
    
    my $start_dir = "UserData/$username";
    delete_files_recursive($username, $start_dir);

    my $filename = "UserData/$username/$username.json";
    unlink($filename);
}

sub delete_files_recursive {
    my ($username, $path) = @_;

    opendir(my $dir, $path) or return 0;

    while (my $file = readdir($dir)) {
        if ($file eq "." || $file eq "..") {
            next;
        }
        my $path = "$path/$file";
        if (-d $path) {
            delete_files_recursive($username, $path);
        } else {
            unlink($path);
        }
    }
    rmdir($path);
}

sub check_if_user_exists {
    my ($client_socket, $username) = @_;
    $username = is_account($username);
    if (!$username) {
    my $html_body = <<HTML;
    <h1>User $username does not exist</h1>
    <br>
HTML
        $html_body .= admin_utils::return_buttons();
        my $html_content = html_structure::get_html($html_body, "User does not exist");
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_404($html_content));
        return 0;
    }
    return 1;
}

sub encode_uri {
    my ($uri) = @_;
    $uri = uri_escape($uri);
    return $uri;
}

sub get_user_count {
    my $count = 0;
    # print("COUNTING USERS\n");

    foreach my $folder (glob("UserData/*")) {
        $count++;
    }
    return $count;
}

sub get_uploads {
    my @uploads = ();
    if (!$main::user) {
        return 0;
    }
    my $data_path = "UserData/$main::user->{username}/ploud";

    foreach my $file (glob("$data_path/*")) {
        
        if (!-d $file) {
            next;
        }
        # print("FILE: $file\n");
        my $filename = $file;
        $filename =~ s/$data_path\///;
        # print("DATA_PATH: $data_path\n");
        # print("FILENAME: $filename\n");
        push @uploads, $filename;
    }
    return @uploads;
}

sub get_metadata {
    my ($filename) = @_;
    # print("METADATACHECK: $filename\n");
    my $data_path = "UserData/$main::user->{username}/ploud/$filename/metadata.json";
    open(my $file, '<', $data_path) or return 0;
    # print("OPENED FILE: $file\n");
    my $json = <$file>;
    # print("JSON: $json\n");
    close $file;
    if (!$json) {
        return 0;
    }
    my $metadata = decode_json($json);
    # print("METADATA: $metadata\n");
    return $metadata;
}

sub format_bytes {
    my ($bytes) = @_;
    if ($bytes eq "Unknown") {
        return "Unknown";
    }
    if ($bytes >= 1024 * 1024 * 1024) {
        return sprintf("%.2f GB", $bytes / (1024 * 1024 * 1024));
    } elsif ($bytes >= 1024 * 1024) {
        return sprintf("%.2f MB", $bytes / (1024 * 1024));
    } elsif ($bytes >= 1024) {
        return sprintf("%.2f KB", $bytes / 1024);
    } else {
        return "$bytes B";
    }
}

sub get_current_used_storage {
    my ($username) = @_;
    if (!$username) {
        $username = get_username();
    }
    $username = is_account($username);
    my $used_storage = 0;
    # print("GETTING USED STORAGE\n");
    my $data_path = "UserData/$username/ploud/usermetadata.json";
    if (!-e $data_path) {
        # print("File does not exist: $data_path\n");
        return 0;
    }
    if (!-r $data_path) {
        # print("File is not readable: $data_path\n");
        return 0;
    }
    open(my $file, '<', $data_path) or do {
        # print("Error opening file $data_path: $!\n");
        return 0;
    };
    my $json = <$file>;
    close $file;
    my $data = decode_json($json);
    # print("USERMETADATA: $data\n");
    # print("DATA: $data\n");
    $used_storage = $data->{used_storage};
    return $used_storage;
}

sub get_user_max_storage {
    my ($username) = @_;

    my $user_stats = user_utils::get_json_data($username);
    if (!$user_stats) {
        return "User not found";
    }
    my $max_storage = $user_stats->{rank}{benefits}{max_storage};
    if (!$max_storage) {
        $max_storage = $main::max_storage
    }
    return $max_storage;
}
sub update_user_metadata {
    my ($username, $data) = @_;
    my $filename = "UserData/$username/ploud/usermetadata.json";
    my $current_storage = 0;
    my $metadata;

    # print("FILENAME: $filename\n");
    # print("UPDATIN METADATA: $data->{size}\n");

    open (my $file, '<', $filename) or do {
        # print("Error opening file $filename\n");
    };
    my $json = <$file>;
    close $file;
    if ($json) {
        $metadata = decode_json($json);
        $current_storage = $metadata->{used_storage};
    }
    if ($data->{subtract}) {
        $current_storage -= $data->{size};
    } else {
        $current_storage += $data->{size};
    }
    $metadata->{used_storage} = $current_storage;


    open($file, '>', $filename) or return 0;
    print $file encode_json($metadata);
    close($file);
    return 1;
}

sub get_rank_stats {
    my ($rank_id, $key) = @_;

    my $filename = "Utils/ranks.json";

    open(my $file, '<', $filename) or do {
        # print("Error opening file $filename\n");
        return 0;
    };

    my $json = do { local $/; <$file> };
    close $file;
    my $data = decode_json($json);

    

    return $data->{$rank_id}->{$key};

}

sub get_rank_id {
    my ($rank) = @_;

    my $filename = "user_Utils/ranks.json";

    open(my $file, '<', $filename) or do {
        # print("Error opening file $filename\n");
        return 0;
    };

    my $json = do { local $/; <$file> };
    close $file;
    my $data = decode_json($json);

    foreach my $rank_id (keys %$data) {
        if ($data->{$rank_id}->{name} eq $rank) {
            return $rank_id;
        }
    }
    return 0;
}

sub update_rank_stats {
    my ($username, $key, $value) = @_;

    my $userdata = get_json_data($username);


    my $rank_data = $userdata->{rank};
    if (!$rank_data) {
        serve_error(HTTP_RESPONSE::ERROR_500("Could not fetch rank data"));
        return 0;
    }
    if ($key eq "max_storage" || $key eq "storage_used") {
        # print("UPDATING RANK BENEFITS\n");
        # print("KEY: $key\n");
        # print("VALUE: $value\n");
        # print("UPDATING $userdata->{rank}{benefits}{$key} TO $value\n");
        $userdata->{rank}{benefits}{$key} = $value;
    } else {
        $userdata->{rank}{$key} = $value;
    }

    open (my $file, '>', "UserData/$username/$username.json") or return 0;
    print $file encode_json($userdata);
    close($file);
    return 1;
}

sub read_file {
    my ($filename) = @_;
    $filename =~ s|\\|/|g;
    $filename =~ s/\r\n$//; 
    $filename =~ s/\n$//;
    $filename =~ s/\r$//;
    # print("FILENAME: $filename HELLO");
    open(my $file, '<', $filename) or do {
        print("Error opening file $filename: $!\n");
        return 0;
    };
    my $content = do { local $/; <$file> };
    close $file;
    return $content;
}

sub write_file {
    my ($filename, $content) = @_;
    open(my $file, '>', $filename) or do {
        # print("Error opening file $filename\n");
        return 0;
    };
    print $file $content;
    close $file;
    return 1;
}

sub create_random_string {
    my ($length) = @_;

    my @chars = ('a'..'z', 'A'..'Z', '0'..'9');
    my $string = join '', @chars[ map { rand @chars } 1..$length ];
    return $string;
}

sub populate_user {
    my ($cookie) = @_;


    if ($cookie =~ /username=([^\s;]+)/) {
        my $username = $1;
        # print "Username: $username\n";
        my $user_stats = get_user_stats($username);
        if (!$user_stats) {
            return;
        }
        $main::user = User->new($user_stats);
        
        # $main::user = $user;
        # print("ROLI $user->{role}\n");
        # print("ROLI $main::user->{role}\n");
    };
}

sub get_user_stats {
    my ($username) = @_;
    my $filename = "UserData/$username/$username.json";

    if (-e $filename) {
        open(my $file, '<', $filename) or return 0;
        my $json = do { local $/; <$file>};
        close $file;
        my $user_stats = decode_json($json);

        return $user_stats;
    }
}


1;