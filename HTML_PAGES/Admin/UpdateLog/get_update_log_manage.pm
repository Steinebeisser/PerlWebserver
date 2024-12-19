package get_update_log_manage;

use strict;
use warnings;

sub get_update_log_manage {

    my $translations = language_utils::load_language("updateLog");

    my @update_log = update_log::get_update_log(1);

    my $html_body = <<HTML;
    <h1>$translations->{updateLog}</h1>
    <div class="add_update_log">
        <a href="/admin/updateLog/add">$translations->{add}</a>
    </div>
    <br>
HTML
    
    foreach my $update (@update_log) {
        my $date = $update->{date};
        my $title = $update->{title};
        my $id = $update->{id};
        # my $description = $update->{description};

        $html_body .= <<HTML;
        <div class="manageUpdate">
            <h2>$title - $date</h2>
HTML
    if ($update->{additionalInfo}) {
        my $additionalInfo = $update->{additionalInfo};
        $html_body .= <<HTML;
            <p>$additionalInfo</p>
HTML
    }
        $html_body .= <<HTML;
            <a href="/admin/updateLog/edit/$id">$translations->{edit}</a>
            <a href="/admin/updateLog/delete/$id">$translations->{delete}</a>
HTML

        $html_body .= <<HTML;
        </div>
HTML
    }

    $html_body .= html_utils::create_breadcrumbs("updateLog");

    my $html_content = html_structure::get_html($html_body, "Update Log");

    return $html_content;
}

1;