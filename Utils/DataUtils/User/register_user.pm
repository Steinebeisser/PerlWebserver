package register_user;

use strict;
use warnings;

use Cwd;
use JSON;

sub post_register {
    my ($client_socket, $request) = @_;
    my $response;
    my $username;
    my $password; 
    my $accept_language = "en";
    
    if ($request =~ /username=(.*)&password=(.*)?/) {
        $username = $1;
        $password = $2;
    }
    if (length($username) > 24 || length($password) > 24) {
        my $response = HTTP_RESPONSE::ERROR_400("Username or password too long");
        return $response;
    }

    if (!$username || !$password) {
        my $response = HTTP_RESPONSE::ERROR_400();
        return $response;
    }

    if ($request =~ /Accept-Language: (.*)/) {
        $accept_language = $1;
    }

    if (register_user($username, $password, $client_socket, $accept_language)) {
        my $cookie = "username=$username";
        user_utils::populate_user($cookie);
        $response = HTTP_RESPONSE::OK_WITH_COOKIE(get_operation_finished_pages::get_registered_html($username), $cookie);
    } else {
        $response = HTTP_RESPONSE::OK("User already exists <a href=\"/register \">Try again</a>");
        # $response = HTTP_RESPONSE::ERROR_400("User already exists");
    }
    http_utils::send_http_response($client_socket, $response);
}


sub register_user {
    my ($username, $password, $client_socket, $accept_language) = @_;
    my $base_dir = getcwd();
    my $UserDataFolder = "$base_dir/UserData";
    my $foldername = "$UserDataFolder/$username";
    my $filename = "$UserDataFolder/$username/$username.json";
    if (!-d $UserDataFolder) {
        mkdir $UserDataFolder or return 0;
    }
    if (!-d $foldername) {
        mkdir $foldername or return 0;
    }


    if (-e $filename) {
        return 0;
    }

    my $max_storage = user_utils::get_rank_stats(0, "benefits")->{max_storage};
    if (!$max_storage) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_500("Error Setting up user"));
    }
    print("MAX STORAGE: $max_storage\n");
    my %user_data = (
        username => $username,
        password => $password,
        preferences => {
            language => $accept_language
        },
        role => "user",
        banned => {
            status => 0,
            reason => "",
            banned_until => 0
        },
        friends_only_uuids => {},
        friends => {},
        friend_requests => {},
        friend_requests_sent => {},
        posts => {},
        comments => {},
        notifications => {},
        messages => {},
        rank => {
            name => "bronze",
            id => 0,
            benefits => {
                max_storage => user_utils::get_rank_stats(0, "benefits")->{max_storage},
                storage_used => 0,
            }
        },
    );

    my $json = encode_json(\%user_data);

    open(my $file, '>', $filename) or return 0;
    # print $file $password . "\n";
    # print $file "user\n";
    print $file $json . "\n";
    close $file;
    # $main::user = User->new($username, $password);
    return 1;
}


1;