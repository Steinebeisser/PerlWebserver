package register_html;

use strict;
use warnings;

sub get_register {

    my $translations = language_utils::load_language("register");

    my $html_body = <<HTML;
    <h1>$translations->{register}</h1>
    <form action="/register" method="post">
    $translations->{username}: <input type="text" name="username" maxlength="24" required><br>
    $translations->{password}: <input type="password" name="password" maxlength="24" required><br>
    <input type="submit" value="$translations->{register}">
    </form>
    <br>
    <a href="/ ">$translations->{returnToIndex}</a><br>
HTML


    my $html_content =  html_structure::get_html($html_body, "Register");


    return ($html_content);
}

1;