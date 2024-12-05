package get_calender_year;

use strict;
use warnings;
use JSON;


sub get_calender_year {
    my ($year) = @_;
    print("YEAHAH: $year\n");
    if ($year =~ /^(\d+)\//) {
        $year = $1;
    }
    if ($year =~ /(\d+)\?/) {
        $year = $1;
    }
    if ($year !~ /^\d+$/) {
        return "Invalid year format. Please enter a valid year.";
    }
    my ($calender_data_json, $language) = calender_utils::get_year_holidays($year);
    my $calender_data = decode_json($calender_data_json) if $calender_data_json;
    $calender_data = $calender_data->{lang}->{$language} if $calender_data;

    print("GOT DATA $calender_data\n$calender_data_json\n");
    my $translations = language_utils::load_language("calender");

    if (!defined $calender_data) {
        return 0;
    }

    


    # print("Calender data: $calender_data_json\n");
    my $html_body = <<HTML;
    <h1>$translations->{calender}</h1>
    <br>
    <div class="back_button">
        <a href="/ ">$translations->{back}</a>
    </div>
    <br>
    <form action="/calender/year" method="post">
        $translations->{year}: <input type="text" name="year">
        <input type="submit" value="$translations->{show}">
    </form>
    <br>
HTML

    my $next_year = $year + 1;
    my $year_before = $year - 1;
    my %holidays = ();

    $html_body .= html_utils::create_breadcrumbs("calender, year/$year");


    $html_body .= <<HTML;
    <br>
    <div class="calender">
        <div class="inline_buttons_test">
            <form action="/calender/year/$year_before" method="get">
                <input type="submit" value="<-">
            </form>
            
            <h2>$translations->{year} $year</h2>
            
            <form action="/calender/year/$next_year" method="get" >
                <input type="submit" value="->">
            </form>
        </div>
HTML
    foreach my $month (sort keys %{$calender_data->{months}}) {
        my $month_name = $calender_data->{months}->{$month}->{name};
        my $holiday_amount = 0;
        foreach my $day (sort keys %{$calender_data->{months}->{$month}->{days}}) {
            if ($calender_data->{months}->{$month}->{days}->{0}) {
                $holiday_amount = 0;
                last;
            }
            $holidays{$month}{$day} = 1;
            $holiday_amount += scalar @{$calender_data->{months}->{$month}->{days}->{$day}->{events}};

        }

        $html_body .= <<HTML;
        <div class="month_button">
            <a href="/calender/year/$year/month/$month">
                <div class="top_calender">
                    <span class="month_name">$month_name</span>
                    <span class="holiday_amount">$holiday_amount $translations->{holidays}</span>
                </div>
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
        my $month_days_amount = calender_utils::days_in_month($month, $year);
        my $first_day = calender_utils::get_weekday(1, $month, $year);
        if ($first_day == 0) {
            $first_day = 7;
        }
        my $last_day = calender_utils::get_weekday($month_days_amount, $month, $year);
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
        foreach my $month (keys %holidays) {
            foreach my $day (keys %{$holidays{$month}}) {
                print("HOLIDAY: $month $day\n");
            }
        }

        $html_body .= <<HTML;
                </div>
            </a>
        </div>
HTML
    }

    $html_body .= <<HTML;
    </div>
HTML

    $html_body .= <<HTML;
    <h2>$translations->{year} $year</h2>
    <table>
        <tr>
            <th>$translations->{month}</th>
            <th>$translations->{day}</th>
            <th>$translations->{event}</th>
            <th>$translations->{description}</th>
        </tr>

HTML

    foreach my $month (sort keys %{$calender_data->{months}}) {
        my $month_name = $calender_data->{months}->{$month}->{name};
        $html_body .= <<HTML;
        <tr>
            <td>$month_name</td>
            <td></td>
            <td></td>
            <td></td>
        </tr>
HTML

        foreach my $day (sort keys %{$calender_data->{months}->{$month}->{days}}) {
            my $day_name = join(", ", @{$calender_data->{months}->{$month}->{days}->{$day}->{events}});
            my $day_description = $calender_data->{months}->{$month}->{days}->{$day}->{description};
            $html_body .= <<HTML;
            <tr>
                <td></td>
                <td>$day</td>
                <td>$day_name</td>
                <td>$day_description</td>
            </tr>
HTML
        }

    }
        $html_body .= <<HTML;
    </table>
HTML

    my $html_content = html_structure::get_html($html_body, "Calender");

    return ($html_content);
}

1;