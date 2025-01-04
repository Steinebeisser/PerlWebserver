package get_profile_ploud_upload;

use strict;
use warnings;

sub get_profile_ploud_upload {
    my ($username) = @_;

    my $human_username = $main::user->{human_username};

    my $translations = language_utils::load_language("profile, ploud");

    my $html_body = <<HTML;
    <h1>$translations->{ploud}</h1>
    <br>
    <p>$translations->{username}: $human_username</p>
HTML

    $html_body .= html_utils::create_breadcrumbs("profile, ploud, upload");

    my $user_stats = user_utils::get_json_data($main::user->{uuid});
    if (!$user_stats) {
        return "User not found";
    }
    my $max_storage = $user_stats->{rank}{benefits}{max_storage};

    print("MAX STORAGE: $max_storage\n");

    if (!$max_storage) {
        $max_storage = $main::max_storage
    }
    my $storage_used = user_utils::get_current_used_storage($main::user->{uuid});

    my $full_percent = sprintf("%.2f", $storage_used / $max_storage * 100);
    print("FULL PERCENT: $full_percent\n");
    print($storage_used . " / " . $max_storage . " = " . $storage_used / $max_storage);

    my $max_storage_formated = user_utils::format_bytes($max_storage);

    

    my $server_storage = user_utils::get_server_storage();
    my $server_storage_used = $server_storage->{used};
    my $server_storage_free = $server_storage->{free};
    my $server_storage_total = $server_storage->{total};
    my $formatted_server_storage_total = user_utils::format_bytes($server_storage_total);
    my $formatted_server_storage_used = user_utils::format_bytes($server_storage_used);
    my $formatted_server_storage_free = user_utils::format_bytes($server_storage_free);
    my $usable_storage_left = user_utils::format_bytes($server_storage_free * $server::storage_bottleneck);
    my $usable_storage_total = user_utils::format_bytes($server_storage_total * $server::storage_bottleneck);
    my $percentage_total = sprintf("%.2f", $server_storage_used / $server_storage_total) * 100;
    my $percentage_free = sprintf("%.2f", ($server_storage_used / ($server_storage_total * $server::storage_bottleneck))) * 100;
    my $server_storage_bottleneck = $server::storage_bottleneck * 100;
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

                available_server_storage = get_server_storage();

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

        document.getElementById('uploadButton').addEventListener('click', function(event) {
            event.preventDefault(); // Prevent default form submission
            console.log('Upload button clicked');
            get_server_storage().then(function(available_server_storage) {
                const fileInput = document.getElementById('fileInput');
                const file = fileInput.files[0];

                if (file) {
                    const fileSize = file.size;

                    if (fileSize > available_server_storage) {
                        alert('Server storage is full. We are working on it. Please try again later.');
                        fileInput.value = '';
                        contact_devs("Storage full");
                        return;
                    }

                    if (fileSize > available_storage) {
                        alert('File is too large. You have ' + (available_storage / (1024 * 1024)).toFixed(2) + ' MB available for upload.');
                        fileInput.value = '';
                        return;
                    }
                    console.log('File size:', fileSize);
                    // Proceed with the upload
                    document.getElementById('uploadForm').submit();
                }
            }).catch(function(error) {
                console.error('Error fetching server storage:', error);
                alert('Error fetching server storage. Please try again later.');
            });
        });

        function get_server_storage() {
            return fetch('/data/get_server_storage', {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json'
            }
            }).then(response => {
            if (response.ok) {
                return response.json().then(data => {
                console.log(data);
                var old_server_storage_free = server_storage_free;
                var old_server_storage_total = server_storage_total;
                var old_server_storage_used = server_storage_used;
                server_storage_free = data.free;
                server_storage_total = data.total;
                server_storage_used = data.used;
                console.log('server_storage_free - old_server_storage_free: ' + (server_storage_free - old_server_storage_free));
                console.log('server_storage_total - old_server_storage_total: ' + (server_storage_total - old_server_storage_total));
                console.log('server_storage_used - old_server_storage_used: ' + (server_storage_used - old_server_storage_used));
                updateServerTooltip();
                return data.free * server_storage_bottleneck;
                });
            } else {
                console.error('Failed to fetch server storage data');
                return 0;
            }
            }).catch(error => {
            console.error('Error:', error);
            return 0;
            });
        }

        function updateServerTooltip() {
            const serverTooltip = document.getElementsByClassName('tooltiptext')[0];
            serverTooltip.innerHTML = '<p>$translations->{serverStorageInfo}</p>' + 
            '<p>$translations->{serverStorageUsed}: ' + format_bytes(server_storage_used) + '</p>' + 
            '<p>$translations->{serverStorageFree}: ' + format_bytes(server_storage_free) + '</p>' + 
            '<p>$translations->{serverStorageTotal}: ' + format_bytes(server_storage_total) + '</p>' + 
            '<p>$translations->{serverStorageBottleneck}: ' + server_storage_bottleneck + '%</p>' + 
            '<p>$translations->{usableStorageLeft}: ' + format_bytes(server_storage_free * server_storage_bottleneck) + '</p>' + 
            '<p>$translations->{usableStorageTotal}: ' + format_bytes(server_storage_total * server_storage_bottleneck) + '</p>' + 
            '<p>$translations->{percentageTotal}: ' + (server_storage_used / server_storage_total * 100).toFixed(2) + '%</p>' + 
            '<p>$translations->{percentageFree}: ' + (server_storage_free / server_storage_total * 100).toFixed(2) + '%</p>';
        }

        function format_bytes(bytes) {
            if (bytes < 1024) {
                return bytes + ' B';
            } else if (bytes < 1048576) {
                return (bytes / 1024).toFixed(2) + ' KB';
            } else if (bytes < 1073741824) {
                return (bytes / 1048576).toFixed(2) + ' MB';
            } else {
                return (bytes / 1073741824).toFixed(2) + ' GB';
            }
        }

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

    <div class="hoverI">
        <p>Server Storage Information</p>
        <div class="tooltiptext">
            <p>$translations->{serverStorageInfo}</p>
            <p>$translations->{serverStorageUsed}: $formatted_server_storage_used</p>
            <p>$translations->{serverStorageFree}: $formatted_server_storage_free</p>
            <p>$translations->{serverStorageTotal}: $formatted_server_storage_total</p>
            <p>$translations->{serverStorageBottleneck}: $server_storage_bottleneck%</p>
            <p>$translations->{usableStorageLeft}: $usable_storage_left</p>
            <p>$translations->{usableStorageTotal}: $usable_storage_total</p>
            <p>$translations->{percentageTotal}: $percentage_total%</p>
            <p>$translations->{percentageFree}: $percentage_free%</p>
        </div>
    </div>

    <form action="/profile/ploud/upload" method="post" enctype="multipart/form-data" id="uploadForm" class="ploud_upload_form">
        <input type="file" name="file" id="fileInput">
        <input type="submit" value="$translations->{upload}" id="uploadButton">
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

    
    

#         $html_body .= <<HTML;
#     <div class="server_storage">
#         <p>$translations->{serverStorageInfo}</p>
#         <p>$translations->{serverStorageUsed}: $formatted_server_storage_used</p>
#         <p>$translations->{serverStorageFree}: $formatted_server_storage_free</p>
#         <p>$translations->{serverStorageTotal}: $formatted_server_storage_total</p>
#         <p>$translations->{serverStorageBottleneck}: $server_storage_bottleneck%</p>
#         <p>$translations->{usableStorageLeft}: $usable_storage_left</p>
#         <p>$translations->{usableStorageTotal}: $usable_storage_total</p>
#         <p>$translations->{percentageTotal}: $percentage_total%</p>
#         <p>$translations->{percentageFree}: $percentage_free%</p>
#     </div>
# HTML

    $html_body .= $script;
    
    my $html_content = html_structure::get_html($html_body, "Profile");
    
    return ($html_content);
}

1;