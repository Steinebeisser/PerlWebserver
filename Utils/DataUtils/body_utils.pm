package body_utils;

use strict;
use warnings;

sub load_temp_file {
    my ($file_path) = @_;
    if (!$file_path) {
        return "";
    }
    if (!-e $file_path) {
        return "";
    }
    if (-s $file_path == 0) {
        return "";
    }
    if (-s $file_path > 1024*1024) {
        print("File too large\n");
        return "";
    }

    open(my $fh, '<', $file_path) or die "Could not open file '$file_path' $!";
    my $content = do { local $/; <$fh> };
    print("CONTENT: $content\n");
    close($fh);

    return $content;
}

1;