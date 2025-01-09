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
            --body-bg: #c4d8ed;
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
            --body-bg: #07192f;
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
        background-color: var(--body-bg);
        margin: 0;
        padding: 0;
        display: flex;
        flex-direction: column;
        min-height: 100vh;
        position: relative;
        overflow: auto;
        text-align: center;
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
        display: flex;
        flex-direction: column;
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
    .footer {
        margin-top: 20px;
    }

CSS
    }
    
    if ($html_body =~ /class="footer"/ || $footer =~ /class="footer"/) {
        $css .= <<CSS;
    .footer {
        position: relative;
        bottom: 0;
        width: 100%;
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
        width: 30%;
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

    if ($html_body =~ /class="memory_end_frame"/ || $footer =~ /class="memory_end_frame"/) {
        $css .= <<CSS;
    .vs_frame {
        margin: auto;
        justify-content: space-between;
        width: 60%;
        flex-wrap: wrap;
        display: flex;
    }
    .p1_frame {
        display: block;
        width: 45%;
    }
    .p2_frame {
        display: block;
        width: 45%;
    }
    .vs {
        width: 10%;
        text-align: center;
        margin: auto;
    }
CSS
    }

    if ($html_body =~ /class="wait_connection_layer"/ || $footer =~ /class="wait_connection_layer"/) {
        $css .= <<CSS;
    .wait_connection_layer {
        position: fixed;
        top: 0;
        left: 0;
        width: 100vw;
        height: 100vh;
        background-color: rgba(0, 0, 0, 0.7);
        display: flex;
        justify-content: center;
        align-items: center;
        z-index: 9999;
    }
    .wait_connection {
        color: white;
        padding: 20px;
        border-radius: 10px;
    }
CSS
    }

    if ($html_body =~ /class="about"/ || $footer =~ /class="about"/) {
        $css .= <<CSS;
    .about {
        width: 90%;
        margin: 20px auto;
        background-color: #1e1e1e;
        border-radius: 15px;
        padding: 20px;
    }
    .overview {
        margin-bottom: 30px;
        padding: 15px;
        border: 1px solid #333;
        border-radius: 8px;
        background-color: #2e2e2e;
        transition: all 0.3s;
    }
    .overview:hover {
        box-shadow: 0 0 10px rgba(255, 204, 0, 0.6);
    }
    h2 {
        color: #ffcc00;
        margin-bottom: 10px;
    }
    p {
        margin-bottom: 15px;
        color: #ccc;
    }
    ul {
        list-style: none;
        padding-left: 0;
    }
    li {
        padding-left: 25px;
        margin-bottom: 8px;
        color: #f0f0f0;
    }
    .features, .to-do, .known-errors, .additional-notes {
        max-height: 300px;
        overflow-y: auto;
        border: 1px solid #444;
        padding: 10px;
        border-radius: 5px;
        background-color: #1f1f1f;
    }
CSS
    }

    if ($html_body =~ /class="editUpdateTitle"/ || $html_body =~ /class="copyUpdatePoint"/) {
        $css .= <<CSS;
    .editUpdateTitle {
        width: 60%;
        margin: 15px auto;
        position: relative;
    }
    .copyUpdatePoint {
        display: none;
    }
    .notSaved {
        text-align: center;
        color:rgb(235, 9, 9);
    }
    .saved {
        text-align: center;
        color:rgb(9, 235, 9);
    }
    .saveAddedUpdatePoint {
        text-align: center;
    }
CSS
    }

    if ($html_body =~ /class="tooltiptext"/) {
    $css .= <<'CSS';
    .tooltiptext {
        visibility: hidden;
        width: 250px;
        background-color: black;
        color: #fff;
        text-align: center;
        border-radius: 6px;
        padding: 5px;
        position: absolute;
        z-index: 1;
        top: 125%; /* Tooltip above */
        left: 50%;
        margin-left: -125px; /* Centering horizontally */
        opacity: 0;
        transition: opacity 0.3s ease-in-out;
    }
    .hoverI {
        position: relative; /* For tooltip positioning */
        display: inline-block;
        cursor: pointer;
    }
    .hoverI:hover .tooltiptext {
        visibility: visible;
        opacity: 1;
    }
CSS
}


    if ($html_body =~ /class="mainUpdateGroup"/ || $html_body =~ /class="updatePoint"/) {
        $css .= <<CSS;
    .updatePoint {
        width: 80%;
        margin: 15px auto;
        background-color: black;
        border-radius: 15px;
        text-align: left;
        padding: 20px;
        position: relative;
    }
    .updatePoint:hover {
        box-shadow: 0 0 20px rgba(255, 0, 0, 0.6);
        transform: scale(1.05);
    }
    .updatePointTitle {
        margin-bottom: 25px;
        text-align: center;
        word-wrap: anywhere;
    }
    .updatePointDescription {
        word-wrap: anywhere;
        white-space: pre-line;
    }
    .grouped {
        display: flex;
        padding: 20px;
    }
    .input_update_log_add {
        flex: 1;
        margin-left: 20px;
        margin-right: 20px;
    }
    .text_update_log_add {
        width: 20%;
        text-align: left;
    }
    .mainUpdateGroup {
        width: 60%;
        margin: auto;
        background: gray;
        border-radius: 15px;
    }
    .enabled {
        color: green;
        position: absolute;
        top: 5px;
        right: 5px;
    }
    .disabled {
        color: red;
        position: absolute;
        top: 5px;
        right: 5px;
    }
CSS
    }

    if ($html_body =~ /class="close"/ || $html_body =~ /className = "close"/) {
        $css .= <<CSS;
        .close {
            position: absolute;
            top: 10px;
            right: 10px;
        }
CSS
    }

    if ($html_body =~ /class="update"/ || $footer =~ /class="update"/) {
        $css .= <<CSS;
    .update {
        display: flex;
        width: 60%;
        margin: 15px auto;
        justify-content: center;
        flex-wrap: wrap;
        padding: 20px;
        background-color: #1e1e1e;
        border-radius: 15px;
    }
    .update:hover {
        box-shadow: 0 0 10px rgba(255, 255, 255, 0.6);
    }
    .title {
        padding: 10px;
        background-color: #131111;
        border-radius: 9px;
    }
    .updateBody {
        padding-top: 15px;
        padding-bottom: 15px;
        display: none;
        flex-wrap: wrap;
        background-color: #575757;
        margin-top: 35px;
        width: 100%;
        border-radius: 15px;
    }
    .description {
        width: 70%;
        text-align: left;
        display: flex;
        flex-wrap: wrap;
        
    }
    .additionalInfo {
        width: 70%;
        text-align: left;
        display: flex;
        flex-wrap: wrap;
    }
    .date {
        width: 30%;
        text-align: right;
    }
    .preview {
        width: 80%;
    }
CSS
    }

    if ($html_body =~ /class="newUpdateTitle"/ || $html_body =~ /class="newUpdatePointTitle"/ || $html_body =~ /class="newUpdatePointDescription"/) {
        $css .= <<CSS;
    .newUpdateTitle {
        display: none;
    }
    .newUpdatePointTitle {
        display: none;
    }
    .newUpdatePointDescription {
        display: none;
    }
CSS
    }

    if ($html_body =~ /class="ping_display"/) {
        $css .= <<CSS;
    .ping_display {
        position: fixed;
        top: 0;
        right: 0;
        padding: 10px;
    }
CSS
    }

    if ($html_body =~ /class="chooseRequest"/) {
        $css .= <<CSS;
    .chooseRequest {
        max-width: 600px;
        margin: 0 auto;
    }

    .dropdown_button {
        display: flex;
        justify-content: space-between;
        align-items: center;
        border: none;
        border-radius: 5px;
        cursor: pointer;
        width: 100%;
        max-width: 480px;
        margin: 0 auto;
    }

    .dropdown_content {
        border-radius: 5px;
        background-color: #f1f1f1;
        display: none; 
        max-width: 480px;
        margin: 0 auto;
    }

    .userSupport {
        padding: 15px;
    }

    .option {
        display: flex;
        flex-direction: column;
        justify-content: left;
        padding: 0 10px 10px 10px;
    }

    .option a {
        margin: unset;
        width: auto;
        text-align: left;    
    }

    .title h2 {
        margin: unset;
    }

    .supportOption {
        padding-bottom: 10px
    }

    .optionTitle {
        margin-bottom: 5px;
    }
CSS
    }

    if ($html_body =~ /class="hidden"/) {
        $css .= <<CSS;
    .hidden {
        display: none;
    }
CSS
    }

    if ($html_body =~ /class="StreamingView"/ || $html_body =~ /class="channel_videos"/ || $html_body =~ /class="ManageVideo"/) {
        $css .= <<CSS;
    .StreamingTop {
        display: flex;
        background-color: #16171d;
        border-radius: 8px;
        padding: 10px 0 10px 0;
    }
    .StreamingTopLeft {
        width: 25%;
    }
    .StreamingTopCenter {
        width: 50%;
        margin: auto;
    }
    .StreamingTopRight {
        width: 25%;
    }
    .StreamingMainLeft {
        width: 10%;
        flex-wrap: wrap;
        justify-content: center;
        background-color: #2a2d37;
        border-right: 5px black solid;
        border-radius: 10px;
    }
    .StreamingMain {
        display: flex;
        flex: 1;
        border-top: 5px black solid;
        border-bottom: 5px solid black;
        border-radius: 10px;
        overflow: hidden;
    }
    .StreamingMainCenter {
        width: 80%;
        background-color: #4c3f54;

    }
    .StreamingMainRight {
        width: 10%;
        background-color: #2a2d37;
        border-left: 5px black solid;
        border-radius: 10px;
    }
    .StreamingView {
        flex: 1;
        display: flex;
        flex-direction: column;
        height: 100%;
        border: 5px black solid;
        border-radius: 10px;
        background: rgba(0, 0, 0, 0.6);
    }
    .Videos {
        display: flex;
        flex-wrap: wrap;
    }

    .Video {
        background: #fff;
        border-radius: 8px;
        box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        margin: 15px;
        overflow: hidden;
        flex: 1 1 calc(25% - 30px);
        max-width: calc(25% - 30px);
        display: flex;
        flex-direction: column;
    }

    \@media (max-width: 1200px) {
        .Video {
            flex: 1 1 calc(33.33% - 30px); 
            max-width: calc(33.33% - 30px);
        }
    }

    \@media (max-width: 768px) {
        .Video {
            flex: 1 1 calc(50% - 30px); 
            max-width: calc(50% - 30px);
        }
    }

    \@media (max-width: 480px) {
        .Video {
            flex: 1 1 100%; 
            max-width: 100%;
        }
    }

    .Thumbnail {
        border: none;
        cursor: pointer;
        background: black; 
        display: flex;
        align-items: center;
        justify-content: center;
        min-width: 100%;
        aspect-ratio: 16 / 9;
        max-width: fit-content;
        padding: unset;
    }

    .Thumbnail img {
        object-fit: cover;
        max-width: 100%;
        max-height: 100%;
    }


    .VideoMetadata {
        display: flex;
    }

    .ChannelIcon {
        flex-shrink: 0;
        margin: 5px 0 0 5px;
        width: 40px;
        height: 40px;
        border-radius: 50%;
        overflow: hidden;
        border: none;
        display: flex;
        align-items: center;
        justify-content: center;
        cursor: pointer;
    }

    .ChannelIcon img {
        object-fit: cover;
    }

    .OtherMetadata {
        flex: 1;
        display: flex;
        flex-wrap: wrap;
        margin: 5px 10px 5px 10px;
        width: calc(100% - 65px);
    }

    .VideoTitle {
        font-size: 1.2rem;
        font-weight: bold;
        width: 100%;
        height: calc(1.2em * 2);
    }

    .VideoTitle a {
        margin: unset;
        padding: unset;
        width: auto;
        text-align: left;
        background-color: unset;
        -webkit-line-clamp: 2;
        -webkit-box-orient: vertical;
        display: -webkit-box;
        white-space: normal;
        overflow: hidden;
        text-overflow: ellipsis;
    }

    .VideoTitle a:hover {
        color: #007bff;
    }

    .ChannelName {
        width: 100%;
        text-align: left;
    }

    .ChannelName a {
        margin: unset;
        padding: unset;
        width: fit-content;
        text-align: left;
    }

    .VideoInline {
        display: flex;
        font-size: 0.9rem;
        color: #777;
        justify-content: space-between;
        flex: 1;
    }
CSS
    }

    if ($html_body =~ /class="StreamingChannel"/) {
        $css .= <<CSS;
    .ChannelBanner {
        position:absolute;
        z-index: -1;
        width: 100%;
        height: 200px;
    }
    .ChannelBanner img {
        width: 100%;
        height: 200px;
    }
    .ChannelInfo {
        display: flex;
        height: 200px;
    }
    .ChannelIcon {
        margin-left: 30%;
        margin-top: unset;
        justify-content: center;
        display: flex;
    }
    .channel_icon {
        margin: auto;
        width: 100px;
    }
    .ChannelText {
        margin-left: 5%;
        display: flex;
        flex-wrap: wrap;
    }
    .ChannelName {
        position: relative;
        top: 30%;
        margin: unset;
        width: 100%;
        height: fit-content;
    }
    .ChannelName h1 {
        margin: unset;
        text-align: left;
    }
    .SubscriberCount {
        height: fit-content;
    }
    .SubscribeButton {
        position: relative;
        top: 55%;
        height: fit-content;
    }
    .ChannelFeatures {
        display: flex;
        background-color: aquamarine;
        justify-content: space-evenly;
    }
    .ChannelFeatures a {
        width: auto;
    }
    .ManageAccount {
        margin-left: auto;
    }
    .ManageAccount a {
        margin: 10px;
        width: auto;
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