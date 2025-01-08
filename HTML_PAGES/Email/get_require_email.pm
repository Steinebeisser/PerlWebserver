package get_require_email;

use strict;
use warnings;

use Cwd;
use JSON;

sub get_require_email {
    my $translations = language_utils::load_language("email");
    # print("TRANSLATIONS: $translations\n");
    my $html_body = <<HTML;
    <h1>$translations->{youNoEmail}</h1>

    $translations->{email}: <input type="email" name="email" maxlength="64" required><br>
    <button class="submit" onclick="sendEmailVerification()">$translations->{sendVerification}</button>
    <br>
    <form action="/logout" method="post"><input type="submit" value="$translations->{logout}"></form>
HTML

    my $script = <<Script;
    <script>
        function sendEmailVerification() {
            var email = document.getElementsByName("email")[0].value;
            if (!email) {
                alert("$translations->{emailEmpty}");
                return;
            }
            if (!email.includes('\@') || !email.includes('.')) {
                alert('Invalid email address');
                return;
            }
            fetch("/add/email", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                },
                body: JSON.stringify({
                    email: email,
                }),
            }).then(response => {
                if (response.ok) {
                    location.reload();
                } else {
                    response.text().then(html => {
                        document.open();
                        document.write(html);
                        document.close();
                    });
                }
            });
        }
    </script>
Script

    $html_body .= $script;

    my $title = $translations->{addingEmail};
    # print("Title: $title\n");
    my $html_content = html_structure::get_html($html_body, $title);

    return ($html_content);
}

1;