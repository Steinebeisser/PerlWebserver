package get_choose_request_support_page;

use strict;
use warnings;

sub get_choose_request_support_page {
    my $translations = language_utils::load_language("support");

    my $supportOptions = support_utils::get_support_options();

    my $html = <<HTML;
    <div class="title">
        <h1>$translations->{supportPage}</h1>
    </div>
    <div class="chooseRequest">
        <div class="header">
            <h2>$translations->{chooseRequest}</h2>
        </div>
        <div class="body">
            <div class="choose_ticket_option">
                <div class="dropdown">
                    <button class="dropdown_button" onclick="toggleDropdown()">
                        <div class="text_left">
                            <p>$translations->{ticket}</p>
                        </div>
                        <div class="arrow_right">
                            <p>></p>
                        </div>
                    </button>
                    <div class="dropdown_content">
HTML

    foreach my $supportOption (@$supportOptions) {
        my $title = $supportOption->{title};
        $html .= <<HTML;
                    <div class="supportOption">
                        <div class="optionTitle">
                            <div class="title">
                                <h2>$translations->{$title}</h2>
                            </div>
                        </div>
HTML
        foreach my $option (@{$supportOption->{options}}) {
            my $link = $option->{link};
            my $description = $option->{description};
            $html .= <<HTML;
                            <div class="option">
                                <a href="$link">
                                    $translations->{$description}
                                </a>
                            </div>
HTML
        }
        $html .= <<HTML;
                    </div>
HTML
    }
                        # <div class="userSupport">
                        #     <div class="title">
                        #         <h2>$translations->{userSupport}</h2>
                        #     </div>
                        #     <div class="options">
                        #         <a href="support/request/user/penalty">
                        #             $translations->{penaltyTicketDescription}
                        #         </a>
                        #         <a href="support/request/user/bug">
                        #             $translations->{bugTicketDescription}
                        #         </a>
                        #         <a href="support/request/user/error">
                        #             $translations->{errorTicketDescription}
                        #         </a>
                        #     </div>
    $html .= <<HTML;
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
HTML

    my $script = <<SCRIPT;
    <script>
        function toggleDropdown() {
            var dropdown = document.getElementsByClassName("dropdown_content")[0];
            var arrow_right = document.getElementsByClassName("arrow_right")[0];
            if (dropdown.style.display === "none" || dropdown.style.display === "") {
                dropdown.style.display = "block";
                arrow_right.style.transform = "rotate(90deg)";
            } else {
                dropdown.style.display = "none";
                arrow_right.style.transform = "rotate(0deg)";
            }
        }
    </script>
SCRIPT

    $html .= $script;

    my $html_content = html_structure::get_html($html, "Support");

    return $html_content;
}

1;