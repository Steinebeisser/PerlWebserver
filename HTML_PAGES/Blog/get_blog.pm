package get_blog;

use strict;
use warnings;

sub get_blog {
    my ($page, $sort_type) = @_;
    # print("SORT TYPE: $sort_type\n");
    my $translations = language_utils::load_language("blog, login, register");
    
    my $html_body = html_utils::get_blog_top_bar_account($translations);

    $html_body .= html_utils::create_breadcrumbs("blog");
    
    $html_body .= html_utils::get_blog_logo();

    $html_body .= <<HTML;
    <div class="blog_body">
        <div class="inner_blog_body">
            <div class="blog_top_bar">
                <h1>Blog</h1>
                <div class="blog_top_bar_post">
                    <a href="/blog">$translations->{posts}</a>
                    <a href="/blog/?sort=newest">$translations->{newest}</a>
                    <a href="/blog/create">$translations->{createPost}</a>
HTML
    if ($main::user->{role} eq "admin") {
        $html_body .= <<HTML;
                    <a href="/blog/announcements/manage">$translations->{announcements}</a>
HTML
    }
    $html_body .= <<HTML;
                </div>  
            </div>
            <div class="sort_type">
                <form action="/blog/" method="get">
                    <label for="sort">$translations->{sortBy}</label>
                    <select name="sort" id="sort">
                        <option value="newest">$translations->{newest}</option>
                        <option value="oldest">$translations->{oldest}</option>
                        <option value="views">$translations->{views}</option>
                        <option value="alphabetical">$translations->{alphabetical}</option>
                    </select>
                    <input type="submit" value="$translations->{sort}">
                </form>
            </div>
HTML
    my @official_announcements = blog_utils::get_official_announcements();
    if (@official_announcements) {
        $html_body .= <<HTML;
            <div class="official_announcements">
                <h2>$translations->{officialAnnouncements}</h2>
HTML
    }
    foreach my $announcement (@official_announcements) {
        $html_body .= <<HTML;
                <div class="official_announcement">
                    <div class="official_announcement_content">
                        <div class="official_announcement_title">
                            <a href="/blog/view/announcement/$announcement->{title}">$announcement->{title}</a>
                        </div>
                    </div>
                    <div class="official_announcement_creation">
                        <div class="official_announcement_author">
HTML
    my $author = user_utils::decode_uri($announcement->{author});
    $html_body .= <<HTML;
                            <p>$translations->{author}: $author</p>
                        </div>
                        <div class="official_announcement_created">
                            <p>$translations->{createdAt}: $announcement->{date}</p>
                        </div>
                    </div>
                    <div class="official_announcement_stats">
                        <div class="official_announcement_views">
                            <p>$translations->{views}: $announcement->{views}</p>
                        </div>
HTML
    if ($announcement->{lastEdited} ne "") {
        $author = user_utils::decode_uri($announcement->{lastEditedBy});
        $html_body .= <<HTML;
                        <div class="official_announcement_last_edited">
                            <p>$translations->{lastEdited}: $announcement->{lastEdited} - $author</p>
                        </div>
HTML
    }
        $html_body .= <<HTML;
                    </div>
                </div>
HTML
    }
    $html_body .= <<HTML;
            </div>
HTML
    # print("SORTY TIPE: $sort_type\n");
    my @blog_posts = blog_utils::get_blog_posts($page, $sort_type);
    if (@blog_posts) {
        $html_body .= <<HTML;
            <div class="blog_posts">
                <h2>$translations->{posts}</h2>
                <div class="inline_buttons_test">
HTML
    if ($page > 1) {
        my $page_before = $page - 1;
        $html_body .= <<HTML;
                    <form action="/blog/" method="get">
                        <input type="hidden" name="page" value="$page_before">
                        <input type="submit" value="<-">
                    </form>
HTML
    }
        my $page_after = $page + 1;
        $html_body .= <<HTML;
                    <h2>$translations->{page}: $page</h2>
                    <form action="/blog/" method="get">
                        <input type="hidden" name="page" value="$page_after">
                        <input type="submit" value="->">
                    </form>
                </div>
HTML
    }
    foreach my $post (@blog_posts) {
        $html_body .= <<HTML;
                <div class="blog_post">
                    <div class="blog_post_content">
                        <div class="blog_post_title">
                            <a href="/blog/view/$post->{title}">$post->{title}</a>
                        </div>
                    </div>
                    <div class="blog_post_creation">
                        <div class="blog_post_author">
HTML
    my $author = user_utils::decode_uri($post->{author});
    $html_body .= <<HTML;
                            <p>$translations->{author}: $author</p>
                        </div>
                        <div class="blog_post_created">
                            <p>$translations->{createdAt}: $post->{date}</p>
                        </div>
                    </div>
                    <div class="blog_post_stats">
                        <div class="blog_post_views">
                            <p>$translations->{views}: $post->{views}</p>
                        </div>
HTML
    if ($post->{lastEdited} ne "") {
        $author = user_utils::decode_uri($post->{lastEditedBy});
        $html_body .= <<HTML;                       
                        <div class="blog_post_last_edited">
                            <p>$translations->{lastEdited}: $post->{lastEdited} - $author</p>
                        </div>
HTML
    }
        $html_body .= <<HTML;
                    </div>
                </div>
                
HTML
    }
    $html_body .= <<HTML;
                <div class="inline_buttons_test">
HTML
    if ($page > 1) {
        my $page_before = $page - 1;
        $html_body .= <<HTML;
                    <form action="/blog/" method="get">
                        <input type="hidden" name="page" value="$page_before">
                        <input type="submit" value="<-">
                    </form>
HTML
    }
        my $page_after = $page + 1;
        $html_body .= <<HTML;
                    <h2>$translations->{page}: $page</h2>
                    <form action="/blog/" method="get">
                        <input type="hidden" name="page" value="$page_after">
                        <input type="submit" value="->">
                    </form>
                </div>
            </div>
        </div>
    </div>
HTML


    my $html_content = html_structure::get_html($html_body, "Blog");

    return ($html_content);
}

1;