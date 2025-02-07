package ip_utils;

use strict;
use warnings;

use JSON;

sub get_geolocation {
    my ($ip) = @_;

    my ($json) = query_ip_api($ip);

    if ($json->{status} eq "fail") {
        return;
    }

    return $json;
}

sub query_ip_api {
    my ($ip) = @_;

    my $url = "http://ip-api.com/json/$ip";
    my $response = `curl -s $url`;
    my $json = decode_json($response);
    # print("JSON: $json\n");
    # foreach my $key (keys %$json) {
        # print("$key: $json->{$key}\n");
    # }
    return $json;
}

1;