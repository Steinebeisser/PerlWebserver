package update_log;

use strict;
use warnings;

use Cwd;
use JSON;

sub get_update_log 
{
    my($is_admin) = @_;

    my @update_log_shown = ();

    my $base_dir = getcwd();
    my $update_log_file = "$base_dir/Data/UpdateLog/update_log.json";
    my $json;

    if (-e $update_log_file) {
        open(my $fh, '<', $update_log_file) or die "Can't open file $update_log_file: $!";
        $json = do { local $/; <$fh> };
        close $fh;
        if (!$json) {
            print("Update log file is empty: $update_log_file\n");
            $json = '{"id": "ERROR", "date": "ERROR", "description": "Failed loading Update Log file or doesnt exist", "enabled": 1}';
            $json = encode_json($json);
        }
    } else {
        print("Update log file not found: $update_log_file\n");
        $json = '{"id": "ERROR", "date": "ERROR", "description": "Failed loading Update Log file or doesnt exist", "enabled": 1}';
        $json = encode_json($json);
    }
    my $decoded_json = decode_json($json);
    $decoded_json = {} unless ref $decoded_json eq 'HASH';

    foreach my $id (keys %$decoded_json) {
        my $update = $decoded_json->{$id};
        if ($update->{enabled} == 0 && !$is_admin) {
            next;
        } else {
            push(@update_log_shown, $update);
        }
    }

    return @update_log_shown;
}

sub add_update_log {
    my ($request) = @_;

    my $base_dir = getcwd();
    my $update_log_file = "$base_dir/Data/UpdateLog/update_log.json";
    open(my $fh, '<', $update_log_file) or die "Can't open file $update_log_file: $!";
    my $json = do { local $/; <$fh> };
    close $fh;
    my $decoded_json = $json ? decode_json($json) : {};
    $decoded_json = {} unless ref $decoded_json eq 'HASH';

    my ($date, $title, $description, $additionalInfo, $enabled) = get_log_data($request);
 
    my $new_id = time(); 
    my @random_numbers = map { int(rand(100)) } (1..5);
    $new_id .= join('', @random_numbers);
    my $new_update = {
        id => $new_id,
        date => $date,
        title => $title,
        description => $description,
        additionalInfo => $additionalInfo,
        enabled => $enabled
    };

    $decoded_json->{$new_id} = $new_update;
    open($fh, '>', $update_log_file) or die "Can't open file $update_log_file: $!";
    print $fh encode_json($decoded_json);
    close $fh;
    print("Added new update log: $title to $update_log_file\n");
}

sub get_log_data {
    my ($request) = @_;

    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime();
    my $date = "$mday." . ($mon + 1) . "." . ($year + 1900) . " " . $hour . ":" . $min . ":" . $sec;
    my $title;
    my $description;
    my $additionalInfo;
    my $enabled = 1;

    my $body = request_utils::skip_to_body($request);
    print("bODY: $body\n");

    if ($body =~ /title=(.*?)&description=(.*?)&additionalInfo=(.*)$/) {
        $title = $1;
        $description = $2;
        $additionalInfo = $3;
    } else {
        print("Failed to get log data\n");
    }

    return ($date, $title, $description, $additionalInfo, $enabled);
}

1;