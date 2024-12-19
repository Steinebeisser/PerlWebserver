package profile_html;

use strict;
use warnings;


sub get_profile {
    my $username = user_utils::decode_uri(user_utils::get_username_by_uuid(user_utils::get_uuid()));


    my $translations = language_utils::load_language("profile");

    if (!$main::user) {
        return 0;
    } 

    my $html_body = <<HTML;
    <h1>Profile</h1>
    <br>
    <p>$translations->{username}: $username</p>
    <p>$translations->{email}: </p>
    <p>$translations->{phone}: </p>
    <p>$translations->{address}: </p>
    <br>
    <a href="/profile/ploud">$translations->{ploud}</a>
    <a href="/logout">$translations->{logout}</a>
    <br>
    <br>
    <a href="/ ">$translations->{returnToIndex}</a>
    <br>
HTML

    $html_body .= html_utils::create_breadcrumbs("profile");

    my $html_content = html_structure::get_html($html_body, "Profile");

    return ($html_content);
}

1;