package get_blog_view;

use strict;
use warnings;

sub get_blog_view {
    my ($blog_name, $client_socket, $is_announcement) = @_;

    my $translations = language_utils::load_language("blog");

    my $html_body = html_utils::get_blog_top_bar_account($translations);

    my $blog_name_decoded = user_utils::decode_uri($blog_name);
    $html_body .= html_utils::create_breadcrumbs("blog, view/$blog_name_decoded");

    $html_body .= html_utils::get_blog_logo();

    my $human_blog_name = user_utils::decode_uri($blog_name);
    my $blog_data = blog_utils::get_blog_data($blog_name, $is_announcement);
    if (!$blog_data) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_404("Blog not found"));
        return;
    }
    $html_body .= <<HTML;
    <h1>$human_blog_name</h1>
HTML
    # print("Blog data: $blog_data\n");
    my $blog_content = user_utils::decode_uri($blog_data->{content});
    $html_body .= <<HTML;
    <div class="original_post">
        <div class="original_post_title">
            $human_blog_name
        </div>
        <div class="left_side">
            <div class="post_views">
                $translations->{views}: $blog_data->{views}
            </div>
        </div>
        <div class="post_text">
            <div class="original_post_content">
                $blog_content
            </div>
        </div>
        <div class="user_info">
            <div class="user_profile_pic">
                <img src="" alt="$translations->{profilePic}">
            </div>
            <div class="user_name">
HTML
    my $author = user_utils::decode_uri($blog_data->{author});
    $html_body .= <<HTML;
                $translations->{author}: $author
            </div>
            <div class="post_date">
                $translations->{createdAt}: $blog_data->{date}
            </div>
            <div class="cool_stuff">
            </div>
        </div>
    </div>
HTML

    my $page_name ="Announcement";
    $page_name = "Blog" if (!$is_announcement);

    
    my $html_content = html_structure::get_html($html_body, $page_name);

    return ($html_content);
}

1;