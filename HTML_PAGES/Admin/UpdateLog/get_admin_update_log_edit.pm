package get_admin_update_log_edit;

use strict;
use warnings;

sub get_admin_update_log_edit {
    my ($update) = @_;
    my $translations = language_utils::load_language("updateLog");
    
    my $updateID = $update->{id};
    # print("updateID: $updateID\n");

    my $html_body = <<HTML;
    <h1>$translations->{edit}</h1>
    <br>
    <div class="editUpdate">
        <div class="editUpdateTitle">
            <div class="enabledStatus">
HTML
    if ($update->{enabled}) {
        $html_body .= <<HTML;
                <div class="enabled">
                    $translations->{enabled}
                </div>
HTML
    } else {
        $html_body .= <<HTML;
                <div class="disabled">
                    $translations->{disabled}
                </div>
HTML
}
    $html_body .= <<HTML;
            </div>
            <div class="updateTitleDisplay">
                <h1>$update->{title}</h1>
            </div>
            <button class="editUpdateTitleButton" onclick="editUpdateTitle()">$translations->{editTitle}</button>
            <div class="newUpdateTitle">
                <textarea class="newUpdateTitleInput">$update->{title}</textarea>
                <button class="newUpdateTitleButton" onclick="saveUpdateTitle()">$translations->{save}</button>
            </div>
            <div class="toggleUpdate">
HTML
        if ($update->{enabled}) {
            $html_body .= <<HTML;
                <button class="disableUpdateButton" onclick="disableUpdate($updateID)">$translations->{disable}</button>
HTML
        } else {
            $html_body .= <<HTML;
                <button class="enableUpdateButton" onclick="enableUpdate($updateID)">$translations->{enable}</button>
HTML
        }
        $html_body .= <<HTML;
            </div>
        </div>
HTML
    my @sorted_update_points = sort { $a <=> $b } keys %{$update->{updatePoints}};
    foreach my $updatePointId (@sorted_update_points) {
        my $updatePoint = $update->{updatePoints}->{$updatePointId};
        my $description = $updatePoint->{description};
        my $title = $updatePoint->{title};
        $html_body .= <<HTML;
        <div class="editUpdatePoint">
            <div class="updatePoint">
                <div class="enabledStatus">
HTML
        if ($updatePoint->{enabled}) {
            $html_body .= <<HTML;
                    <div class="enabled">
                        $translations->{enabled}
                    </div>
HTML
        } else {
            $html_body .= <<HTML;
                    <div class="disabled">
                        $translations->{disabled}
                    </div>
HTML
        }
        $html_body .= <<HTML;
                </div>
                <div class="updatePointTitle">
                    <div class="updatePointTitleDisplay">
                        $title
                    </div>
                    <button class="editUpdatePointTitleButton" onclick="editUpdatePointTitle($updatePointId)">$translations->{edit}</button>
                    <div class="newUpdatePointTitle">
                        <textarea class="newUpdatePointTitleInput">$title</textarea>
                        <button class="newUpdatePointTitleButton" onclick="saveUpdatePointTitle($updatePointId)">$translations->{save}</button>
                    </div>
                </div>
                <div class="updatePointDescription">
                    <div class="updatePointDescriptionDisplay">
                        $description 
                    </div>
                    <button class="editUpdatePointDescriptionButton" onclick="editUpdatePointDescription($updatePointId)">$translations->{edit}</button>
                    <div class="newUpdatePointDescription">
                        <textarea class="newUpdatePointDescriptionInput">$description</textarea>
                        <button class="newUpdatePointDescriptionButton" onclick="saveUpdatePointDescription($updatePointId)">$translations->{save}</button>
                    </div>
                </div>
HTML
        if (defined $updatePoint->{useNewTime}) {
            # print("newTime123: $updatePoint->{useNewTime}\n");
            my $useNewTime = $updatePoint->{useNewTime};
            if ($useNewTime) {
                $html_body .= <<HTML;
                    <div class="newTime">
                        <input type="checkbox" id="useNewTimeCheckbox_$updatePointId" onclick="toggleNewTime($updatePointId)" checked>
                        <label for="useNewTimeCheckbox_$updatePointId">$translations->{useNewTime}</label>
                    </div>
HTML
            } else {
                $html_body .= <<HTML;
                    <div class="newTime">
                        <input type="checkbox" id="useNewTimeCheckbox_$updatePointId" onclick="toggleNewTime($updatePointId)">
                        <label for="useNewTimeCheckbox_$updatePointId">$translations->{useNewTime}</label>
                    </div>
HTML
            }
        }

            $html_body .= <<HTML;
                <div class="toggleUpdatePoint">
HTML
        if ($updatePoint->{enabled}) {
            $html_body .= <<HTML;
                    <button class="disableUpdatePointButton" onclick="disableUpdatePoint($updatePointId)">$translations->{disable}</button>
HTML
        } else {
            $html_body .= <<HTML;
                    <button class="enableUpdatePointButton" onclick="enableUpdatePoint($updatePointId)">$translations->{enable}</button>
HTML
        }
        $html_body .= <<HTML;
                </div>
                <div class="deleteUpdatePoint">
                    <button class="deleteUpdatePointButton" onclick="requestDeleteUpdatePoint($updatePointId)">$translations->{delete}</button>
                </div>

            </div>
        </div>
HTML
    }

    $html_body .= <<HTML;
        <div class="addedUpdatePoints">
        </div>
        <div class="updatePoints">
            <div class="copyUpdatePoint">
                <div class="status">
                    <div class="notSaved">
                        $translations->{notSaved}
                    </div>
                </div>
                <div class="grouped">
                    <div class="text_update_log_add">$translations->{title_updatePoint}:</div> 
                    <textarea class="input_update_log_add" id="newUpdatePointTitle" required></textarea>
                </div>
                <div class="grouped">
                    <div class="text_update_log_add">$translations->{description_updatePoint}:</div> 
                    <textarea class="input_update_log_add" id="newUpdatePointDescription" required></textarea>
                </div>
                <div class="grouped">
                    <div class="text_update_log_add">$translations->{additionalInfo_updatePoint}:</div> 
                    <textarea class="input_update_log_add" id="newUpdatePointAdditionalInfo"></textarea>
                </div>
                <div class="useNewTime">
                    <input type="checkbox" id="useNewTime" name="useNewTime" value="useNewTime">
                    <label for="useNewTime">$translations->{useNewTime}</label>
                </div>
                <div class="saveAddedUpdatePoint">
                    <button onclick="saveNewUpdatePoint(this)">$translations->{save}</button>
                </div>
            </div>
        </div>
        <div class="addUpdatePoint">
            <button onclick="addUpdatePoint()">$translations->{add_updatePoint}</button>
        </div>
    </div>
HTML

    my $script = <<Script;
    <script>
        var newUpdateID = 0;
        var updateID = BigInt("$updateID");
        function toggleNewTime(updatePointId) {
            var checkbox = document.getElementById("useNewTimeCheckbox_" + updatePointId);
            if (checkbox.checked) {
                enableNewTime(updatePointId);
            } else {
                disableNewTime(updatePointId);
            }
        }
        function enableNewTime(updatePointId) {
            updatePointId += 1;
            sendToSever(updateID, updatePointId, "enable", "newTime");
        }
        function disableNewTime(updatePointId) {
            updatePointId += 1;
            sendToSever(updateID, updatePointId, "disable", "newTime");
        }
        function saveNewUpdatePoint(button) {
            // var newUpdatePoint = document.getElementsByClassName("newUpdatePoint")[];
            // console.log(newUpdatePoint);
            var updatePoint = button.parentElement.parentElement;
            var updatePoint = button.parentElement.parentElement;
            console.log(button);
            console.log(updatePoint);

            // Fetch values using getElementsByClassName (in the scope of the updatePoint)
            var title = updatePoint.querySelector("#newUpdatePointTitle").value;
            var description = updatePoint.querySelector("#newUpdatePointDescription").value;
            var additionalInfo = updatePoint.querySelector("#newUpdatePointAdditionalInfo").value;
            var useNewTime = updatePoint.querySelector("#useNewTime").checked;

            console.log("title: " + title);
            console.log("description: " + description);
            console.log("additionalInfo: " + additionalInfo);
            console.log("useNewTime: " + useNewTime);

            var additionalInfo = document.getElementById("newUpdatePointAdditionalInfo").value;
            if (!title || !description) {
                alert("$translations->{missingFields}");
                return;
            }
            var newUpdatePoint = {
                "title": title,
                "description": description,
                "additionalInfo": additionalInfo,
                "useNewTime": useNewTime,
                "type": "newPoint"
            };
            fetch("/admin/updateLog/edit/" + updateID, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json"
                },
                body: JSON.stringify(newUpdatePoint)
            }).then(response => {
                if (response.ok) {
                    console.log("New update point saved successfully");
                    var status = button.parentElement.parentElement.querySelector(".status");
                    status.innerHTML = "<div class='saved'>$translations->{savedReload}</div>";
                    button.remove();
                } else {
                    console.error("Failed to save new update point");
                }
            }).catch(error => {
                console.error("Error:", error);
            })
        }
        function editUpdateTitle() {
            var title = document.getElementsByClassName("newUpdateTitle")[0];
            if (title.style.display === "block") {
                title.style.display = "none";
            } else {
                title.style.display = "block";
            }
        }
        function editUpdatePointTitle(id) {
            var title = document.getElementsByClassName("newUpdatePointTitle")[id];
            if (title.style.display === "block") {
                title.style.display = "none";
            } else {
                title.style.display = "block";
            }
        }
        function editUpdatePointDescription(id) {
            var description = document.getElementsByClassName("newUpdatePointDescription")[id];
            if (description.style.display === "block") {
                description.style.display = "none";
            } else {
                description.style.display = "block";
            }
        }
        function saveUpdateTitle() {
            var title = document.getElementsByClassName("newUpdateTitleInput")[0].value;
            document.getElementsByClassName("updateTitleDisplay")[0].innerHTML = "<h1>" + title + "</h1>";
            document.getElementsByClassName("newUpdateTitle")[0].style.display = "none";
            sendToSever(updateID, "none", title, "title");
        }
        function saveUpdatePointTitle(updatePointId) {
            var title = document.getElementsByClassName("newUpdatePointTitleInput")[updatePointId].value;
            document.getElementsByClassName("updatePointTitleDisplay")[updatePointId].innerHTML = title;
            document.getElementsByClassName("newUpdatePointTitle")[updatePointId].style.display = "none";
            console.log("updatePointId: " + updatePointId);
            updatePointId += 1;
            sendToSever(updateID, updatePointId, title, "title");
        }
        function saveUpdatePointDescription(updatePointId) {
            var description = document.getElementsByClassName("newUpdatePointDescriptionInput")[updatePointId].value;
            document.getElementsByClassName("updatePointDescriptionDisplay")[updatePointId].innerHTML = description;
            document.getElementsByClassName("newUpdatePointDescription")[updatePointId].style.display = "none";
            updatePointId += 1;
            sendToSever(updateID, updatePointId, description, "description");
        }
        function sendToSever(updateID, updatePointId, data, type) {
            var url = "/admin/updateLog/edit/" + updateID;
            console.log (url);
            if (updatePointId) {
                updatePointId -= 1;
                url += "/" + (updatePointId);
            }
            console.log(url);
            fetch(url, {
                method: "POST",
                body: JSON.stringify({data: data, type: type}),
                headers: {
                    "Content-Type": "application/json"
                }
            });
        }
        function disableUpdatePoint(updatePointId) {
            const FieldButton = document.getElementsByClassName("toggleUpdatePoint")[updatePointId];
            FieldButton.innerHTML = '<button class="enableUpdatePointButton" onclick="enableUpdatePoint(' + updatePointId + ')">$translations->{enable}</button>';
            const FieldText = document.getElementsByClassName("enabledStatus")[updatePointId];
            FieldText.innerHTML = '<div class=\"disabled\">$translations->{disabled}</div>';
            updatePointId += 1;
            sendToSever(updateID, updatePointId, "disable", "disable");
        }
        function enableUpdatePoint(updatePointId) {
            const FieldButton = document.getElementsByClassName("toggleUpdatePoint")[updatePointId];
            FieldButton.innerHTML = '<button class="disableUpdatePointButton" onclick="disableUpdatePoint(' + updatePointId + ')">$translations->{disable}</button>';
            const FieldText = document.getElementsByClassName("enabledStatus")[updatePointId];
            FieldText.innerHTML = '<div class=\"enabled\">$translations->{enabled}</div>';
            updatePointId += 1;
            sendToSever(updateID, updatePointId, "enable", "enable");
        }
        function requestDeleteUpdatePoint(updatePointId) {
            if (confirm("$translations->{confirmDelete}")) {
                const Field = document.getElementsByClassName("editUpdatePoint")[updatePointId];
                updatePointId += 1;
                sendToSever(updateID, updatePointId, "delete", "delete");
                Field.remove();
            }
        }
        function disableUpdate() {
            const FieldButton = document.getElementsByClassName("toggleUpdate")[0];
            FieldButton.innerHTML = '<button class="enableUpdateButton" onclick="enableUpdate()">$translations->{enable}</button>';
            const FieldText = document.getElementsByClassName("enabledStatus")[0];
            FieldText.innerHTML = '<div class=\"disabled\">$translations->{disabled}</div>';
            sendToSever(updateID, "disable", "disable", "disable");
        }
        function enableUpdate() {
            const FieldButton = document.getElementsByClassName("toggleUpdate")[0];
            FieldButton.innerHTML = '<button class="disableUpdateButton" onclick="disableUpdate()">$translations->{disable}</button>';
            const FieldText = document.getElementsByClassName("enabledStatus")[0];
            FieldText.innerHTML = '<div class=\"enabled\">$translations->{enabled}</div>';
            sendToSever(updateID, "enable", "enable", "enable");
        }
        function addUpdatePoint() {
            var updatePoints = document.getElementsByClassName("addedUpdatePoints")[0];
            console.log(updatePoints);
            var updatePoint = document.getElementsByClassName("copyUpdatePoint")[0];
            console.log(updatePoint);
            var newUpdatePoint = updatePoint.cloneNode(true);
            newUpdatePoint.className = "updatePoint";
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
Script

    $html_body .= html_utils::create_breadcrumbs ("admin, updateLog, edit, ");

    $html_body .= $script;

    my $html_content = html_structure::get_html($html_body, "Edit Updatelog");

    return $html_content;
}

1;