package get_admin_update_log_add;

use strict;
use warnings;

sub get_admin_update_log_add {
    my $translations = language_utils::load_language("updateLog");

    my $html_body = <<HTML;
    <div class="add_update">
        <h1>$translations->{add}</h1>
        <form action="/admin/updateLog/add" method="post">
            <div class="mainUpdateGroup">
                <div class="grouped">
                    <div class="text_update_log_add">$translations->{title_update}: </div> 
                    <textarea class="input_update_log_add" name="updateTitle" required></textarea>
                </div>
                <div class="grouped">
                    <div class="text_update_log_add">$translations->{additionalInfo_update}: </div> 
                    <textarea class="input_update_log_add" name="updateAdditionalInfo" ></textarea>
                </div>
            </div>
            <br>
            <br>
            <div id="updatePoints">
                $translations->{updatePoints}:<br>
                <div class="updatePoint">
                    <div class="grouped">
                        <div class="text_update_log_add">$translations->{title_updatePoint}:</div> 
                        <textarea class="input_update_log_add" name="updatePointTitle" required></textarea>
                    </div>
                    <div class="grouped">
                        <div class="text_update_log_add">$translations->{description_updatePoint}:</div> 
                        <textarea class="input_update_log_add" name="updatePointDescription" required></textarea>
                    </div>
                    <div class="grouped">
                        <div class="text_update_log_add">$translations->{additionalInfo_updatePoint}:</div> 
                        <textarea class="input_update_log_add" name="updatePointAdditionalInfo"></textarea>
                    </div>
                </div>
            </div>
            <input type="submit" value="$translations->{addUpdate}">
        </form>
        <br>
        
        <button onclick="addUpdatePoint()">$translations->{add_updatePoint}</button><br><br>
        <a href="/admin/updateLog">$translations->{return}</a>
    </div>
HTML

    my $script = <<script;
    <script>
        function addUpdatePoint() {
            var updatePoints = document.getElementById("updatePoints");
            var updatePoint = document.getElementsByClassName("updatePoint")[0];
            var newUpdatePoint = updatePoint.cloneNode(true);
            var closeButton = document.createElement("div");
            closeButton.className = "close";
            closeButton.innerHTML = '<button onclick="removeUpdatePoint(this)">X</button>';
            newUpdatePoint.appendChild(closeButton);
            var textareas = newUpdatePoint.getElementsByTagName("textarea");
            for (var i = 0; i < textareas.length; i++) {
                textareas[i].value = "";
            }
            updatePoints.appendChild(newUpdatePoint);
        }
        function removeUpdatePoint(element) {
            element.parentElement.parentElement.remove();
        }
    </script>
script

    $html_body .= $script;

    $html_body .= html_utils::create_breadcrumbs("admin, updateLog, add");

    my $html_content = html_structure::get_html($html_body, "Admin");

    return $html_content;
}

1;