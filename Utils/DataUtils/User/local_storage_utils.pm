package local_storage_utils;

use strict;
use warnings;

sub get_local_storage {
    my ($client_socket, $request) = @_;
    my $local_storage = request_utils::get_local_storage($request);
    if (!$local_storage) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_404("Local storage not found"));
    }
    return $local_storage;
}