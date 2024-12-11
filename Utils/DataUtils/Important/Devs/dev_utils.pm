package dev_utils;

use strict;
use warnings;
use Net::SMTP;

use Cwd;

my %devs = (
    "hardware" => "hardware_devs.txt",
    "software" => "software_devs.txt"
);

sub send_email {
    my ($email, $name, $subject, $message) = @_;

    my $from = "devs.info\@aioperl.de";
    my $to = $name . "<" . $email . ">";

    smtp_utils::send_email($from, $to, $subject, $message);
}

sub get_devs {
    my ($type) = @_;

    my $devs_file = $devs{$type};
    my $base_dir = getcwd();
    my $devs_path = "$base_dir/Data/DevLists/$devs_file";

    my @devs;

    open(my $devs_fh, "<", $devs_path) or do {
        warn "Could not open file '$devs_path' $!";
        return;
    };
    foreach my $dev (<$devs_fh>) {
        chomp($dev);
        if ($dev =~ /(.*) : (.*)/) {
            my $dev_name = $1;
            my $dev_email = $2;
            push @devs, { name => $dev_name, email => $dev_email };
        }
    }
    close($devs_fh);

    return @devs;
}

1;