package get_calender_pages;

use strict;
use warnings;

sub get_calender_year {
    my ($client_socket, $request) = @_;
    my $year;
    if ($request =~ /\/calender\/year\/(.*) HTTP/) {
        $year = $1;
        # print "YEAR: $year\n";
    }
    if (!$year) {
        my ($sec, $min, $hour, $mday, $mon, $year_localtime, $wday, $yday, $isdst) = localtime();
        $year_localtime += 1900;
        $year = $year_localtime;
    }

    my $html = get_calender_year::get_calender_year($year);

    return $html;
}

sub get_calender_month {
    my ($client_socket, $request) = @_;
    my $year;
    my $month;
    if ($request =~ /\/calender\/year\/(.*)\/month\/(.*) HTTP/) {
        $year = $1;
        $month = $2;
        # print "YEAR: $year\n";
        # print "MONTH: $month\n";
    }
    my $html = get_calender_month::get_calender_month($year, $month);
    return $html;
}




1;