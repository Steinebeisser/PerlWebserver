package hardware_devs;

use strict;
use warnings;

sub send_to_hardware_devs {
    my ($reason) = @_;

    my @hardware_devs = dev_utils::get_devs("hardware");

    foreach my $hardware_dev (@hardware_devs) {
        my $name = $hardware_dev->{name};
        my $email = $hardware_dev->{email};
        # print("Sending email to hardware dev: $email\n");
        dev_utils::send_email($email, $name, "Hardware issue", "$reason, please check it out.");
    }
}

1;