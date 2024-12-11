package get_profile_ploud_upload;

use strict;
use warnings;

sub get_profile_ploud_upload {
    my ($username) = @_;

    my $human_username = user_utils::get_username();

    my $translations = language_utils::load_language("profile, ploud");

    my $html_body = <<HTML;
    <h1>$translations->{ploud}</h1>
    <br>
    <p>$translations->{username}: $human_username</p>
HTML

    $html_body .= html_utils::create_breadcrumbs("profile, ploud, upload");

    my $user_stats = user_utils::get_json_data($username);
    if (!$user_stats) {
        return "User not found";
    }
    my $max_storage = $user_stats->{rank}{benefits}{max_storage};

    print("MAX STORAGE: $max_storage\n");

    if (!$max_storage) {
        $max_storage = $main::max_storage
    }
    my $storage_used = user_utils::get_current_used_storage();

    my $full_percent = sprintf("%.2f", $storage_used / $max_storage * 100);
    print("FULL PERCENT: $full_percent\n");
    print($storage_used . " / " . $max_storage . " = " . $storage_used / $max_storage);

    my $max_storage_formated = user_utils::format_bytes($max_storage);

    

    my $server_storage = user_utils::get_server_storage();
    my $server_storage_used = $server_storage->{used};
    my $server_storage_free = $server_storage->{free};
    my $server_storage_total = $server_storage->{total};
    my $script = <<SCRIPT;
    <script>
        var max_storage = $max_storage;
        var storage_used = $storage_used;
        var server_storage_free = $server_storage_free;
        var server_storage_total = $server_storage_total;
        var server_storage_used = $server_storage_used;
        var server_storage_bottleneck = $server::storage_bottleneck;

        var available_storage = max_storage - storage_used - (max_storage * 0.02); 
        var available_server_storage = server_storage_free * server_storage_bottleneck;
        console.log("AVAILABLE SERVER STORAGE: " + available_server_storage);

        document.getElementById('fileInput').addEventListener('change', function(event) {
            const file = event.target.files[0]; 

            if (file) {
                const fileSize = file.size; 

                if (fileSize > available_server_storage) {
                    event.preventDefault(); 
                    alert('Server storage is full. Were working on it. Please try again later.');
                    document.getElementById('fileInput').value = '';
                    contact_devs("Storage full");
                    return;
                }
                if (fileSize > available_storage) {
                    event.preventDefault(); // Prevent form submission
                    alert('File is too large. You have ' + (available_storage / (1024 * 1024)).toFixed(2) + ' MB available for upload.');
                    document.getElementById('fileInput').value = '';
                }
            }
        });

        function contact_devs(reason) {
            fetch('/important/contact_devs', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    reason: reason
                })
            });
        }
    </script>
SCRIPT


    $html_body .= <<HTML;
    <br>
    <form action="/profile/ploud/upload" method="post" enctype="multipart/form-data" id="uploadForm" class="ploud_upload_form">
        <input type="file" name="file" id="fileInput">
        <input type="submit" value="$translations->{upload}">
    </form>
    <br>
    <div class="storage_info">
        <p>$translations->{storageInfo}</p>
        <p>$translations->{storageUsed}: $full_percent%</p>
        <p>$translations->{storageTotal}: $max_storage_formated</p>
    </div>
    <div class="upgrade_storage">
        <a href="/profile/ploud/upgrade">$translations->{upgradeStorage}</a>
    </div>
HTML

    $html_body .= html_utils::get_ploud_items();

    $html_body .= <<HTML;
    <div class="server_storage">
        <p>$translations->{serverStorageInfo}</p>
        <p>$translations->{serverStorageUsed}: $server_storage_used</p>
        <p>$translations->{serverStorageFree}: $server_storage_free</p>
        <p>$translations->{serverStorageTotal}: $server_storage_total</p>
    </div>
HTML

    $html_body .= $script;
    
    my $html_content = html_structure::get_html($html_body, "Profile");
    
    return ($html_content);
}

1;