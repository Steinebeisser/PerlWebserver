package html_structure;

use strict;
use warnings;

sub get_html {
    my ($html_body, $title) = @_;

    my $footer = html_utils::get_footer();
    my $style = css_utils::get_css($html_body, $footer);
    my $vanta_bg = get_vanta_bg();
    # my $language_query_script = get_language_query_script();

    my $html_content = <<"HTML";
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$title</title>
    $style
</head>
<body>
    $vanta_bg
    <div class="main">
        $html_body
    </div>
    $footer
</body>
</html>
HTML

    return ($html_content);
}


sub get_vanta_bg {
    my $font_backs = css_utils::get_font_backs();
    my $vanta_bg = <<"VANTA_BG";
    <div class="vanta_bg" aria-hidden="true"></div>
    <script src="${font_backs}ExternalJS/three.min.js"></script>
    <script src="${font_backs}ExternalJS/vanta.birds.min.js"></script>
    <script>
        VANTA.BIRDS({
        el: ".vanta_bg",
        mouseControls: true,
        touchControls: true,
        gyroControls: false,
        minHeight: 200.00,
        minWidth: 200.00,
        scale: 1.00,
        scaleMobile: 1.00,
VANTA_BG
print("Main scheme: $main::scheme\n");
    if ($main::scheme eq "dark") {
        $vanta_bg .= <<VANTA_BG;
        colorMode: "lerp",
VANTA_BG
    } else {
        $vanta_bg .= <<VANTA_BG;
        backgroundColor: 0xc4d8ed,
        color1: 0x523232,
VANTA_BG
    }
    $vanta_bg .= <<VANTA_BG;
        birdSize: 0.50,
        wingSpan: 15.00,
        speedLimit: 1.00,
        separation: 70.00,
        alignment: 1.00,
        cohesion: 1.00,
        quantity: 4.00
        })
    </script>
VANTA_BG
    
    return $vanta_bg;
}


sub get_language_query_script {
    my $language_query_script = <<LANGUAGE_QUERY_SCRIPT;
    <script>
        if (!localStorage.getItem('language')) {
            const browserLanguage = navigator.language || navigator.userLanguage || 'en';
            localStorage.setItem('language', browserLanguage);
        }
        const language = localStorage.getItem('language') || 'en'; // Default to 'en' if missing
        const currentURL = window.location.href;

        // Append ?lang=<language> if not already present
        if (!currentURL.includes('lang=')) {
            const separator = currentURL.includes('?') ? '&' : '?';
            window.location.href = currentURL + separator + 'lang=' + language;
        } else if (!currentURL.includes('lang=' + language)) {
            // Replace existing language query parameter
            window.location.href = currentURL.replace(/lang=[^&]+/, 'lang=' + language);
        }
    </script>
LANGUAGE_QUERY_SCRIPT

    return $language_query_script;  
}


1;