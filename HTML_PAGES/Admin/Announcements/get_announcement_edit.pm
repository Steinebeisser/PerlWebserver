package get_announcement_edit;

use strict;
use warnings;

sub get_announcement_edit {
    my ($announcement, $client_socket) = @_;
    my $user = $main::user;
    if ($user->{role} ne "admin") {
        return 0;
    }
    if (!$main::user) {
        return 0;
    }

    my $translations = language_utils::load_language("admin");

    my $is_announcement = 1;
    my $announcement_data = blog_utils::get_blog_data($announcement, $is_announcement);
    if (!$announcement_data) {
        main::serve_error($client_socket, HTTP_RESPONSE::ERROR_404("Announcement not found"));
        return;
    }

    my $html_body = html_utils::get_blog_top_bar_account();
    $html_body .= html_utils::create_breadcrumbs("blog, announcements/manage, edit/$announcement_data->{title}");

    $html_body .= <<HTML;
    <form action="/admin/announcements/edit/$announcement_data->{title}" method="post" id="announcementForm">
        <input type="text" name="title" placeholder="title" value="$announcement_data->{title}">
        <br>
        <textarea name="content" placeholder="content" class="blog_input_content">$announcement_data->{content}</textarea>
        <br>
        <input type="submit" value="submit">
    </form>

HTML

    my $html_content = html_structure::get_html($html_body, "Edit Announcement");

    return $html_content;
}

1;