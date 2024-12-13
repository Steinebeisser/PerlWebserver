package update_log_html;

use strict;
use warnings;

sub update_log_html {
    my $translations = language_utils::load_language("updateLog");

    my @update_log = update_log::get_update_log();

    my $html_body = <<HTML;
    <h1>$translations->{updateLog}</h1>
    <br>
HTML
    
    foreach my $update (@update_log) {
        my $date = $update->{date};
        my $description = $update->{description};
        my $title = $update->{title};

        $html_body .= <<HTML;
        <div class="update">
            <div class="title">
                $title    
            </div>
            <div class="updateBody">
                <div class="description">
                    $description
                </div>
                <div class="date">
                    $date
                </div>

HTML
    if ($update->{additionalInfo}) {
        my $additionalInfo = $update->{additionalInfo};
        $html_body .= <<HTML;
                <div class="additionalInfo">
                    $additionalInfo
                </div>
HTML
    }
        $html_body .= <<HTML;
            </div>
        </div>
HTML
    }

    $html_body .= html_utils::create_breadcrumbs("updateLog");

    my $html_content = html_structure::get_html($html_body, "Update Log");

    return $html_content;
}

1;