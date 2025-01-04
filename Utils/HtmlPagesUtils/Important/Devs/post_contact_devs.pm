package post_contact_devs;

use strict;
use warnings;

use JSON;
use Cwd;

my %reasons = (
    "Storage full" => \&hardware_devs::send_to_hardware_devs,
    "Server down" => \&software_devs::send_to_software_devs,
);

sub post_contact_devs {
    my ($client_socket, $route, $temp_file) = @_;

    print("CONTACT DEVS\n");

    my $body = body_utils::load_temp_file($temp_file);
    my $json = decode_json($body);

    my $reason = $json->{reason};

    send_to_corresponding_devs($reason);
}

sub send_to_corresponding_devs {
    my ($reason) = @_;

    my $send_to_devs = $reasons{$reason};

    $send_to_devs->($reason);
}


1;