package request_utils;

use strict;
use warnings;

sub get_cookie_data {
    my ($request) = @_;

    if ($request =~ /Cookie: (.*)/) {
        my $cookie = $1;
        # print("COOOOKIE: $cookie\n");
        my %cookie_data;
        if ($cookie =~ /username=(.*)[;| |\r]/) {
            # print("USERNAME $1\n");
            $cookie_data{username} = $1;
        }
        if ($cookie =~ /scheme=([^\s;]+)/) {
            # print("SCHEME $1\n");
            $cookie_data{scheme} = $1;
        }
        if ($cookie =~ /language=(.*)[;| |\r]/) {
            # print("LANGUAGE $1\n");
            $cookie_data{language} = $1;
        }
        if ($cookie =~ /memory=([^\s;]+)/) {
            # print("MEMORY $1\n");
            $cookie_data{memory} = $1;
        }
        return \%cookie_data;
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

sub get_cookie {
    my ($request) = @_;
    my $cookie;
    if (!$request) {
        return;
    }
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
            print "BODY: $line\n";
            $request_body .= $line . "\n";
        }
    }
    # print("REQUEST BODY: $request_body\n");

    return $request_body;
}

1;