package login_html;

use strict;
use warnings;

sub get_login {

    my $translations = language_utils::load_language("login");

    my $html_body = <<HTML;
    <h1>$translations->{login}</h1>
    <form action="/login" method="post">
    $translations->{username}: <input type="text\" name="username" maxlength="24" required><br>
    $translations->{password}: <input type="password" name="password" maxlength="24" required><br>
    <input type="submit" value="$translations->{login}">
    </form>
    <br>
    <a href="/ ">$translations->{returnToIndex}</a><br>
HTML

    $html_body .= html_utils::create_breadcrumbs("login");

    my $html_content =  html_structure::get_html($html_body, "Login");

    return ($html_content);
}

1;