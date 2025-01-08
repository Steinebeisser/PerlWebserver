package streaming_upload;

use strict;
use warnings;

sub get_streaming_upload {
    my $translations = language_utils::load_language("streaming");

    my $html = <<HTML;
    <div class="streaming_upload">
        <form action="/streaming/upload" method="post" enctype="multipart/form-data" id="uploadForm">
            <input type="file" name="file" id="videoFileInput" accept="video/*">
            <input type="title" name="title" placeholder="$translations->{title}">
            <input type="description" name="description" placeholder="$translations->{description}">
            <input type="file" name="thumbnail" id="thumbnailInput" placeholder="$translations->{thumbnail}" accept="image/*">
            <input type="submit" id="uploadButton" value="$translations->{upload}">
        </form>
    </div>
HTML


    my $server_storage = user_utils::get_server_storage();
    my $server_storage_free = $server_storage->{free};
    my $server_storage_bottleneck = $server::storage_bottleneck * 100;

    my $script = <<Script;
    <script>
        var server_storage_free = $server_storage_free;
        var server_storage_bottleneck = $server_storage_bottleneck;

        var available_server_storage = server_storage_free * server_storage_bottleneck;
        var upload_size = 0;
        var thumbnailSize = 0;
        var videoSize = 0;

        document.getElementById('videoFileInput').addEventListener('change', function(event) {
            const file = event.target.files[0];

            if (file) {
                videoSize = file.size;

                upload_size = videoSize + thumbnailSize;

                if (upload_size > available_server_storage) {
                    event.preventDefault();
                    alert('Server storage is full. We are working on it. Please try again later.');
                    document.getElementById('videoFileInput').value = '';
                    contact_devs("Storage full");
                    return;
                }

            }
        });

        document.getElementById('thumbnailInput').addEventListener('change', function(event) {
            const file = event.target.files[0];

            if (file) {
                thumbnailSize = file.size;

                upload_size = videoSize + thumbnailSize;

                if (upload_size > available_server_storage) {
                    event.preventDefault();
                    alert('Server storage is full. We are working on it. Please try again later.');
                    document.getElementById('thumbnailInput').value = '';
                    contact_devs("Storage full");
                    return;
                }
            }
        })

        document.getElementById('uploadButton').addEventListener('click', function(event) {
            event.preventDefault(); // Prevent default form submission
            console.log('Upload button clicked');
            upload_size = document.getElementById('videoFileInput').files[0].size + document.getElementById('thumbnailInput').files[0].size;
            get_server_storage().then(function(available_server_storage) {
                if (upload_size > available_server_storage) {
                    alert('Server storage is full. We are working on it. Please try again later.');
                    contact_devs("Storage full");
                    return;
                }
                console.log('Upload Size: ' + upload_size + ', Available Server Storage: ' + available_server_storage);
                // Proceed with the upload
                document.getElementById('uploadForm').submit();               
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
                server_storage_free = data.free;
                console.log('server_storage_free - old_server_storage_free: ' + (server_storage_free - old_server_storage_free));
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
Script

    $html .= $script;

    my $html_content = html_structure::get_html($html, "Streaming");

    return $html_content;
}

1;