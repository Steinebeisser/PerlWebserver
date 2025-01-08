package support_utils;

use strict;
use warnings;

use Cwd;
use JSON;

my $base_dir = getcwd();
my $support_path = "$base_dir/Data/Support/";
my $support_options_file = "$support_path/support_options.json";

if (!-d $support_path) {
    mkdir $support_path;
}
if (!-e $support_options_file) {
    open my $fh, ">", $support_options_file;
    print $fh "{}";
    close $fh;
}

sub get_support_options {
    open my $fh, "<", $support_options_file or die "Could not open file '$support_options_file' $!";
    my $json = do { local $/; <$fh> };  # Slurp the entire file content
    close $fh;

    my $supportOptions = decode_json($json);
    my @result;

    # Sort the main options by keys
    foreach my $mainOption (sort keys %$supportOptions) {
        my $title = $supportOptions->{$mainOption}->{title};
        # print("TITLE: $title\n");

        my @options;
        # Sort the sub-options by keys
        foreach my $option_key (sort keys %{$supportOptions->{$mainOption}->{options}}) {
            my $option = $supportOptions->{$mainOption}->{options}->{$option_key};
            my $link = $option->{link};
            my $description = $option->{text};

            push @options, {
                link => $link,
                description => $description,
            };
        }

        push @result, {
            title   => $title,
            options => \@options,
        };
    }

    return \@result;
}

sub handle_new_request {

    if ($main::uri =~ /\/support\/request\/new\/(.*)/) {
        my $request_type = $1;
        # print("REQUEST TYPE: $request_type\n");
    } else {
        # print("URI: $main::uri\n");
    }
}
1;