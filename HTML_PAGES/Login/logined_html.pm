package logined_html;

use strict;
use warnings;

sub new {
    my ($username) = @_;

    my $translations = language_utils::load_language("login");
    print("LOGOGO\n");

    if (user_utils::is_encoded($username)) {
        $username = user_utils::decode_uri($username);
    }
    my $html_body = <<HTML;
    <h1>$translations->{welcome} $username</h1>
    <br>
    <a href="/ ">$translations->{returnToIndex}</a>
    <br>
HTML

    $html_body .= html_utils::create_breadcrumbs("login");
    
    my $html_content =  html_structure::get_html($html_body, "$translations->{loggedIn}");

    return ($html_content);
}

1;