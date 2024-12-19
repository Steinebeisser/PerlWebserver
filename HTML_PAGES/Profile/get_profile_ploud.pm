package get_profile_ploud;

use strict;
use warnings;

sub get_profile_ploud {
    my ($username) = @_;

    my $human_username = user_utils::get_username_by_uuid(user_utils::get_uuid());

    my $translations = language_utils::load_language("profile");

    my $html_body = <<HTML;
    <h1>$translations->{profile}</h1>
    <br>
    <p>$translations->{username}: $human_username</p>
HTML

    $html_body .= html_utils::create_breadcrumbs("profile, ploud");
    
    $html_body .= <<HTML;
    <br>
    <div class="cloud_buttons">
        <a href="/profile/ploud/upload">$translations->{upload}</a>
    </div>
HTML

    $html_body .= html_utils::get_ploud_items();
    

    my $html_content = html_structure::get_html($html_body, "Profile");

    return ($html_content);
}

1;