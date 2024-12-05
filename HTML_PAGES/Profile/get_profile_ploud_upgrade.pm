package get_profile_ploud_upgrade;

use strict;
use warnings;

sub get_profile_ploud_upgrade {
    my ($username) = @_;

    my $human_username = utils::get_username();

    my $translations = language_utils::load_language("profile, ploud");

    print("UPGRADEEEEEEEEE\n");

    my $html_body = <<HTML;
    <h1>$translations->{ploud}</h1>
    <br>
    <p>$translations->{username}: $human_username</p>
HTML

    $html_body .= html_utils::create_breadcrumbs("profile, ploud, upgrade");


    $html_body .= html_utils::show_ranks();

    

    my $html_content = html_structure::get_html($html_body, "Profile");

    return ($html_content);
}

1;