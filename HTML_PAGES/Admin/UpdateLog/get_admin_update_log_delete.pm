package get_admin_update_log_delete; 

use strict;
use warnings;

sub get_admin_update_log_delete {
    my ($update) = @_;

    my $translations = language_utils::load_language("updateLog");
    my $html = <<HTML;
        <div class="container">
            <h2>Delete Update Log</h2>         
HTML

    $html .= <<HTML;
            <p>$translations->{deleteUpdateLog} $update->{title}?\n<h1>$translations->{irreversible}</h1></p>
            <button class="deleteButton" onclick="deleteUpdateLog($update->{id})">$translations->{delete}</button></button>
        </div>
HTML

    my $script = <<script;
    <script>
        var updateID = BigInt("$update->{id}");
        function deleteUpdateLog() {
            console.log("deleteUpdateLog: " + updateID);
            if (confirm(`$translations->{deleteUpdateLog} $update->{title}?`)) {
                fetch("/admin/updateLog/delete/" + updateID, {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json",
                    },
                    body: JSON.stringify({
                        deleteoLEUPDATEEEEE: true,
                    }),
                }).then(response => {
                    if (response.ok) {
                        window.location.href = "/admin/updateLog";
                    } else {
                        console.error("Failed to delete update log");
                    }
                }).catch(error => {
                    console.error("Error:", error);
                });
            }
        }
    </script>
script

    $html .= $script;

    my $html_content = html_structure::get_html($html,"deleteUpdateLog");

    return $html_content;

}

1;