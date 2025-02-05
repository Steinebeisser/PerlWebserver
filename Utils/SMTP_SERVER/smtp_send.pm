package smtp_send;

use strict;
use warnings;

use Socket;

sub send_email {
    my ($from, $to, $subject, $message, $content_type, $smtp_server, $smtp_port, $client_fd, $srs_from, $username, $to_username) = @_;
    # print("SENDING EMAIL\n");

    if (!$smtp_server) {
        $smtp_server = "localhost";
    }
    if (!$smtp_port) {
        $smtp_port = 25;
    }

    if (!$srs_from) {
        $srs_from = $from;
    }

    if (!$username) {
        $username = $from;
    }

    if (!$to_username) {
        $to_username = $to;
    }

    if (!$content_type) {
        $content_type = "Content-Type: text/html; charset=UTF-8";
    }

    socket(my $smtp_socket, AF_INET, SOCK_STREAM, 0);
    connect($smtp_socket, sockaddr_in($smtp_port, inet_aton($smtp_server))) || do {
        # print("Can't connect to SMTP server: $!\n");
        return;
    };
    # print("Connected to SMTP server\n");

    recv($smtp_socket, my $greeting, 1024, 0);
    # print("RECEIVED GREETING: $greeting\n");
    if ($greeting !~ /^220/) {
        if (!smtp_utils2::try_with_gmail($client_fd, $greeting, $client_fd)) {
            smtp_utils2::return_to_sender($client_fd, $greeting, $client_fd);
        }
    }
    smtp_utils2::send_and_receive($smtp_socket, "EHLO localhost", $client_fd);
    # smtp_utils2::send_and_receive($smtp_socket, "MAIL FROM:<$srs_from>", $client_fd);
    smtp_utils2::send_and_receive($smtp_socket, "MAIL FROM:<$srs_from>", $client_fd);
    smtp_utils2::send_and_receive($smtp_socket, "RCPT TO:<$to>", $client_fd);
    smtp_utils2::send_and_receive($smtp_socket, "DATA", $client_fd);
    my $message_id = "<" . time() . "." . $$ . "\@" . "sinc.de" . ">";
    smtp_utils2::send_msg($smtp_socket, "Message-ID: $message_id");   
    smtp_utils2::send_msg($smtp_socket, "Subject: $subject\r\nFrom: \"$username\" <$from> \r\nTo: \"$to_username\" <$to>\r\n$content_type\r\n\r\n$message");
    # print("EMAIL MSG: Subject: $subject\r\nFrom: \"$username\" <$from>\r\nTo: \"$to_username\" <$to>\r\n$content_type\r\n\r\n$message\n");
    smtp_utils2::send_and_receive($smtp_socket, "\r\n.", $client_fd);
    smtp_utils2::send_and_receive($smtp_socket, "QUIT", $client_fd);

    # print("WHOLE EMAIL\n");
    # print("Subject: $subject\r\nFrom: $from\r\nTo: $to\r\n\r\n$message\n");
    # print("Sent email\n");
    close($smtp_socket);
}

sub send_without_ehlo {
    my ($from, $to, $subject, $message, $smtp_server, $smtp_port, $client_fd) = @_;
    # print("SENDING EMAIL\n");

    if (!$smtp_server) {
        return;
    }
    smtp_utils2::send_and_receive($smtp_server, "MAIL FROM:<$from>", $client_fd);
    smtp_utils2::send_and_receive($smtp_server, "RCPT TO:<$to>", $client_fd);
    smtp_utils2::send_and_receive($smtp_server, "DATA", $client_fd);
    my $message_id = "<" . time() . "." . $$ . "\@" . "localhost" . ">";
    smtp_utils2::send_msg($smtp_server, "Message-ID: $message_id");
    smtp_utils2::send_msg($smtp_server, "Subject: $subject\r\nFrom: $from\r\nTo: $to\r\n\r\n$message");
    smtp_utils2::send_and_receive($smtp_server, "\r\n.", $client_fd);
    smtp_utils2::send_and_receive($smtp_server, "QUIT", $client_fd);

    # print("Sent email\n");
    close($smtp_server);
}
1;