package load_fonts;

use strict;
use warnings;

use Cwd;

sub get_fonts {
    my ($client_socket, $route) = @_;

    # print("FONTS\n");
    # print("REQUEST: $request\n");

    if ($route =~ /\/fonts\/(.*)/) {
        my $font = $1;
        # print("FONT: $font\n");

        my $base_dir = getcwd();
        my $font_path = "$base_dir/fonts/$font";
        # print("FONT PATH: $font_path\n");
        if (-e $font_path) {
            open my $fh, '<', $font_path or die "Cannot open file: $!";

            binmode $fh;
            my $font_data;
            {
            local $/;
            $font_data = <$fh>;
            }
            close $fh;

            my $response = HTTP_RESPONSE::OK_WITH_DATA($font_data, $font);
            http_utils::send_http_response($client_socket, $response);
        } else {
            http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_404("Font not found"));
        }
    }
}


1;