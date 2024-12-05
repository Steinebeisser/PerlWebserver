package css_utils;

use strict;
use warnings;

sub get_css {
    my ($html_body, $footer) = @_;
    my $font_backs = get_font_backs();
    my $css = <<CSS;

    
    <style>
        \@font-face {
            font-family: 'Inter';
            font-weight: 400;
            src: url("${font_backs}fonts/Inter/Inter-Italic-VariableFont_opsz,wght.ttf") format('truetype'), 
                url("${font_backs}fonts/Inter/inter-v18-latin-regular.woff2") format('woff2');
                
        }
CSS

    if ($main::scheme eq "light") {
        $css .= <<CSS;    
        :root {  
            --font-family: 'Inter', Arial, sans-serif;
            --body-bg: white;
            --body-text: black;
            --body-text: #ffd178;
            --inline-link-bg: red;
            --inline-link-text: white;
            --inline-link-hover: blue;
            --admin-return-text: orange;
            --admin-return-bg: cyan;
            --inline-button-text: orange;
            --inline-button-bg: #4CAF50;
            --inline-button-blue-bg: lightblue;
            --inline-button-blue-text: purple;
            --inline-button-blue-hover: cyan;
            --a-bg: #4CAF50;
            --a-hover: #45a049;
            --text-on-bg: white;
            --th-bg: #4CAF50;
            --th-text: white;
            --tr-even: #f2f2f2;
            --month-bg: white;
            --month-text: #4CAF50;
            --month-hover: #388E3C;
            --footer-bg: #4CAF50;
            --footer-text: white;
            --calender-bg: #f5eed4;
            --blog-headline-bg: #D4D4D4;
            --blog-headline-text: #4900A8;
            --blog-view-bg: #305A5A;
        }
CSS
    } else {
        $css .= <<CSS;
        :root {
            --font-family: 'Inter', sans-serif;
            --body-bg: #2e2e2e;
            --body-text: #39ff14;
            --body-text: #ffd178;
            --inline-link-bg: red;
            --inline-link-text: white;
            --inline-link-hover: blue;
            --admin-return-text: #39ff14;
            --admin-return-bg: cyan;
            --inline-button-text: #2e2e2e;
            --inline-button-bg: #39ff14;
            --inline-button-blue-bg: #32cd32;
            --inline-button-blue-text: #39ff14;
            --inline-button-blue-hover: #00ff00;
            --a-bg: #39ff14;
            --a-hover: #32cd32;
            --text-on-bg: #2e2e2e;
            --th-bg: #39ff14;
            --th-text: #2e2e2e;
            --tr-even: #3a3a3a;
            --month-bg: #3a3a3a;
            --month-text: #39ff14;
            --month-hover: #32cd32;
            --footer-bg: #32cd32;
            --footer-text: #2e2e2e;
            --calender-bg: #f5eed4;
            --blog-headline-bg: #D4D4D4;
            --blog-headline-text: #4900A8;
            --blog-view-bg: #305A5A;
            --blog-view-text: #F8C7F9;
        }
CSS
    }

    $css .= <<CSS;
    body {
        font-family: var(--font-family);
        color: var(--body-text);
        background-color: #07192f;
        margin: 0;
        padding: 0;
        display: flex;
        flex-direction: column;
        min-height: 100vh;
        position: relative;
        overflow: auto;
    }

    html {
        height: 100%;
    }


    .vanta_bg {
        position: fixed;
        top: 0;
        left: 0;
        width: 100vw;
        height: 100vh;
        z-index: -1;
    }

    .main {
        flex: 1;
        z-index: 1;
    }
CSS



    if ($html_body =~ /class="inline_link"/ || $footer =~ /class="inline_link"/) { 
        $css .= <<CSS;
    .inline_link {
        display: inline;
        text-align: center;
        padding: 0;
        margin: 0;

    }
    .inline_link a {
        display: inline-block;
        margin: 0 10px;
        padding: 10px 20px;
        text-decoration: none;
        border-radius: 5px;
        width: 10%;
        background-color: var(--inline-link-bg);
        color: var(--inline-link-text);
        text-decoration: none;
        transition: background-color 0.3s ease;
    }
    .inline_link a:hover {
        background-color: var(--inline-link-hover);
    }
CSS
    }

    if ($html_body =~ /class="admin_return"/ || $footer =~ /class="admin_return"/) {
        $css .= <<CSS;
    .admin_return {
        text-align: center;
        display: inline-block;
        color: var(--admin-return-text);
        margin: 20px 0;
        width: 100%;
    }
    .admin_return a {
        width: 10%;
        display: inline-block;
        text-align: center;
        color: var(--admin-return-text);
        background-color: var(--admin-return-bg);
        text-decoration: none;
    }
CSS
    }

    if ($html_body =~ /class="inline_buttons"/ || $footer =~ /class="inline_buttons"/) {
        $css .= <<CSS;
    .inline_buttons {
        text-align: center;
        display: inline-block;
        margin: 20px 0;
        width: 100%;
    }
    .inline_buttons a {
        display: inline-block;
        background-color: var(--inline-button-bg);
        color: var(--inline-button-text);
        margin: 0 10px;
        padding: 10px 20px;
        text-decoration: none;
        border-radius: 5px;
        width: 10%;
        transition: background-color 0.3s ease;
    }
CSS
    }

    if ($html_body =~ /class="inline_buttons_test"/ || $footer =~ /class="inline_buttons_test"/) {
        $css .= <<CSS;
    .inline_buttons_test {
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 10px; 
        color: var(--text-color);

    }
    .inline_buttons_test form {
        text-align: center;
        color: var(--text-color);
        background-color: var(--bg-color-inline);
    }
CSS
    }

    if ($html_body =~ /<h1>/ || $footer =~ /<h1>/) {
        $css .= <<CSS;
        
    h1 {
        text-align: center;
        margin-top: 20px;
    }
CSS
    }

    if ($html_body =~ /<form/ || $footer =~ /<form/) {
        $css .= <<CSS;
    form {
        color: #39ff14;
    }
CSS
    }
    
    if ($html_body =~ /<h2>/ || $footer =~ /<h2>/) {
        $css .= <<CSS;
    h2 {
        text-align: center;
        margin-top: 20px;
    }
CSS
    }

    if ($html_body =~ /class="inline_buttons_blue"/ || $footer =~ /class="inline_buttons_blue"/) {
        $css .= <<CSS;
    .inline_buttons_blue {
        text-align: center;
        display: inline-block;
        margin: 20px 0;
        width: 100%;
    }
    .inline_buttons_blue a {
        display: inline-block;
        margin: 0 10px;
        padding: 10px 20px;
        text-decoration: none;
        background-color: var(--inline-button-blue-bg);
        color: var(--inline-button-blue-text);
        border-radius: 5px;
        width: 10%;
        transition: background-color 0.3s ease;
        background-color: var(--inline-button-blue-bg);
    }
    .inline_buttons_blue a:hover {
    }
CSS
    }

    if ($html_body =~ /<a href/ || $footer =~ /<a href>/) {
        $css .= <<CSS;
    a {
        display: block;
        text-align: center;
        margin: 10px auto;
        padding: 10px 20px;
        background-color: var(--a-bg);
        color: var(--text-on-bg);
        text-decoration: none;
        border-radius: 5px;
        transition: background-color 0.3s ease;
        width: 20%;
    }
    a:hover {
        background-color: var(--a-hover);
    }
CSS
    }

    if ($html_body =~ /<form/ || $footer =~ /<form/) {
        $css .= <<CSS;
    form {
        text-align: center;
    }
CSS
    }
    
    if ($html_body =~ /<p/ || $footer =~ /<p/) {
        $css .= <<CSS;
    p {
        text-align: center;
    }
CSS
    }
    
    if ($html_body =~ /<ul/ || $footer =~ /<ul/) {
        $css .= <<CSS;
    ul {
        list-style-type: none;
        padding: 0;
        margin: 0;
    }
    li {
        margin: 10px 0;
        text-align: center;
    }
CSS
    }
    
    if ($html_body =~ /<table/ || $footer =~ /<table/) {
        $css .= <<CSS;
    table {
        margin: 20px auto;
        border-collapse: collapse;
        width: 60%;
    }
    td {
        padding: 8px;
        text-align: left;
        border-bottom: 1px solid #ddd;
    }
    th {
        background-color: var(--th-bg);
        color: var(--th-text);
    }
    tr:nth-child(even) {
        background-color: var(--tr-even);
    }
CSS
    }
    if ($html_body =~ /class="back_button"/ || $footer =~ /class="back_button"/) {
        $css .= <<CSS;
    .back_button {
        position: absolute;
        top: 15;
        left: 0;
    }
    .back_button a {
        width: 100%;
    }
CSS
    }

    if ($html_body =~ /class="calender"/ || $footer =~ /class="calender"/) {
        $css .= <<CSS;
    .calender {
        width: 100%;
        background-color: var(--calender-bg);
    }
    .top_calender {
        display: flex;
        justify-content: space-around;
        align-items: center;
    }
    .month_button {
        display: inline-block;
        margin: 10px;
        width: calc(25% - 20px - 20px / 4); 
        box-sizing: border-box;
        aspect-ratio: 1 / 0.5; 
        background-color: #f0f0f0; 
    }
    .month_button:hover .day {
        color: #e0e0e0;
    }
    .month_button:hover .day.holiday {
        color: red;
    }
    .week_days {
        display: flex;
        justify-content: space-around;
    }
    .days {
        display: flex;
        width: 100%;
        justify-content: space-around;
        flex-wrap: wrap;
        color: #357c38;
    }
    .day {
        width: calc(100% / 7 );
        text-align: center;
    }
    .day.holiday {
        color: red;
    }
    .inline_buttons_test {
        background-color: #a8a391;

    }
    .month_button a {
        width: 100%;
        height: 100%;
        margin: 0;
        padding: 0;
        text-align: center;
        transition: transform 0.2s ease, box-shadow 0.2s ease;
        background-color: var(--month-text); 
        text-decoration: none; 
        color: var(--month-bg);
    }

CSS
    }
    
    if ($html_body =~ /class="footer"/ || $footer =~ /class="footer"/) {
        $css .= <<CSS;
    .footer {
        position: relative;
        bottom: 0;
        width: 100%;
        margin-top: 20px;
        display: inline-block;
        text-align: center;
        background-color: var(--footer-bg);
        color: var(--footer-text);
    }
    .language_form {
        text-align: center;
        color: #000000;
        margin: 20px 0;
    }
    .language_form p {
        color: var(--footer-color);
    }
    form {
        color: var(--footer-color);
    }
CSS
    }
    
    if ($html_body =~ /<class="language_form">/ || $footer =~ /<class="language_form">/) {
        $css .= <<CSS;
    .language_form {
        text-align: center;
        color: var(--footer-color);
        margin: 20px 0;
    }
CSS
    }

    if ($html_body =~ /class="userCount"/ || $footer =~ /class="userCount"/) {
        $css .= <<CSS;
    .userCount {
        position: absolute;
        top: 0;
        right: 10px;

    }
CSS
    }


    if ($html_body =~ /class="ploud"/ || $footer =~ /class="ploud"/) {
        $css .= <<CSS;
    .ploud {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
    }
    .ploud table {
        width: 60%;
    }
    .ploud th {

    }
    .ploud td {
        text-align: center;
    }
    .ploud td a {
        width: auto;
    }
CSS
    }

    if ($html_body =~ /class="no-input-layer"/ || $footer =~ /class="no-input-layer"/ 
        || $html_body =~ /id="no-input-layer"/ || $footer =~ /class="no-input-layer"/) {
        $css .= <<CSS;
    .no-input-layer {
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background-color: rgba(0, 0, 0, 0.5);
        z-index: 1000;
    }
CSS
    }

    if ($html_body =~ /class="breadcrumbs"/ || $footer =~ /class="breadcrumbs"/) {
        $css .= <<CSS;
    .breadcrumbs {
        position: absolute;
        top: 0;
        left: 0;
        width: 20%;
        display: flex;
        align-items: left;
        justify-content: left;
        margin-right: auto;
        padding: 5px;
    }
    .breadcrumbs a {
        margin: 0 5px;

    }
CSS
    }


#     if ($html_body =~ /class="ploud_item"/ || $footer =~ /class="ploud_item"/) {
#         $css .= <<CSS;
#     .ploud_item {
#         display: flex;
#         justify-content: center;
#         align-items: center;
#         background-color: #f0f0f0;
#         width: 60%;

#     }
#     .ploud_item util_buttons {
#         display: flex;
#     }
#     .ploud_item p {
#         display: flex;
#         align-items: center;
#         margin-left: auto;
#     }
#     .util_buttons {
#         display: flex;
#         justify-content: center;
#         width: auto;
#         margin-left: auto;
#     }

#     .util_buttons a {
#         width: auto;
#         margin: 5px;
#     }
# CSS
#     }

    if ($html_body =~ /class="ploud_upload_form"/ || $footer =~ /class="ploud_upload_form"/) {
        $css .= <<CSS;
    .ploud_upload_form:active{
        transform: scale(0.98);

    }

CSS
    }

    if ($html_body =~ /class="blog_top_bar_account"/ || $footer =~ /class="blog_top_bar_account"/) {
        $css .= <<CSS;
    .blog_top_bar_account {
        display: flex;
        justify-content: end;
        width: 60%;
        margin-left: auto;
    }
    .blog_top_bar_account a {
        margin: 3px;
        justify-content: center;
        display: flex;
    }
CSS
    }


    if ($html_body =~ /class="blog_top_bar_post"/ || $footer =~ /class="blog_top_bar_post"/) {
        $css .= <<CSS;
    .blog_top_bar_post {
        width: 60%;
        justify-content: center;
        display: flex;
        align-items: center;
        margin: auto;

    }
    .blog_top_bar_post a {
    }
CSS
    }

    if ($html_body =~ /class="blog_logo"/ || $footer =~ /class="blog_logo"/) {
        $css .= <<CSS;
    .blog_logo {
        margin-bottom: 8%;
    }
CSS
    }

    if ($html_body =~ /class="blog_body"/ || $footer =~ /class="blog_body"/) {
        $css .= <<CSS;
    .blog_body {
        width: 90%;
        margin: auto;
        border: 5px black solid;
        background-color: #545454;
    }
    .block_body h1 {
        color: #4900A8;
    }
CSS
    }

    if ($html_body =~ /class="official_announcements"/ || $footer =~ /class="official_announcements"/) {
        $css .= <<CSS;
    .official_announcements {
        width: 95%;
        margin: 10px auto;
        background-color: var(--blog-headline-bg);
    }
    .official_announcements h2 {
        color: var(--blog-headline-text);
    }
CSS
    }

    if ($html_body =~ /class="official_announcement"/ || $footer =~ /class="official_announcement"/) {
        $css .= <<CSS;
    .official_announcement {
        width: 90%;
        margin: 10px auto;
        border: 5px gray solid;
        background-color: #2e2e2e;
        display: flex;
        flex-wrap: wrap;
    }
    .official_announcement_content {
        display: flex;
        width: 100%;
        margin: auto;
    }
    .official_announcement_title a{
        width: auto;
    }
    .official_announcement_title {
        width: 100%;
    }
    .official_announcement_creation {
        display: flex;
    }
    .official_announcement_stats {
        display: flex;
        margin-left: auto;
    }
    .official_announcement a {
        background-color: beige;
        margin: 10px;
    }
    .official_announcement p {
        margin: 10px;
        text-align: inherit;
    }
CSS
    }

if ($html_body =~ /class="blog_post"/ || $footer =~ /class="blog_post"/) {
    $css .= <<CSS;
    .blog_post {
        width: 90%;
        margin: 10px auto;
        border: 5px gray solid;
        background-color: #2e2e2e;
        display: flex;
        flex-wrap: wrap;
    }
    .blog_post_content {
        display: flex;
        width: 100%;
        margin: auto;
    }
    .blog_post_title a {
        width: auto;
    }
    .blog_post_title {
        width: 100%;
    }
    .blog_post_creation {
        display: flex;
    }
    .blog_post_stats {
        display: flex;
        margin-left: auto;
    }
    .blog_post a {
        background-color: beige;
        margin: 10px;
    }
    .blog_post p {
        margin: 10px;
        text-align: inherit;
    }
CSS
    }


    if ($html_body =~ /class="blog_top_bar"/ || $footer =~ /class="blog_top_bar"/) {
        $css .= <<CSS;
    .blog_top_bar {
        background-color: var(--blog-headline-bg);
        width: 95%;
        margin: 20px auto;

    }
    .blog_top_bar h1 {
        color: var(--blog-headline-text);
    }

CSS
    }

    if ($html_body =~ /class="blog_input_content"/ || $footer =~ /class="blog_input_content"/) {
        $css .= <<CSS;
    .blog_input_content {
        overflow: auto;
        resize: none;
    }
CSS
    }

    if ($html_body =~ /class="manage_announcement"/ || $footer =~ /class="manage_announcement"/) {
        $css .= <<CSS;
    .manage_announcement {
        width: 90%;
        margin: 10px auto;
        border: 5px gray solid;
        background-color: #2e2e2e;
        display: flex;
        flex-wrap: wrap;
    }
CSS
    }

    if ($html_body =~ /class="announcement_manage_buttons"/ || $footer =~ /class="announcement_manage_buttons"/) {
        $css .= <<CSS;
    .announcement_manage_buttons {
        display: flex;
        margin-left: auto;
    }
    .announcement_manage_buttons a {
        background-color: orange;
        margin: 10px;
    }
    .status {
        display: block;
        width: 100%;
    }
CSS
    }

    if ($html_body =~ /class="original_post"/ || $footer =~ /class="original_post"/) {
        $css .= <<CSS;
    .original_post {
        display: flex;
        width: 80%;
        margin: auto;
        background-color: var(--blog-view-bg);
        color: var(--blog-view-text);
        flex-wrap: wrap;
    }
    .original_post_title {
        width: 100%;
        text-align: center;
    }
    .left_side {
        width: 15%;
    }
    .post_text {
        width: 70%;
    }
    .user_info {
        margin-left: auto;
        width: 15%;
    }

CSS
    }



#     if ($html_body =~ /<button/ || $footer =~ /<button/) {
#         $css .= <<CSS;
#     button {
#         background-color: #4CAF50;
#         color: white;
#         font-size: 16px;
#         cursor: pointer;
#     }
# CSS
#     }

    if ($html_body =~ /class="memory_field"/ || $footer =~ /class="memory_field"/) {
        $css .= <<CSS;
    .memory_field {
        width: 20%;
        margin: 2% auto;
        background-color: brown;
        aspect-ratio: 1;
        align-items: center;
        display: flex;
        justify-content: center;
        border: 0px;
    }
    .memory_game {
        width: 40%;
        margin: auto;
    }
    .memory_row {
        display: flex;
        justify-content: center;
    }
    .memory_field:hover {
        transition-property: all;
        transition-duration: 0.3s;
        transition-timing-function: ease;
        background-color: #721d1d;
        transform: scale(1.1);
    }
    .memory_field:active {
        background-color: purple;
    }
CSS
    }

    if ($html_body =~ /class="memory_frame"/ || $footer =~ /class="memory_frame"/) {
    $css .= <<CSS;
    .memory_frame {
        display: flex;
    }
    .player1_container {
        margin-left: auto;
    }
    .player2_container {
        margin-right: auto;
    }
CSS
    }

    $css .= "</style>";
    return $css;
}


sub get_font_backs {
    $main::header =~ /(.*) HTTP/;
    my $get_request = $1;
    my $count = 0;
    while ($get_request =~ /\//g) {
        $count++;
    }
    return "../" x $count;
}
1;

