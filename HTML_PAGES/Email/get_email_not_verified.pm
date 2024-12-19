package get_email_not_verified;

use strict;
use warnings;

sub get_email_not_verified {
    my $email = $main::user->{email};
    my $starred_email = star_email($email);
    my $html_body = <<HTML;
    <h1>Email not verified</h1>
    <br>
    <p>Your email has not been verified yet. Please check your email "($starred_email)" for a verification link.</p>
    <br>
    <p>If you did not receive an email, you can request a new one by clicking <button onclick="resendVerificationEmail()">here</button></p>
    <p>If you would like to change your email, you can do so by clicking <a href="/change_email">here</a>.<br>
    You can also unlink your email by clicking <form action="/unlink_email" method="post"><input type="submit" value="here"></form></p>
    <form action="/logout" method="post"><input type="submit" value="Logout"></form>
    <br>
HTML
    
    my $script = <<'Script';
    <script>
        function resendVerificationEmail() {
            fetch("/resend_verification_email", {
                method: "POST",
            }).then(response => {
                if (response.ok) {
                    alert("Verification email sent");
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
    
    my $html_content = html_structure::get_html($html_body, "Email not verified");

    return ($html_content);

}
sub star_email {
    my ($email) = @_;

    my ($username, $domain) = split('@', $email);
    my $starred_username = substr($username, 0, 3) . '*****';
    my $starred_email = "$username\@$domain";
    return "$starred_username\@$domain";
}

1;