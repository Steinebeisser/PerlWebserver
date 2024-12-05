package get_blog_create;

use strict;
use warnings;

sub get_blog_create {
    my $html = <<HTML;
    <h1>Create a blog</h1>
    <br>
    <form action="/blog/create" method="post">
        <input type="text" name="title" placeholder="Title">
        <br>
        <textarea name="content" placeholder="Content" class="blog_input_content"></textarea>
        <br>
        <input type="submit" value="Create Blog">
    </form>
    <br>
HTML

    my $html_content = html_structure::get_html($html, "Create a blog");

    return $html_content;
}
1;