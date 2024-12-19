package registered_html;

use strict;
use warnings;

sub get_registered {
    my ($username) = @_;

    my $html_body = <<HTML;
    <h1>Registered $username</h1>
    <br>
    <p>Click on the link in the email to activate your account</p>
    <a href="/ ">Return to index</a>
    <br>
HTML

    my $html_content =  html_structure::get_html($html_body, "User registered");

    return ($html_content);
}
1;