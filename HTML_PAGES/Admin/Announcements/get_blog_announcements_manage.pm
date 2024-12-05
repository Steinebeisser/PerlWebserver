package get_blog_announcements_manage;

use strict;
use warnings;

sub get_blog_announcements_manage {
    my $user = $main::user;
    if ($user->{role} ne "admin") {
        return 0;
    }
    if (!$main::user) {
        return 0;
    }

    my $html_body = <<HTML;
    <h1>Manage Announcements</h1>
    <br>
    <a href="/blog/announcement/create">Create Announcement</a>
    <br>
HTML

    $html_body .= html_utils::create_breadcrumbs("blog, announcements/manage");

    my $get_all = 1;
    my @announcements = blog_utils::get_official_announcements($get_all);
    if (@announcements) {
        $html_body .= <<HTML;
        <div class="announcements">
            <h2>Announcements</h2>

HTML
    }
    foreach my $announcement (@announcements) {
        print("Announcement: $announcement\n");
        my $status = defined $announcement->{active} && $announcement->{active} eq "true" ? "Active" : "Deactivated";

        $html_body .= <<HTML;
            <div class="manage_announcement">
                <h3>$announcement->{title}</h3>
                <div class="announcement_manage_buttons">
                    <a href="/blog/view/announcement/$announcement->{title}">View</a>
                    <a href="/blog/announcement/edit/$announcement->{title}">Edit</a>
HTML
        if ($announcement->{active} eq "true") {
            $html_body .= <<HTML;
                    <a href="/blog/announcement/deactivate/$announcement->{title}">Deactivate</a>
HTML
        } else {
            $html_body .= <<HTML;
                    <a href="/blog/announcement/activate/$announcement->{title}">Activate</a>
HTML
        }
        $html_body .= <<HTML;
                    <a href="/blog/announcement/delete/$announcement->{title}">Delete</a>
                </div>
                <div class="status">
                    Status: $status
                </div>
            </div>
                
HTML
    }
    if (@announcements) {
        $html_body .= <<HTML;
        </div>
HTML
    }

    
    my $html_content = html_structure::get_html($html_body, "Manage Announcements");

    return $html_content;
}

1;