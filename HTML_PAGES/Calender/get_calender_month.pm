package get_calender_month;

use strict;
use warnings;
use JSON;

sub get_calender_month {
    my ($year, $month) = @_;

    if (!$year || !$month) {
        return 0;
    }
    
    my $calender_data_json = calender_utils::get_month_holidays($year, $month);
    my $calender_data = decode_json($calender_data_json) if $calender_data_json;



    my $translations = language_utils::load_language("calender");

    print($calender_data_json);

    if (!defined $calender_data) {
        main::serve_error(HTTP_RESPONSE::ERROR_404("No holiday data found for $year/$month"));
    }

    my $html_body = <<HTML;
    <h1>Calender</h1>
    <br>
    <div class="back_button">
        <a href="/calender/year/$year">$translations->{back}</a>
    </div>
    <br>
    <form action="/calender/month" method="get">
        $translations->{year}: <input type="text" name="year">
        $translations->{month}: <input type="text" name="month">
        <input type="submit" value="$translations->{show}">
    </form>
    <br>
HTML

    my $month_name = $calender_data->{name};
    my $next_year = $year;
    my $next_month = $month + 1;
    my $year_before = $year;
    my $before_month = $month - 1;
    if ($next_month > 12) {
        $next_month = 1;
        $next_year++;
    }
    if ($next_month < 10) {
        $next_month = "0$next_month";
    }
    if ($before_month < 1) {
        $before_month = 12;
        $year_before--;
    }
    if ($before_month < 10) {
        $before_month = "0$before_month";
    }
    $html_body .= <<HTML;
    <div class="inline_buttons_test">
        <form action="/calender/year/$year_before/month/$before_month" method="get">
            <input type="submit" value="<-">
        </form>
        
        <h2>$month_name $year</h2>
        
        <form action="/calender/year/$next_year/month/$next_month" method="get" >
            <input type="submit" value="->">
        </form>
    </div>
    <br>
HTML
    print("/calender/year/$year/month/$next_month");




    $html_body .= <<HTML;
    <div class="calender">
        <div class="week_days">
            <span class="week_day">$translations->{longMonday}</span>
            <span class="week_day">$translations->{longTuesday}</span>
            <span class="week_day">$translations->{longWednesday}</span>
            <span class="week_day">$translations->{longThursday}</span>
            <span class="week_day">$translations->{longFriday}</span>
            <span class="week_day">$translations->{longSaturday}</span>
            <span class="week_day">$translations->{longSunday}</span>
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

            if ($calender_data->{days}{$scan_day}) {
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

        $html_body .= <<HTML;
                </div>
            </a>
        </div>
HTML
    



    $html_body .= <<HTML;
    <table>
        <tr>
            <th>$translations->{day}</th>
            <th>$translations->{event}</th>
            <th>$translations->{description}</th>
        </tr>
HTML

    foreach my $day (sort keys %{$calender_data->{days}}) {
        my $day_name = join(", ", @{$calender_data->{days}->{$day}->{events}});
        my $day_description = $calender_data->{days}->{$day}->{description};

        $html_body .= <<HTML;
        <tr>
            <td>$day</td>
            <td>$day_name</td>
            <td>$day_description</td>
        </tr>
HTML
    }

    $html_body .= <<HTML;
    </table>
    </div>
HTML

    $html_body .= html_utils::create_breadcrumbs("calender,year/$year, month/$month");

    my $html_content = html_structure::get_html($html_body, "Calender $month_name $year");

    return ($html_content);
}

1;