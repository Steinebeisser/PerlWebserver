package email_utils;

use strict;
use warnings;
use Cwd;
use JSON;

$email::verification_links = {};

sub create_email_verification_link {
    my ($email, $username) = @_;

    my $base_dir = getcwd();
    my $EmailFolder = "$base_dir/Data/UserData/EmailVerification";
    if (!-d $EmailFolder) {
        mkdir $EmailFolder or do {
            warn "Cannot create folder: $!";
            return;
        };
    }
    my $random_verify_id = user_utils::create_random_string(20);
    my $filename = "$EmailFolder/$random_verify_id";
    my $link = "10.31.0.18/verify/email/$random_verify_id";
    
    my $timeout = 15 * 60 * 24;
    my $timeout_timestamp = time() + $timeout;
    print("LINK: $link\n");
    open my $fh, '>', $filename or do {
        warn "Cannot open file: $!";
        return;
    };
    print $fh "Link: $link\n";
    print $fh "Username: $username\n";
    print $fh "Email: $email\n";
    print $fh "Timestamp: $timeout_timestamp\n";
    close $fh;

    add_to_email_router($email, $link);
}

sub add_to_email_router {
    my ($email, $link) = @_;

    print("SENDING EMAIL\n");
    my $html_email = <<HTML;
<!DOCTYPE html>
<html>
  <body>
    <p>Klicken Sie auf den folgenden Link, um Ihre E-Mail zu verifizieren:</p>
    <a href="$link" target="_blank">
      E-Mail verifizieren
    </a>
    <p>Falls der Link nicht klickbar ist, kopieren Sie die folgende URL und fügen Sie sie in Ihren Browser ein:</p>
    <p>$link</p>
    <br>
    <br>
    <br>
    <p>Falls Sie diese E-Mail nicht angefordert haben, ignorieren Sie diese E-Mail.</p>
  </body>
</html>
HTML
    my $content_type = "Content-type: text/html; charset=UTF-8\n";
    smtp_send::send_email("verify\@aioperl.com", $email, "Email Verification", $html_email, $content_type);
    $email::verification_links->{$link} = $email;
}

sub is_verification_link_valid {
    my ($email, $link) = @_;

    my $base_dir = getcwd();
    my $UserDataFolder = "$base_dir/Data/UserData";
    my $filename = "$UserDataFolder/EmailVerification/$link";
    
    open my $fh, '<', $filename or do {
        warn "Cannot open file: $!";
        return;
    };
    my $line = <$fh>;
    close $fh;
    my ($link, $username, $email, $timestamp) = split('\n', $line);
    my $current_timestamp = time();
    if ($timestamp < $current_timestamp) {
        return 1;
    }
    return 0;
}


sub handle_email_verification {
    my ($client_socket, $request, $route) = @_;

    my $used_emails = user_utils::get_used_emails();
    my $base_dir = getcwd();
    my $EmailFolder = "$base_dir/Data/UserData/EmailVerification";
    print("REQUEST: $request\n");
    my ($verification_link) = $request =~ /verify\/email\/(.*) HTTP/; 
    my $filename = "$EmailFolder/$verification_link";
    print("FILENAME: $filename\n");
    open my $fh, '<', $filename or do {
        warn "Cannot open file: $!";
        return;
    };
    my @lines = <$fh>;
    close $fh;
    my %data;
    foreach my $line (@lines) {
        if ($line =~ /^Link: (.*)$/) {
            $data{link} = $1;
        } elsif ($line =~ /^Username: (.*)$/) {
            $data{username} = $1;
        } elsif ($line =~ /^Email: (.*)$/) {
            $data{email} = $1;
        } elsif ($line =~ /^Timestamp: (.*)$/) {
            $data{timestamp} = $1;
        }
    }

    if ($used_emails->{$data{email}}) {
        return "Email already verified\nUnbinding email<br><a href=\"\/add/email\">Add email</a><br><a href=\"/ \">Return to index</a>";
    }
    my $expire_timestamp = $data{timestamp};
    my $current_timestamp = time();
    print("TIMESTAMP: $data{timestamp}\n");
    print("CURRENT_TIMESTAMP: $current_timestamp\n");
    if ($expire_timestamp < $current_timestamp) {
        return "Email expired<br><a href=\"/ \">Return to index</a>";
    }
    my $response = "Email verified<br><a href=\"/ \">Return to index</a>";
    my $uuid = user_utils::get_uuid();
    user_utils::update_user_values($uuid, "email_status", "verified");
    $used_emails->{$data{email}} = $uuid;
    user_utils::save_used_emails($used_emails);
    return $response;
}

sub post_add_email {
    my ($client_socket, $request) = @_;

    my $body = request_utils::skip_to_body($request);
    my $json = decode_json($body);
    my $email = $json->{email};
    print($body);
    print("EMAIL: $email\n");
    if (!$email) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_500("Error fetching email, try again later"));
        return;
    }
    my $used_emails = user_utils::get_used_emails();

    if ($used_emails && $used_emails->{$email}) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_400("Email already verified, Try another one <a href=\"/\">Add email</a> <br>or logout <a href=\"/logout \">Logout</a>"));
        return;
    } elsif (!$used_emails) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_500("Error fetching email, try again later <a href=\"logout\">Logout</a>"));
        return;
    }

    user_utils::update_user_values($main::user->{uuid}, "email", $email);
    user_utils::update_user_values($main::user->{uuid}, "email_status", "pending");
    my $username = $main::user->{human_username};
    create_email_verification_link($email, $username);
}

sub post_unlink_email {
    my ($client_socket, $request) = @_;

    my $email = $main::user->{email};
    user_utils::update_user_values($main::user->{uuid}, "email", "");
    user_utils::update_user_values($main::user->{uuid}, "email_status", "");
    my $html = get_operation_finished_pages::get_email_unlinked($email);
    my $html_content = html_structure::get_html($html, "Email unlinked");
    return $html_content;
}

sub post_resend_verification_email {
    my ($client_socket, $request) = @_;

    my $email = $main::user->{email};
    my $username = $main::user->{human_username};
    create_email_verification_link($email, $username);
}
1;