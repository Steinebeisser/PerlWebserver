package html_structure;

use strict;
use warnings;

sub get_html {
    my ($html_body, $title) = @_;

    my $footer = html_utils::get_footer();
    my $style = css_utils::get_css($html_body, $footer);
    my $vanta_bg = get_vanta_bg();

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
        colorMode: "lerp",
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
# sub get_vanta_bg {

#     my $vanta_bg = <<"FUCK U";
# <div class="vanta_bg" aria-hidden="true"></div>
# <script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r134/three.min.js"></script>
# <script src="https://cdn.jsdelivr.net/npm/vanta\@latest/dist/vanta.birds.min.js"></script>
# <script>
#     VANTA.BIRDS({
#     el: ".vanta_bg",
#     mouseControls: true,
#     touchControls: true,
#     gyroControls: false,
#     minHeight: 200.00,
#     minWidth: 200.00,
#     scale: 1.00,
#     scaleMobile: 1.00,
#     colorMode: "lerp",
#     birdSize: 0.50,
#     wingSpan: 15.00,
#     speedLimit: 1.00,
#     separation: 70.00,
#     alignment: 1.00,
#     cohesion: 1.00,
#     quantity: 4.00
#     })
# </script>
# FUCK U

#     return $vanta_bg;
# }


1;