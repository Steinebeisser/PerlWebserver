package get_announcement_create;

use strict;
use warnings;

sub get_announcement_create {
    my ($client_socket, $request) = @_;

    my $user = $main::user;
    if ($user->{role} ne "admin") {
        return 0;
    }
    if (!$main::user) {
        return 0;
    }

    my $html_body = <<HTML;
    <h1>Create Announcement</h1>
    <br>
    <form action="/blog/announcement/create" method="post">
        <input type="text" name="title" placeholder="title">
        <br>
        <textarea name="content" placeholder="content" class="blog_input_content"></textarea>
        <br>
        <input type="submit" value="submit">
    </form>
    <br>
HTML
    
    my $html_content = html_structure::get_html($html_body, "Create Announcement");

    return $html_content;
}

1;