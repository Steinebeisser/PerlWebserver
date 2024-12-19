package request_utils;

use strict;
use warnings;

sub get_cookie_data {
    my ($request) = @_;

    if ($request =~ /Cookie: (.*)/) {
        my $cookie = $1;
        # print("COOOOKIE: $cookie\n");
        return $cookie;
    }
}

sub get_referer {
    my ($request) = @_;
    my $referer;
    if ($request =~ /Referer: (.*)\r\n/) {
        $referer = $1;
    }
    return $referer;
}

sub get_session_cookie {
    my ($header) = @_;

    my $cookie;
    if ($header =~ /Cookie: (.*)/) {
        $cookie = $1;
    }
    if (!$cookie) {
        return;
    }
    if ($cookie =~ /session(=[^\s;]+)/) {
        return $1;
    }
}

sub get_scheme_by_cookie {
    my ($cookie) = $main::header =~ /Cookie: (.*)/;
    if ($cookie) {
        print("COOKIE GOT: $cookie\n");
        if ($cookie =~ /scheme=([^\s;]+)/) {
            print("SCHEME: $1\n");
            return $1;
        }
    }
}

sub get_accept_language_by_cookie {
    my ($cookie) = $main::header =~ /Cookie: (.*)/;
    if ($cookie) {
        if ($cookie =~ /language=([^\s;]+)/) {
            return $1;
        }
    }
}
sub get_cookie {
    my ($request) = @_;
    my $cookie;
    if (!$request) {
        return;
    }
    # print("REQUEST FOR COOKIE: $request\n");
    if ($request =~ /Cookie: (.*)/) {
        $cookie = $1;
        # print "Cookie: $cookie\n";
        if ($cookie =~ /username=([^\s;]+)/) {
            $main::isLoggedIn = 1;
            user_utils::populate_user($cookie);
        }
        if ($cookie =~ /language=([^\s;]+)/) {
            # print "Cookie language: $1\n";
            $main::cookie_language = $1;
        }
        if ($cookie =~ /scheme=([^\s;]+)/) {
            # print "Cookie dark mode: $1\n";
            $main::cookie_dark_mode = $1;
        }
    }
    return $cookie;
}

sub skip_to_body {
    my ($request) = @_;
    my $request_body = "";
    my @lines = split(/\r?\n/, $request);
    my $is_body = 0;
    foreach my $line (@lines) {
        if ($line eq "") {
            $is_body = 1;
            next;
        }
        if ($is_body) {
            # print "BODY: $line\n";
            $request_body .= $line . "\n";
        }
    }
    # print("REQUEST BODY: $request_body\n");

    return $request_body;
}

1;