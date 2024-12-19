package get_change_email;

use strict;
use warnings;

sub get_change_email {
    my $translations = language_utils::load_language("email");

    my $html = <<HTML;
    <h1>$translations->{change_email}</h1>
    <label for="email">$translations->{email}</label>
    <input type="email" id="email" name="email" required>
    <button onclick="change_email()">$translations->{change_email}</button>
HTML

    my $script = <<JS;
    <script>
        function change_email() {
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
                        window.location.href = "/";
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
JS

    $html .= $script;

    my $html_content = html_structure::get_html($html, $translations->{change_email});
    
    return $html_content;
}

1;