package update_log_html;

use strict;
use warnings;

sub update_log_html {
    my $translations = language_utils::load_language("updateLog");

    my @update_log = update_log::get_update_log();

    my $html_body = <<HTML;
    <h1>$translations->{updateLog}</h1>
    <br>
HTML
    
    foreach my $update (@update_log) {
        my $date = $update->{date};
        # my $description = $update->{description};
        my $title = $update->{title};

        $html_body .= <<HTML;
        <div class="update" onclick="toggleUpdate(this)">
            <div class="preview">
                <div class="title">
                    $title<br>    
                    $date
                </div>
HTML
#         if ($update->{additionalInfo}) {
#         my $additionalInfo = $update->{additionalInfo};
#         $html_body .= <<HTML;
#                 <div class="additionalInfo">
#                     $additionalInfo
#                 </div>
# HTML
#         }
        $html_body .= <<HTML;
                <div class="updateBody" onclick="event.stopPropagation()">
HTML
    my @sorted_update_points = sort { $a <=> $b } keys %{$update->{updatePoints}};
    foreach my $updatePointId (@sorted_update_points) {
        my $updatePoint = $update->{updatePoints}->{$updatePointId};
        my $description = $updatePoint->{description};
        my $title = $updatePoint->{title};
        my $date = $updatePoint->{date};
        $html_body .= <<HTML;
                    <div class="updatePoint">
                        <div class="updatePointTitle">
                            $title
HTML
        if ($updatePoint->{useNewTime}) {
            my $newTime = $updatePoint->{Date};
            $html_body .= <<HTML;
                            <div class="newTime">
                                Added Later - $date
                            </div>  
HTML
        }
        $html_body .= <<HTML;
                        </div>
                        <div class="updatePointDescription">
                            $description
                        </div>
                    </div>
HTML

    }
        $html_body .= <<HTML;
                </div>
            </div>
        </div>
HTML
    }

    my $script = <<Script;
    <script>
        function toggleUpdate(element) {
            var updateBody = element.getElementsByClassName("updateBody")[0];
            console.log(updateBody.style.display);
            if (updateBody.style.display === "none" || updateBody.style.display === "") {
                updateBody.style.display = "flex";
            } else {
                updateBody.style.display = "none";
            }
        }
        function stopPropagation(event) {
            event.stopPropagation();
        }
    </script>
Script

    $html_body .= $script;

    $html_body .= html_utils::create_breadcrumbs("updateLog");

    my $html_content = html_structure::get_html($html_body, "Update Log");

    return $html_content;
}

1;