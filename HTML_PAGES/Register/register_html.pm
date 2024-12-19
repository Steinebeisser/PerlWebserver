package register_html;

use strict;
use warnings;

sub get_register {

    my $translations = language_utils::load_language("register");

    my $html_body = <<HTML;
    <h1>$translations->{register}</h1>
    $translations->{email}: <input type="email" name="email" maxlength="64" required><br>
    $translations->{username}: <input type="text" name="username" maxlength="24" required><br>
    $translations->{password}: <input type="password" name="password" maxlength="24" required><br>
    <button class="register" onclick="register()">$translations->{register}</button>
    <br>
    <a href="/ ">$translations->{returnToIndex}</a><br>
HTML

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

    function register() {
        var email = document.getElementsByName("email")[0].value;
        var username = document.getElementsByName("username")[0].value;
        var password = document.getElementsByName("password")[0].value;
        var fingerprint = getFingerprint();
        if (!email.includes('@') || !email.includes('.')) {
            alert('Invalid email address');
            return;
        }
        fetch("/register", {
            method: "POST",
            headers: {
            "Content-Type": "application/json",
            },
            body: JSON.stringify({
            email: email,
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

    my $html_content =  html_structure::get_html($html_body, "Register");


    return ($html_content);
}

1;