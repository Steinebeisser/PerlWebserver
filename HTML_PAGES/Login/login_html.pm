package login_html;

use strict;
use warnings;

sub get_login {

    my $translations = language_utils::load_language("login");

    my $html_body = <<HTML;
    <h1>$translations->{login}</h1>
    $translations->{username}: <input type="text\" name="username" maxlength="24" required><br>
    $translations->{password}: <input type="password" name="password" maxlength="24" required><br>
    <button class="login" onclick="login()">$translations->{login}</button>
    <br>
    <a href="/ ">$translations->{returnToIndex}</a><br>
HTML

    $html_body .= html_utils::create_breadcrumbs("login");

my $script = <<'Script';
<script>
    function getFingerprint() {
        return {
            platform: navigator.platform,
            userAgent: navigator.userAgent,
            languages: navigator.languages,
            timezone: Intl.DateTimeFormat().resolvedOptions().timeZone, 
        };
    }

    function login() {
        var username = document.getElementsByName("username")[0].value;
        var password = document.getElementsByName("password")[0].value;
        var fingerprint = getFingerprint();
        
        fetch("/login", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
            },
            body: JSON.stringify({
                username: username,
                password: password,
                fingerprint: fingerprint,
            }),
        })
        .then(response => response.text())
        .then(html => {
            document.open();
            document.write(html);
            document.close();
        })
        .catch(error => {
            console.error('Error:', error);
        });
    }
</script>
Script


    $html_body .= $script;

    my $html_content =  html_structure::get_html($html_body, "Login");

    return ($html_content);
}

1;