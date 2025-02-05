package update_log;

use strict;
use warnings;

use Cwd;
use JSON;

my $base_dir = getcwd();
my $update_log_file = "$base_dir/Data/UpdateLog/update_log.json";

sub get_update_log 
{
    my($is_admin) = @_;

    my @update_log_shown = ();

    
    my $json;

    if (-e $update_log_file) {
        open(my $fh, '<', $update_log_file) or die "Can't open file $update_log_file: $!";
        $json = do { local $/; <$fh> };
        close $fh;
        if (!$json) {
            # print("Update log file is empty: $update_log_file\n");
            $json = '{"id": "ERROR", "date": "ERROR", "description": "Failed loading Update Log file or doesnt exist", "enabled": 1}';
            $json = encode_json($json);
        }
    } else {
        # print("Update log file not found: $update_log_file\n");
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
            check_each_update_point($update);
            push(@update_log_shown, $update);
        }
    }

    my @sorted_update_log = sort { $b->{id} cmp $a->{id} } @update_log_shown;
    return @sorted_update_log;
}

sub check_each_update_point {
    my ($update) = @_;

    my $updatePoints = $update->{updatePoints};
    foreach my $id (keys %$updatePoints) {
        # print("Checking update point: $id\n");
        my $updatePoint = $updatePoints->{$id};
        if ($updatePoint->{enabled} == 0) {
            delete $updatePoints->{$id};
        }
    }
}

sub add_update_log {
    my ($request) = @_;

    if (!-e $update_log_file) {
        open(my $fh, '>', $update_log_file) or do {
            warn "Can't open file $update_log_file: $!";
            return;
        };  
        close $fh;
    }
    open(my $fh, '<', $update_log_file) or do {
        warn "Can't open file $update_log_file: $!";
        return;
    };
    my $json = do { local $/; <$fh> };
    close $fh;
    my $decoded_json = $json ? decode_json($json) : {};
    $decoded_json = {} unless ref $decoded_json eq 'HASH';

    my ($date, $title, $additionalInfo, $enabled, $updatePoints, $timestamp) = get_log_data($request);
 
    my $new_id = time(); 
    my @random_numbers = map { int(rand(100)) } (1..5);
    $new_id .= join('', @random_numbers);
    $new_id = "$new_id";
    my $new_update = {
        id => $new_id,
        date => $date,
        title => $title,
        additionalInfo => $additionalInfo,
        enabled => $enabled,
        updatePoints => $updatePoints,
        timestamp => $timestamp
    };

    $decoded_json->{$new_id} = $new_update;
    open($fh, '>', $update_log_file) or die "Can't open file $update_log_file: $!";
    print $fh encode_json($decoded_json);
    close $fh;
    # print("Added new update log: $title to $update_log_file\n");
}

sub get_log_data {
    my ($body) = @_;

    my $date = get_date();
    my $title;
    my $description;
    my $additionalInfo;
    my $enabled = 1;
    my $updatePoints = {};

    # print("bODY: $body\n");

    if ($body =~ /updateTitle=(.*)&updateAdditionalInfo=(.*?)&(.*)$/) {
        $title = $1;
        $additionalInfo = $2;
        my $updatePointsStr = $3;
        while ($updatePointsStr =~ s/updatePointTitle=(.*?)&updatePointDescription=(.*?)&updatePointAdditionalInfo=(.*?)(?:&|$)//) {
            # print("updatePointTitle: $1\n");
            my $point_title = $1;
            my $point_description = $2;
            my $point_additionalInfo = $3;
            $point_title = http_utils::parse_input($point_title);
            $point_description = http_utils::parse_input($point_description);
            $point_additionalInfo = http_utils::parse_input($point_additionalInfo);
            my $point_id = scalar(keys %$updatePoints);   
            $updatePoints->{$point_id} = {
                title => $point_title,
                description => $point_description,
                additionalInfo => $point_additionalInfo,
                enabled => 1
            }
        }
    } else {
        # print("Failed to get log data\n");
    }

    if (!$title) {
        # print("Failed to get log data\n");
        return 0;
    }

    $additionalInfo = user_utils::decode_uri($additionalInfo);
    $title = user_utils::decode_uri($title);

    $additionalInfo =~ s/\+/ /g;
    $title =~ s/\+/ /g;
   

    return ($date, $title, $additionalInfo, $enabled, $updatePoints, localtime());
}

sub get_update_log_by_id {
    my ($id) = @_;

    if (!-e $update_log_file) {
        open(my $fh, '>', $update_log_file) or do {
            warn "Can't open file $update_log_file: $!";
            return;
        };  
        close $fh;
    }
    open(my $fh, '<', $update_log_file) or do {
        warn "Can't open file $update_log_file: $!";
        return;
    };

    my $json = do { local $/; <$fh> };
    close $fh;

    if (!$json) {
        # print("Update log file is empty: $update_log_file\n");
        $json = '{"id": "ERROR", "date": "ERROR", "description": "Failed loading Update Log file or doesnt exist", "enabled": 1}';
        $json = encode_json($json);
    }

    my $decoded_json = decode_json($json);
    return $decoded_json->{$id};
}

sub parse_edit_request {
    my ($uri, $body) = @_;

    my $update_log_id;
    my $update_point_id;

    # print("REQUEST: $request\n");

    if ($uri =~ /\/admin\/updateLog\/edit\/(\d+)(?:\/(\d+))?/) {
        $update_log_id = $1;
        $update_point_id = $2;
    }

    if (!$update_log_id) {
        return;
    }

    if (!$body) {
        return;
    }

    # print("update_point_id: $update_point_id\n");

    return ($update_log_id, $update_point_id, $body);
}

sub edit_update_log {
    my ($update_log_id, $update_point_id, $content) = @_;

    my %types = (
        "title" => 1,
        "description" => 1,
    );

    my %specialTypes = (
        "delete" => \&delete_update_point,
        "enable" => \&enable_update_point,
        "disable" => \&disable_update_point,
        "newTime" => \&toggle_new_time,
    );

    my %specialTypes1 = (
        "disable" => \&disable_update_log,
        "enable" => \&enable_update_log,
        "newPoint" => \&add_new_update_point,
    );

    if (!-e $update_log_file) {
        open(my $fh, '>', $update_log_file) or do {
            warn "Can't open file $update_log_file: $!";
            return;
        };  
        close $fh;
    }
    open(my $fh, '<', $update_log_file) or do {
        warn "Can't open file $update_log_file: $!";
        return;
    };

    my $json = do { local $/; <$fh> };
    close $fh;

    if (!$json) {
        return 0;
    }

    my $decoded_json = decode_json($json);
    $content = decode_json($content);

    # print("GOT JSON: $json\n");
    my $update = $decoded_json->{$update_log_id};
    # print("GOT UPDATE: $update\n");

    if (!$update) {
        return 0;
    }

    if (defined $update_point_id && $update_point_id >= 0) {
        my $updatePoint = $update->{updatePoints}->{$update_point_id};
        # print("GOT UPDATE POINT: $updatePoint\n");
        if (!$updatePoint) {
            return 0;
        }
        # print("CONTENT: $content\n");
        my $type = $content->{type};
        # print("TYPE: $type\n");
        if ($specialTypes{$type}) {
            # print("BONJOUR\n");
            $specialTypes{$type}->($update, $update_point_id, $content);
        } elsif ($types{$type}) {
            # print("UPDATIN: $updatePoint->{$type} to $content->{data}\n");
            $updatePoint->{$type} = $content->{data};
        } else {
            return 0;
        }
    } elsif ($specialTypes1{$content->{type}}) {
        # print("BONJOUR\n");
        $specialTypes1{$content->{type}}->($update, $content);
    } else {
        # print("UPDATIN: $update->{title} to $content->{data}\n");
        $update->{title} = $content->{data};
    }
    # print("UPDATE: $update\n");

    open($fh, '>', $update_log_file) or do {
        warn "Can't open file $update_log_file: $!";
        return;
    };

    print $fh encode_json($decoded_json);
    close $fh;

    return 1;
}

sub toggle_new_time {
    my ($update, $update_id, $content) = @_;

    my $status = $content->{data};

    if ($status eq "enable") {
        $update->{updatePoints}->{$update_id}->{useNewTime} = 1;
    } else {
        $update->{updatePoints}->{$update_id}->{useNewTime} = 0;
    }
}

sub add_new_update_point {
    my ($update, $content) = @_;

    my $id = scalar keys %{$update->{updatePoints}};
    my $useNewTime = $content->{useNewTime};
    if ($useNewTime) {
        $useNewTime = 1;
    } else {
        $useNewTime = 0;
    }
    my $date = get_date();
    # print("ID: $id\n");
    # print("DATE: $date\n");
    $update->{updatePoints}->{$id} = {
        title => $content->{title},
        description => $content->{description},
        enabled => 1,
        additionalInfo => $content->{additionalInfo},
        timestamp => time(),
        useNewTime => $useNewTime,
        date => $date
    };
    # foreach my $key (keys %{$update->{updatePoints}->{$id}}) {
    #     print("$key: $update->{updatePoints}->{$id}->{$key}\n");
    # };
}   

sub delete_update_point {
    my ($update, $update_point_id) = @_;

    delete $update->{updatePoints}->{$update_point_id};

    my %new_updatePoints;
    my $new_id = 0;
    foreach my $id (sort { $a <=> $b } keys %{$update->{updatePoints}}) {
        $new_updatePoints{$new_id} = $update->{updatePoints}->{$id};
        $new_id++;
    }
    $update->{updatePoints} = \%new_updatePoints;
}

sub disable_update_point {
    my ($update, $update_point_id) = @_;

    $update->{updatePoints}->{$update_point_id}->{enabled} = 0;
}

sub enable_update_point {
    my ($update, $update_point_id) = @_;

    $update->{updatePoints}->{$update_point_id}->{enabled} = 1;
}

sub enable_update_log {
    my ($update, $update_point_id) = @_;

    $update->{enabled} = 1;
}

sub disable_update_log {
    my ($update, $update_point_id) = @_;

    $update->{enabled} = 0;
}
sub delete_update_log {
    my ($update_log_id) = @_;
    # print("DELELLELELEL\n");
    open(my $fh, '<', $update_log_file) or do {
        warn "Can't open file $update_log_file: $!";
        return;
    };

    my $json = do { local $/; <$fh> };
    close $fh;

    my $decoded_json = decode_json($json);
    delete $decoded_json->{$update_log_id};

    open($fh, '>', $update_log_file) or do {
        warn "Can't open file $update_log_file: $!";
        return;
    };

    print $fh encode_json($decoded_json);
    close $fh;
}#

sub parse_delete_request {
    my ($uri) = @_;

    my $update_log_id;

    if ($uri =~ /\/admin\/updateLog\/delete\/(\d+)/) {
        $update_log_id = $1;
    }

    # print("update_log_id: $update_log_id\n");
    return $update_log_id;
}

sub get_date {
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime();
    $year += 1900;
    if ($min < 10) {
        $min = "0$min";
    }
    if ($hour < 10) {
        $hour = "0$hour";
    }
    if ($mday < 10) {
        $mday = "0$mday";
    }
    $mon += 1;
    if ($mon < 10) {
        $mon = "0$mon";
    }

    my $weekday = calender_utils::get_parsed_weekday($mday, $mon, $year);
    my $date = "$weekday, $mday.$mon.$year $hour:$min:$sec";
    return $date;
}
1;