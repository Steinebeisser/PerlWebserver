package calender_utils;

use strict;
use warnings;
use JSON;
use Cwd;
use Time::Local;
use File::Spec;

my $new_language = 0;

my %no_events_mapping = (
    de => "Keine Ereignisse",
    en => "No events"
);

my @days_of_week = (
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday"
);

my %holiday_name_mapping = (
    neuj => { de => "Neujahr", en => "New Year's day" },
    hl3k => { de => "Heilige 3 K&ouml;nige", en => "Epiphany" },
    ifra => { de => "Internationaler Frauentag", en => "Internationals Women's day" },
    romo => { de => "Rosenmontag", en => "Carnival monday" },
    fadi => { de => "Faschingsdienstag", en => "Shrove tuesday" },
    grun => { de => "Gr&uuml;ndonnerstag", en => "Green thursday" },
    karf => { de => "Karfreitag", en => "Good friday" },
    osts => { de => "Ostersonntag", en => "Easter sunday" },
    ostm => { de => "Ostermontag", en => "Easter monday" },
    pfis => { de => "Pfingstsonntag", en => "Whit sunday" },
    pfim => { de => "Pfingstmontag", en => "Whit monday" },
    himm => { de => "Himmelfahrtstag", en => "Ascension day" },
    fron => { de => "Fronleichnam", en => "Corpus christi" },
    '1mai' => { de => "Maifeiertag", en => "Labor day, German style" }, #put names with numbers on first slot in quotation marks so perl doesnt cry
    frau => { de => "Friedensfest Augsburg", en => "Peace festival Augsburg" },
    mari => { de => "Mariae Himmelfahrt", en => "Assumption day" },
    wekt => { de => "Weltkindertag", en => "World children's day" },
    '3okt' => { de => "Tag der deutschen Einheit", en => "Reunion day" }, #put names with numbers on first slot in quotation marks so perl doesnt cry
    refo => { de => "Reformationstag", en => "Reformation day" },
    alhe => { de => "Allerheiligen", en => "All hallows day" },
    buss => { de => "Buss- und Bettag", en => "Penance day" },
    heil => { de => "Heiligabend", en => "Christmas eve" },
    wei1 => { de => "1. Weihnachtstag", en => "Christmas" },
    wei2 => { de => "2. Weihnachtstag", en => "Christmas" },
    silv => { de => "Silvester", en => "New year's eve" },
);

sub number_to_month {
    my ($number, $lang) = @_;
    my %months= (
        de => [qw(Januar Februar M&auml;rz April Mai Juni Juli August September Oktober November Dezember)],
        en => [qw(January February March April May June July August September October November December)]
    );
    return $months{$lang}[$number - 1];
}


sub get_year_holidays {
    my ($year, $state) = @_;
    my $json_holidays;
    $new_language = 0;
    if ($year !~ /^\d+$/) {
        return 0;
    }

    print("IM HERE\n");
    my $language = language_utils::get_user_language();

    my $json = holidays_exists($year, $language);

    if (!$json) {
        $json_holidays = calculate_holidays($year, $language);
    } elsif ($json && $new_language) {
        $json_holidays = calculate_holidays($year, $language, $json);
    } elsif ($json && !$new_language) {
        $json_holidays = encode_json($json); #get_stored_holidays($year, $language, $json);
    } else {
        return 0;
    }

    if (!$json_holidays) {
        return 0;
    }

    return ($json_holidays, $language);
}

sub get_month_holidays {
    my ($year, $month) = @_;
    if ($month =~ /(\d+)/) {
        $month = $1;
    }
    if ($year !~ /^\d+$/ || $month !~ /^\d+$/) {
        return 0;
    }
    my ($json_holidays, $language) = get_year_holidays($year);
    my $json_holidays_ref = decode_json($json_holidays);
    if (!defined($json_holidays_ref)) {
        return 0;
    }
    if (!exists($json_holidays_ref->{lang}{$language}{months}{$month})) {
        return 0;
    }
    return encode_json($json_holidays_ref->{lang}{$language}{months}{$month});
}


sub calculate_holidays {
    my ($year, $language, $calender_ref) = @_;
    my %calender = $calender_ref ? %$calender_ref : ();

    if (!%calender) {
        %calender = (
            year => $year,
            lang => {}
        ); 
    } 


    $calender{lang}{$language} = {
        months => {}
    };
    my ($easter_day, $easter_month) = calculate_easter($year);
    print("CALCING EASTER: $easter_day, $easter_month\n");
    my $easter_holidays_ref = get_holidays_based_on_easter($year, $easter_day, $easter_month);
    my @easter_holidays = @$easter_holidays_ref;
    foreach my $easter_holiday (@easter_holidays) {
        print("EASTER HOLIDAY: $easter_holiday\n");
    }
    print("HOLIDAYS: @easter_holidays\n");

    my $year_holidays = add_constant_holidays($year, \@easter_holidays);
    print("HELLO?\n");
    foreach my $year_holiday (@$year_holidays) {
        print("YEAR HOLIDAY: $year_holiday\n");
    }

    # my $year_timestamp = get_timestamp_from_year($year);
    # if ($year_timestamp == 0) {
    #     return 0;
    # }

    
    # my $holidays_ref = holidays(WHERE   => ['all'],
    #                         YEAR    => $year,
    #                         FORMAT  => "%#, %m, %d");
    # my @holidays = @$holidays_ref;

    foreach my $holiday (@$year_holidays) {
        my @holiday_data = split(/, /, $holiday);
        my $holiday_name = $holiday_data[0];
        my $holiday_month = $holiday_data[1];
        my $holiday_day = $holiday_data[2];
        if ($holiday_month < 10) {
            if ($holiday_month =~ /0/) {
                print("HAS ZERO $holiday_month\n");
            } else {
                print("NO ZERO $holiday_month\n");
                $holiday_month = "0$holiday_month";
            }
        }
        print("HOLIDAY: $holiday_name, $holiday_month, $holiday_day\n");

        my $holiday_full_name = $holiday_name_mapping{$holiday_name}{$language};
        print("HOLIDAY FULL NAME: $holiday_full_name\n");

        $calender{lang}{$language}{months}{$holiday_month}{name} = number_to_month($holiday_month, $language);
        $calender{lang}{$language}{months}{$holiday_month}{days}{$holiday_day}{events} = [$holiday_full_name];
        $calender{lang}{$language}{months}{$holiday_month}{days}{$holiday_day}{description} = "Baguette";
    }

    foreach my $month (1..12) {
        print("MONTH: $month\n");
        if ($month < 10) {
            $month = "0$month";
        }
        if (!exists($calender{lang}{$language}{months}{$month})) {
            $calender{lang}{$language}{months}{$month} = {
                name => number_to_month($month, $language),
                days => {
                    0 => {
                        events => [
                            "$no_events_mapping{$language}"
                        ],
                        description => "$no_events_mapping{$language}"
                    }
                }
            };
        }
    }
    

    my $current_dir = getcwd();
    my $data_dir = File::Spec->catdir($current_dir, 'Data');
    my $base_dir = File::Spec->catdir($data_dir, 'Calender');
    if (!-d $base_dir) {
        if (!-d $data_dir) {
            print "Creating directory $data_dir\n";
            mkdir $data_dir;
        }
        print "Creating directory $base_dir\n";
        mkdir $base_dir;
    }
    my $json = encode_json(\%calender);
    open(my $file, '>', File::Spec->catfile($base_dir, "$year.json")) or do {
        print "Could not open file $!\n";
        return;
    };
    print $file $json;
    close($file);

    return $json;
}

sub add_constant_holidays {
    my ($year, $holidays_ref) = @_;
    my @holidays = @$holidays_ref;

    my ($buss_day, $buss_month) = calculate_buss($year);
    print("BUSS DAY: $buss_day\n");
    
    push (@holidays, "neuj, 01, 01");
    push (@holidays, "hl3k, 01, 06");
    push (@holidays, "ifra, 03, 08");
    push (@holidays, "1mai, 05, 01");
    push (@holidays, "frau, 08, 08");
    push (@holidays, "mari, 08, 15");
    push (@holidays, "wekt, 09, 20");
    push (@holidays, "3okt, 10, 03");
    push (@holidays, "refo, 10, 31");
    push (@holidays, "alhe, 11, 01");
    push (@holidays, "buss, 11, $buss_day");
    push (@holidays, "wei1, 12, 25");
    push (@holidays, "wei2, 12, 26");

    return \@holidays;
}

sub calculate_buss {
    my ($year) = @_;
    
    print("CALCULATING BUSS");
    my ($easter_day, $easter_month) = calculate_easter($year); # Sonntag
    my $wednesday = $easter_day + 3; # Mittwoch
    my $getting_buss_day = 1;

 
    while ($easter_month < 9) {
        if ($wednesday > days_in_month($easter_month, $year)) {
            $wednesday = $wednesday - days_in_month($easter_month, $year);
            $easter_month++;
        } else {
            $wednesday += 7;
        }
    }
    while ($getting_buss_day) {
        if (($wednesday + 7) >= 23) {
            return ($wednesday);
        } else {
            $wednesday += 7;
        }
    }
}

sub calculate_easter {
	my ($year) = @_;
	
	my $a = int($year % 19);

	my $b = int($year / 100);

	my $c = int($year % 100);

	my $d = int($b / 4);

	my $e = int($b % 4);

	my $f = int(($b + 8) / 25);

	my $g = int(($b - $f + 1) / 3);

	my $h = int((19 * $a + $b - $d - $g + 15) % 30);

	my $i = int($c / 4);

	my $k = int($c % 4);

	my $l = int((32 + 2 * $e + 2 * $i - $h - $k) % 7);

	my $m = int(($a + 11 * $h + 22 * $l) / 451);

	my $n = int(($h + $l - 7 * $m + 114) / 31);

	my $p = int(($h + $l - (7*$m) + 114) % 31);

	my $easter_day =  $p + 1;
	my $easter_month = $n;

	return ($easter_day, $easter_month, $year);
}

sub get_holidays_based_on_easter {
    my ($year, $easter_day, $easter_month) = @_;

    my $romo = $easter_day - 48;
    my $fadi = $easter_day - 47;
    my $grun = $easter_day - 3;
    my $karf = $easter_day - 2;
    my $osts = $easter_day;
    my $ostm = $easter_day + 1;
    my $himm = $easter_day + 39;
    my $pfis = $easter_day + 49;
    my $pfim = $easter_day + 50;
    my $fron = $easter_day + 60;

    my @holiday_name = qw(romo fadi grun karf osts ostm himm pfis pfim fron);
    my @holidays = ($romo, $fadi, $grun, $karf, $osts, $ostm, $himm, $pfis, $pfim, $fron);
    my @holiday_ref = ();

    foreach my $holiday (@holidays) {
        my $holiday_month = $easter_month;
        while ($holiday < 1 || $holiday > days_in_month($holiday_month, $year)) {
            if ($holiday < 1) {
                $holiday = $holiday + days_in_month($holiday_month - 1, $year);
                $holiday_month--;
            } elsif ($holiday > days_in_month($holiday_month, $year)) {
                $holiday = $holiday - days_in_month($holiday_month, $year);
                $holiday_month++;
            }
        }
        my $holiday_name = shift(@holiday_name);
        if ($holiday_month < 10) {
            $holiday_month = "0$holiday_month";
        }
        if ($holiday < 10) {
            $holiday = "0$holiday";
        }
        push (@holiday_ref, ("$holiday_name, $holiday_month, $holiday"));
    }
    print("HOLIDAY REF: @holiday_ref\n");

    return \@holiday_ref;
}


sub days_in_month {
    my ($month, $year) = @_;
    return 31 if $month == 1 || $month == 3 || $month == 5 || $month == 7 || $month == 8 || $month == 10 || $month == 12;
    return 30 if $month == 4 || $month == 6 || $month == 9 || $month == 11;
    if (is_leapyear ($year)) {
        return 29;
    }
    return 28;
}

sub is_leapyear {
    my ($year) = @_;
    return 1 if $year % 400 == 0;
    return 0 if $year % 100 == 0;
    return 1 if $year % 4 == 0;
    return 0;
}

sub get_timestamp_from_year {
    my ($year) = @_;
    if ($year < 1970 || $year > 2037) {
        main::serve_error(HTTP_RESPONSE::ERROR_404("Year is too far in the future"));
        return 0;
    }
    return 1;

}

sub get_max_timestamp {
    my $max_time = 2**31 - 1;
    print("MAX TIME: $max_time\n");
    return $max_time;
}
sub holidays_exists {
    my ($year, $language) = @_;
    my $current_dir = getcwd();
    my $data_dir = File::Spec->catdir($current_dir, 'Data');
    my $base_dir = File::Spec->catdir($data_dir, 'Calender');
    if (!-d $base_dir) {
        return 0;
    }
    if (!-f File::Spec->catfile($base_dir, "$year.json")) {
        return 0;
    }

    open my $file, '<', File::Spec->catfile($base_dir, "$year.json") or do {
        print("Could not open file $!\n");
        return 0;
    };
    my $json = do { local $/; <$file> };
    close $file;
    $json = decode_json($json);

    print("LANG: $language\n");


    if (!defined($json)) {
        return 0;
    }
    if (!exists($json->{lang}{$language})) {
        $new_language = 1;
        return $json;
    }
    print "EXISTIN\n";
    return $json;
}

sub get_stored_holidays {
    my ($year) = @_;
    my $current_dir = getcwd();
    my $data_dir = File::Spec->catdir($current_dir, 'Data');
    my $base_dir = File::Spec->catdir($data_dir, 'Calender');
    open(my $file, '<', File::Spec->catfile($base_dir, "$year.json")) or do {
        print "Could not open file $!\n";
        return;
    };
    my $json = do { local $/; <$file> };
    close($file);
    return $json;
}

sub get_weekday {
    my ($day, $month, $year) = @_;

    my $yearcode = calculate_yearcode($year);
    print("YEARCODE: $yearcode\n");

    my $monthcode = calculate_monthcode($month);
    print("MONTHCODE: $monthcode\n");

    my $centurycode = calculate_centurycode($year);
    print("CENTURYCODE: $centurycode\n");

    my $leapcode_modifier = 0;
    if (is_leapyear($year) && ($month == 1 || $month == 2)) {
        $leapcode_modifier = -1;
    }
    print("DAY: $day\n");
    print("LEAPCODE MODIFIER: $leapcode_modifier\n");

    my $weekday = ($yearcode + $monthcode + $centurycode + $day + $leapcode_modifier) % 7;
    print("WEEKDAY: $weekday\n");

    return $weekday;
}

sub calculate_yearcode {
    my ($year) = @_;

    my $last_two_digits = substr($year, -2, 2);
    print("LAST TWO DIGITS: $last_two_digits\n");
    
    my $yearcode = ($last_two_digits + int($last_two_digits / 4)) % 7;
    
    return $yearcode;
}

sub calculate_monthcode {
    my ($month) = @_;

    my %monthcodes = (
        "01" => 0,
        "02" => 3,
        "03" => 3,
        "04" => 6,
        "05" => 1,
        "06" => 4,
        "07" => 6,
        "08" => 2,
        "09" => 5,
        "10" => 0,
        "11" => 3,
        "12" => 5
    );

    return $monthcodes{$month};
}

sub calculate_centurycode {
    my ($year) = @_;

    my $century = int($year / 100) ;

    my @centurycodes = (6, 4, 2, 0);

    my $centurycode = $centurycodes[$century % 4];

    return $centurycode;
}

sub get_parsed_weekday {
    my ($day, $month, $year) = @_;
    my $weekday = get_weekday($day, $month, $year);
    if ($weekday == 0) {
        $weekday = 6;
    } else {
        $weekday--;
    }
    my $parsed_weekday = $days_of_week[$weekday];
    return $parsed_weekday;
}

sub get_calender_layout {
    my ($month, $year, $translations, %holidays) = @_;
    my $html_body = <<HTML;
    <div class="week_days">
                    <span class="week_day">$translations->{monday}</span>
                    <span class="week_day">$translations->{tuesday}</span>
                    <span class="week_day">$translations->{wednesday}</span>
                    <span class="week_day">$translations->{thursday}</span>
                    <span class="week_day">$translations->{friday}</span>
                    <span class="week_day">$translations->{saturday}</span>
                    <span class="week_day">$translations->{sunday}</span>
                </div>
                <div class="days">
HTML
        my $month_days_amount = days_in_month($month, $year);
        my $first_day = get_weekday(1, $month, $year);
        if ($first_day == 0) {
            $first_day = 7;
        }
        my $last_day = get_weekday($month_days_amount, $month, $year);
        if ($last_day == 0) {
            $last_day = 7;
        }
        for (my $i = 2; $i <= $month_days_amount+$first_day+1; $i++) {
            my $scan_day;
            my $day = ($i-$first_day);
            if ($day <= 0) {
                $html_body .= <<HTML;
                <span class="day"></span>
HTML
                next;
            }

            if ($day > $month_days_amount) {
                
                $html_body .= <<HTML;
                <span class="day"></span>
HTML
                for (my $j = 0; $j < 7 - $last_day; $j++) {
                    $html_body .= <<HTML;
                    <span class="day"></span>
HTML
                }
                next;  
            }

            if ($day < 10) {
                $scan_day = "0$day";
            } else {
                $scan_day = $day;
            }

            if ($holidays{$month}{$scan_day}) {
                print("HOLIDAY FOUND: $month $day\n");
                $html_body .= <<HTML;
                <div class="day holiday">$day</div>
HTML
                next;
            }

            $html_body .= <<HTML;
                <span class="day">$day</span>
HTML


            if ($day % 7 == 0) {
                $html_body .= <<HTML;
                <br>
HTML
            }
        }
    return $html_body;
}

sub parse_date {
    my ($timestamp) = @_;
    print("TIMESTAMP: $timestamp\n");

    my ($sec, $min, $hour, $day, $month, $year) = localtime($timestamp);
    $year += 1900;
    $month++;

    if ($sec < 10) {
        $sec = "0$sec";
    }
    if ($min < 10) {
        $min = "0$min";
    }
    if ($hour < 10) {
        $hour = "0$hour";
    }
    if ($day < 10) {
        $day = "0$day";
    }
    if ($month < 10) {
        $month = "0$month";
    }
    
    my $parsed_date = "$day.$month.$year $hour:$min:$sec";

    return $parsed_date;
}

sub handle_calender {
    my ($client_socket, $route) = @_;
    my $year;
    my $month;
    my $is_month = 0;
    # print("REQUEST123: $request\n");

    if ($route =~ /\/calender\/year\/(.*)\/month\/(.*)/) {
        $is_month = 1;
        $year = $1;
        $month = $2;
        print("YEAR: $year\n");
        print("MONTH: $month\n");
    } elsif ($route =~ /\/calender\/year\/(.*)/) {
        $year = $1;
        print("YEAR2: $year\n");
    }
    if ($is_month) {
        return get_calender_pages::get_calender_month($client_socket, $route);
    } else {
        return get_calender_pages::get_calender_year($client_socket, $route);
    }
}
1;