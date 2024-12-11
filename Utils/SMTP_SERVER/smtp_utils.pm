package smtp_utils;

use strict;
use warnings;

use threads;
use Socket;
use Cwd;
use IO::Epoll;
use Net::DNS qw(mx);

my $max_conn = 5;

$smtp::epoll = epoll_create(1024) or die "Failed to create epoll: $!";

sub start_smtp_server {
    my $server_thread = threads->create(\&run_smtp_server);
    $server_thread->detach();
}

sub run_smtp_server {
    setup_smtp_server();
    print("Running SMTP server\n");
    epoll_loop();
}
my $smtp_server;

sub setup_smtp_server {
    print("Setting up SMTP server\n");

    print("Starting SMTP server\n");
    socket($smtp_server, AF_INET, SOCK_STREAM, 0);

    print("Setting socket options\n");
    setsockopt($smtp_server, SOL_SOCKET, SO_REUSEADDR, 1) || die "Can't set socket options: $!";
    
    print("Binding to port 25\n");
    bind($smtp_server, sockaddr_in(25, INADDR_ANY)) || die "Can't bind to port 25: $!";

    print("Listening on port 25\n");
    listen($smtp_server, $max_conn) || die "Can't listen: $!";

    epoll_ctl($smtp::epoll, EPOLL_CTL_ADD, fileno $smtp_server, EPOLLIN) >= 0 or die "Failed to add server to epoll: $!";
}

sub epoll_loop {
    print("Starting epoll loop\n");
    while (1) {
        my $events = epoll_wait($smtp::epoll, 10, -1);
        # print("Waiting for SMTP events\n");

        for my $event (@$events) {
            my $fd = $event->[0];
            if ($fd == fileno $smtp_server) {
                accept(my $smtp_client_socket, $smtp_server);
                my $client_fd = fileno $smtp_client_socket;
                $smtp::clients{$client_fd} = {};
                $smtp::clients{$client_fd}{"smtp_socket"} = $smtp_client_socket;
                print("CLIENT FD 1: $client_fd\n");
                print("CLIENT SOCKET 1: $smtp_client_socket\n");
                $smtp::clients{$client_fd}{"read"} = "done";
                $smtp::clients{$client_fd}{"buffer"} = "";
                print("Accepted client\n");
                greet_client($client_fd);
                epoll_ctl($smtp::epoll, EPOLL_CTL_ADD, fileno $smtp_client_socket, EPOLLIN) >= 0 || die "Can't add client socket to smtp::epoll: $!";
                print("Added client to epoll\n");
            } else {
                # print("Handling client\n");
                handle_client($event->[0]);
            }
        }
    }
}

sub greet_client {
    my ($client_fd) = @_;
    send_msg($client_fd, "220 Welcome to SMTP server");
    print("greeted client\n");
}
sub handle_client {
    my ($client_fd) = @_;
    my $client_socket = $smtp::clients{$client_fd}{"smtp_socket"};

    my $buffer;
    if ($smtp::clients{$client_fd}{"read"} eq "not done") {
        print("RECEIVING MSG\n");
        receive_msg($client_socket);
        return;
    } else {
        print("RECEIVING BUFFER\n");
        recv($client_socket, $buffer, 1024, 0);

    }

    # if (!$buffer) {
    #     print("Client $client_fd disconnected\n");
    #     remove_client($client_fd);
    #     return;
    # }

    # Append to client's buffer
    $smtp::clients{$client_fd}{buffer} .= $buffer;

    print("REQUEST BUFFER: $smtp::clients{$client_fd}{buffer}\n");
    # Process complete lines
    while ($smtp::clients{$client_fd}{buffer} =~ s/^(.*?)\r\n//) {
        my $line = $1;
        process_msg($client_fd, $line);
    }
}

sub process_msg {
    my ($client_fd, $line) = @_;
    print("Client $client_fd sent: $line\n");

    if ($smtp::clients{$client_fd}{"EOD"} || $line =~ /^\./) {
        print("EOD\n");
        send_msg($client_fd, "250 OK");
        $smtp::clients{$client_fd}{"EOD"} = 0;
        $smtp::clients{$client_fd}{"read"} = "done";
    } elsif ($line =~ /^EHLO (.*)/) {
        my $name = $1;
        $smtp::clients{$client_fd}{"name"} = $name;
        send_msg($client_fd, "250 Hello from SMTP server");
    } elsif ($line =~ /^MAIL FROM:<?(.*)?<(.*\w)>?>/) {
        my $from = $1;
        my $from_email = $2;
        $smtp::clients{$client_fd}{"from"} = $from;
        $smtp::clients{$client_fd}{"from_email"} = $from_email;
        send_msg($client_fd, "250 OK");
    } elsif ($line =~ /^RCPT TO:<?(.*)?<(.*\w)>?>/) {
        my $to = $1;
        my $to_email = $2;
        $smtp::clients{$client_fd}{"to"} = $to;
        $smtp::clients{$client_fd}{"to_email"} = $to_email;
        send_msg($client_fd, "250 OK");
    } elsif ($line =~ /^DATA/) {
        send_msg($client_fd, "354");
        $smtp::clients{$client_fd}{"read"} = "not done";
    } elsif ($line =~ /^QUIT/) {
        print("Client $client_fd quit\n");
        send_msg($client_fd, "221 Goodbye");
        build_email($client_fd);
        send_to_recipient($client_fd);
        remove_client($client_fd);
    } else {
        print("Unrecognized command: $line\n");
        send_msg($client_fd, "500 Unrecognized command");
    }
}

sub send_msg {
    my ($client_fd, $msg) = @_;
    my $smtp_client_socket = $smtp::clients{$client_fd}{"smtp_socket"};
    send($smtp_client_socket, "$msg\r\n", 0);
}

sub remove_client {
    my ($client_fd) = @_;
    close($smtp::clients{$client_fd}{"smtp_socket"});
    delete $smtp::clients{$client_fd};
}

sub receive_msg {
    my ($smtp_client_socket) = @_;

    my $client_fd = fileno $smtp_client_socket;

    recv($smtp_client_socket, my $buffer, 1024, 0);
    $smtp::clients{$client_fd}{"data"} .= $buffer;
    print("Received MSg: $buffer\n");
    print("Length of buffer: " . length($buffer) . "\n");
    if (!$buffer) {
        print("Client $client_fd disconnected\n");
        remove_client($client_fd);
        return;
    }
    if (length($buffer) < 1024) {
        if ($smtp::clients{$client_fd}{"data"} =~ s/\.\r\n$//) {
            print("Received full message\n");
            $smtp::clients{$client_fd}{"EOD"} = 1;
            $smtp::clients{$client_fd}{"read"} = "done";
            process_msg($client_fd, ".");
            return $buffer;
        }
    }

}

sub build_email {
    my ($client_fd) = @_;
    my $file = $smtp::clients{$client_fd}{"name"};
    my $from = $smtp::clients{$client_fd}{"from"};
    my $to = $smtp::clients{$client_fd}{"to"};
    my $data = $smtp::clients{$client_fd}{"data"};

    my $base_dir = getcwd();
    my $email_dir = "$base_dir/Emails";
    if (!-d $email_dir) {
        mkdir($email_dir) or do {
            warn "Could not create directory: $!";
            return;
        };
    }

    my $specified_dir = "$email_dir/$to";
    if (!-d $specified_dir) {
        mkdir($specified_dir) or do {
            warn "Could not create directory: $!";
            return;
        };
    }

    my $file_path = "$specified_dir/$file";
    $file_path = check_file_exist($file_path);
    print("FILE PATH: $file_path\n");

    open(my $fh, ">", $file_path) or do {
        warn "Can't open file: $!";
        return;
    };
    print $fh $data;
    close($fh);
    print("Email saved to $file_path\n");
}

sub check_file_exist {
    my ($file_path) = @_;
    my $count = 1;
    while (-f $file_path) {
        $file_path = $file_path . $count;
        $count++;
    }
    if ($file_path !~ /\.txt$/) {
        $file_path = $file_path . ".txt";
    }
    return $file_path;
}

sub send_to_recipient {
    my ($client_fd) = @_;
    my $to = $smtp::clients{$client_fd}{"to_email"};
    my $mx_record = get_mx_record($to);
    print("MX RECORD: $mx_record\n");
    
    socket(my $smtp_to_recipient_socket, AF_INET, SOCK_STREAM, 0);
    my $mx_addr = inet_aton($mx_record);
    my $mx_port = 25;
    connect($smtp_to_recipient_socket, sockaddr_in($mx_port, $mx_addr)) || die "Can't connect to MX: $!";
    print("Connected to MX\n");

    my $recipient_name = $smtp::clients{$client_fd}{"to"};
    my $recipient = $smtp::clients{$client_fd}{"to_email"};
    my $from_name = $smtp::clients{$client_fd}{"from"};
    my $from = $smtp::clients{$client_fd}{"from_email"};
    my $data = $smtp::clients{$client_fd}{"data"};
    my $name = $smtp::clients{$client_fd}{"name"};

    send_and_receive($smtp_to_recipient_socket, "EHLO $name");
    send_and_receive($smtp_to_recipient_socket, "MAIL FROM:<$from>");
    send_and_receive($smtp_to_recipient_socket, "RCPT TO:<$recipient>");
    send_and_receive($smtp_to_recipient_socket, "DATA");
    send_and_receive($smtp_to_recipient_socket, $data);
    send_and_receive($smtp_to_recipient_socket, ".");
    send_and_receive($smtp_to_recipient_socket, "QUIT");



    print("Sent email to recipient\n");
    close($smtp_to_recipient_socket);
}

sub send_and_receive {
    my ($socket, $msg) = @_;
    send($socket, "$msg\r\n", 0);
    my $response;
    recv($socket, $response, 1024, 0);
    print("Response: $response\n");
}

sub get_mx_record {
    my ($recipient) = @_;

    my $domain = (split /@/, $recipient)[1];
    print("DOMAIN: $domain\n");
    my @mx = mx($domain);
    foreach my $mx (@mx) {
        print("MX: $mx\n");
        foreach my $key (keys %$mx) {
            print("$key: $mx->{$key}\n");
        }
    }
    my $mx_record = $mx[0];
    return $mx_record->exchange;
}

sub send_email {
    my ($from, $to, $subject, $message) = @_;

    my $smtp_server = "localhost";
    my $smtp_port = 25;

    socket(my $smtp_socket, AF_INET, SOCK_STREAM, 0);
    connect($smtp_socket, sockaddr_in($smtp_port, inet_aton($smtp_server))) || die "Can't connect to SMTP server: $!";
    print("Connected to SMTP server\n");

    send_and_receive($smtp_socket, "EHLO $subject");
    send_and_receive($smtp_socket, "MAIL FROM:<$from>");
    send_and_receive($smtp_socket, "RCPT TO:<$to>");
    send_and_receive($smtp_socket, "DATA");
    send_and_receive($smtp_socket, "Subject: $subject\r\nFrom: $from\r\nTo: $to\r\n\r\n$message");
    send_and_receive($smtp_socket, ".");
    send_and_receive($smtp_socket, "QUIT");

    print("Sent email\n");
    close($smtp_socket);
}
1;