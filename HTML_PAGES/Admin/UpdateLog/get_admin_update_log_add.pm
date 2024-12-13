package get_admin_update_log_add;

use strict;
use warnings;

sub get_admin_update_log_add {
    my $translations = language_utils::load_language("updateLog");

    my $html_body = <<HTML;
    <h1>$translations->{add}</h1>
    <form action="/admin/updateLog/add" method="post">
        $translations->{title}: <input type="text" name="title" required><br>
        $translations->{description}: <input type="text" name="description" required><br>
        $translations->{additionalInfo}: <input type="text" name="additionalInfo"><br>
        <input type="submit" value="$translations->{add}">
    </form>
    <br>
    <a href="/admin/updateLog">$translations->{return}</a>
HTML
}

1;