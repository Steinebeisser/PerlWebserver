package streaming_manage_channel;

use strict;
use warnings;

use Cwd;
use JSON;


my %locations = (
    "videos" => \&get_streaming_manage_channel_videos,
    "about" => \&get_streaming_manage_channel_about,
);

sub get_streaming_manage_channel {
    my ($username, $client_socket, $path) = @_;

    my $base_dir = getcwd();
    my $uuid = user_utils::get_uuid_by_username($username);
    my $channel_path = "$base_dir/Data/UserData/Users/$uuid/Streaming";
    my $videos_file = "$channel_path/videos.txt";

    if (!channel_utils::has_manage_access(user_utils::get_uuid_by_username($username))) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_401("You have no access to manage this channel, request permissions from the channel owner"));
        return;
    }

    my $html = <<HTML;
    <div class="StreamingManageChannel">
HTML
    if (!$path) {
        $html .= get_main_manage($username, $client_socket);
        $html .= get_region_changer($username);
    } else {
        my $id;
        if ($path =~ /(.*)\/(.*)/) {
            $path = $1;
            $id = $2;
        }
        $html .= get_region_changer($username);
        $html .= $locations{$path}($username, $client_socket, $id);
    }
    $html .= <<HTML;
    </div>
HTML

    my $html_content = html_structure::get_html($html, "Manage Channel");
    return $html_content;
}

sub get_region_changer {
    my ($username) = @_;

    my $html = <<HTML;
    <div class="ChooseManageRegion">
        <div class="ManageVideos">
            <a href="/streaming/manage/channel/$username/videos">Videos</a>
        </div>
        <div class="ManageAbout">
            <a href="/streaming/manage/channel/$username/about">About</a>
        </div>
        <div class="ManageInfo">
            <a href="/streaming/manage/channel/$username">Info</a>
        </div>
    </div>
HTML

    return $html;
}
sub get_streaming_manage_channel_videos {
    my ($username, $client_socket, $id) = @_;

    if ($id) {
        return get_streaming_manage_channel_single_video($username, $client_socket, $id);
    }
    my $uuid = user_utils::get_uuid_by_username($username);
    my $base_dir = getcwd();
    my $channel_path = "$base_dir/Data/UserData/Users/$uuid/Streaming";
    my $videos_file = "$channel_path/videos.txt";
    # print("VIDEOS FILE: $videos_file\n");
    my @videos = video_utils::get_videos($videos_file, 0, $uuid);

    my $html = <<HTML;
    <div class="channel_videos">
        <div class="Videos">
HTML
    foreach my $video (@videos) {
        my $video_id = $video->{video_id};
        my $video_title = user_utils::decode_uri($video->{title});
        my $video_description = $video->{description};
        $html .= <<HTML;
        <div class="Video">
            <button type="button" class="Thumbnail" onclick="window.location.href='/streaming/watch/v=$video_id'">
                <img src="/streaming/image/src/$video_id">
            </button>
            <div class="VideoTitle">
                <a href="/streaming/watch/v=$video_id">$video_title</a>
            </div>
            <div class="ManageVideo">
                <a href="/streaming/manage/channel/$username/videos/$video_id">Manage</a>
            </div>
        </div>
HTML
    }
    $html .= <<HTML;
        </div>
    </div>
HTML



    return $html;
}

sub get_streaming_manage_channel_single_video {
    my ($username, $client_socket, $video_id) = @_;


    my $uuid = user_utils::get_uuid_by_username($username);
    my $base_dir = getcwd();
    my $channel_path = "$base_dir/Data/UserData/Users/$uuid/Streaming";
    my $videos_file = "$channel_path/videos.txt";
    if (!-e $videos_file) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_404("Videos not found"));
    }
    if (!channel_utils::has_manage_access(user_utils::get_uuid_by_username($username))) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_401("You have no access to manage this channel, request permissions from the channel owner"));
        return;
    }
    open my $fh, "<", $videos_file;
    my $line;
    while ($line = <$fh>) {
        if ($line =~ /$video_id/) {
            last;
        }
    }
    close $fh;
    if (!$line) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_404("Video not found"));
        return;
    }

    my $file_path = "$base_dir/$line";
    $file_path =~ s/\n//;
    if (!-e $file_path) {
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_404("Video not found"));
        return;
    }
    # print("FILE PATH: $file_path\n");
    my $video = video_utils::get_video_metadata($file_path);
    if (!$video) {
        # print("Video not found\n");
        http_utils::serve_error($client_socket, HTTP_RESPONSE::ERROR_404("Video not found"));
        return;
    }
    my $video_title = user_utils::decode_uri($video->{title});
    my $video_description = $video->{description};

    my $html = <<HTML;
    <div class="ManageVideo">
        <div class="Video">
            <div class="VideoStatus">
HTML
    if ($video->{enabled}) {
        $html .= <<HTML;
                <div class="Enabled">
                    <h1>Enabled</h1><br>
                    <button class="DisableButton" onclick="disableVideo()">Disable</button>
                </div>
HTML
    } else {
        $html .= <<HTML;
                <div class="Disabled">
                    <h1>Disabled</h1>
                    <button class="EnableButton" onclick="enableVideo()">Enable</button>
                </div>
HTML
    }

    $html .= <<HTML;
            </div>
            <div class="PublicityInfo">
HTML
    if ($video->{private}) {
        $html .= <<HTML;
                <div class="Private">
                    <h1>Private</h1>
                    <button class="MakePublicButton" onclick="makeVideoPublic()">Make Public</button>
                </div>
HTML
    } else {
        $html .= <<HTML;
                <div class="Public">
                    <h1>Public</h1>
                    <button class="MakePrivateButton" onclick="makeVideoPrivate()">Make Private</button>
                </div>
HTML
    }
    $html .= <<HTML;
            </div>
            <div class="ManageThumbnail">
                <button type="button" class="Thumbnail" onclick="window.location.href='/streaming/watch/v=$video_id'">
                    <img src="/streaming/image/src/$video_id" alt="Video Thumbnail: $video_title">
                </button>
                <form action="/update/streaming/manage/channel/$username/videos/$video_id/thumbnail" method="post" enctype="multipart/form-data">
                    <input type="file" name="thumbnail" id="thumbnail">
                    <input type="submit" value="Upload Thumbnail">
                </form>
            </div>
            <div class="ManageVideoTitle">
                Title<br>
                <textarea id="video_title" name="video_title" form="video_title_form">$video_title</textarea>
                <button class="SaveButton" onclick="saveVideoTitle()">Save</button>
            </div>
            <div class="ManageVideoDescription">
                Description<br>
                <textarea id="video_description" name="video_description" form="video_description_form">$video_description</textarea>
                <button class="SaveButton" onclick="saveVideoDescription()">Save</button>
            </div>
            <div class="ManageVideoDelete">
                <button class="DeleteButton" onclick="deleteVideo()">Delete</button>
            </div>
        </div>
    </div>
HTML

    my $css = <<CSAS;
    <style>
        .Video {
            flex: 1 1 100%; 
            max-width: 90%;
            margin: auto;
        }
        .Enabled h1{
            color: green;
        }
        .Disabled h1{
            color: red;
        }
        .Public h1{
            color: green;
        }
        .Private h1{
            color: red;
        }
    </style>
CSAS

    $html .= $css;

    my $script = <<SCRIPT;
    <script>
        function disableVideo() {
            fetch("/update/streaming/manage/channel/$username/videos/$video_id/disable", {
                method: "POST",
            }).then(response => {
                if (response.ok) {
                    var VideoStatus = document.getElementsByClassName("VideoStatus")[0];
                    VideoStatus.innerHTML = '<div class="Disabled"><h1>Disabled</h1><br><button class="EnableButton" onclick="enableVideo()">Enable</button></div>';
                } else {
                    alert("Failed to disable video");
                }
            }).catch(error => {
                alert("Network error: " + error.message);
            });
        }

        function enableVideo() {
            fetch("/update/streaming/manage/channel/$username/videos/$video_id/enable", {
                method: "POST",
            }).then(response => {
                if (response.ok) {
                    var VideoStatus = document.getElementsByClassName("VideoStatus")[0];
                    VideoStatus.innerHTML = '<div class="Enabled"><h1>Enabled</h1><br><button class="DisableButton" onclick="disableVideo()">Disable</button></div>';
                } else {
                    alert("Failed to enable video");
                }
            }).catch(error => {
                alert("Network error: " + error.message);
            });
        }

        function saveVideoTitle() {
            var video_title = document.getElementsByName("video_title")[0].value;
            fetch("/update/streaming/manage/channel/$username/videos/$video_id/title", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                },
                body: JSON.stringify({
                    video_title: video_title,
                }),
            }).then(response => {
                if (response.ok) {
                    document.getElementsByName("video_title")[0].value = video_title;
                } else {
                    alert("Failed to save video title");
                }
            }).catch(error => {
                alert("Network error: " + error.message);
            });
        }

        function saveVideoDescription() {
            var video_description = document.getElementsByName("video_description")[0].value;
            fetch("/update/streaming/manage/channel/$username/videos/$video_id/description", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                },
                body: JSON.stringify({
                    video_description: video_description,
                }),
            }).then(response => {
                if (response.ok) {
                    document.getElementsByName("video_description")[0].value = video_description;
                } else {
                    alert("Failed to save video description");
                }
            }).catch(error => {
                alert("Network error: " + error.message);
            });

        }

        function deleteVideo() {
            if (!confirm("Are you sure you want to delete this video?")) {
                return;
            }
            fetch("/update/streaming/manage/channel/$username/videos/$video_id/delete", {
                method: "POST",
            }).then(response => {
                if (response.ok) {
                    window.location.href = "/streaming/manage/channel/$username/videos";
                } else {
                    alert("Failed to delete video");
                }
            }).catch(error => {
                alert("Network error: " + error.message);
            });
        }

        function makeVideoPublic() {
            fetch("/update/streaming/manage/channel/$username/videos/$video_id/public", {
                method: "POST",
            }).then(response => {
                if (response.ok) {
                    document.getElementsByClassName("PublicityInfo")[0].innerHTML = '<div class="Public"><h1>Public</h1><button class="MakePrivateButton" onclick="makeVideoPrivate()">Make Private</button></div>';
                } else {
                    alert("Failed to make video public");
                }
            }).catch(error => {
                alert("Network error: " + error.message);
            });
        }

        function makeVideoPrivate() {
            fetch("/update/streaming/manage/channel/$username/videos/$video_id/private", {
                method: "POST",
            }).then(response => {
                if (response.ok) {
                    document.getElementsByClassName("PublicityInfo")[0].innerHTML = '<div class="Private"><h1>Private</h1><button class="MakePublicButton" onclick="makeVideoPublic()">Make Public</button></div>';
                } else {
                    alert("Failed to make video private");
                }
            }).catch(error => {
                alert("Network error: " + error.message);
            });
        }
    </script>
SCRIPT

    $html .= $script;

    return $html;
}

sub get_streaming_manage_channel_about {
    my ($username, $client_socket) = @_;

    my $uuid = user_utils::get_uuid_by_username($username);
    my $base_dir = getcwd();
    my $streaming_path = "$base_dir/Data/UserData/Users/$uuid/Streaming";
    if (!-d $streaming_path) {
        mkdir $streaming_path;
    }
    my $channel_path = "$streaming_path/Channel";
    if (!-d $channel_path) {
        mkdir $channel_path;
    }
    my $about_file = "$channel_path/about.txt";

    # print("ABOUT FILE: $about_file\n");
    if (!-e $about_file) {
        # print("NO ABOUT FILE\n");
        open(my $fh, ">", $about_file);
        print $fh "No about information";
        close $fh;
    }

    open(my $fh, "<", $about_file);
    my $about = do { local $/; <$fh> };
    close $fh;

    my $html = <<HTML;
    <div class="channel_about">
        <div class="About">
            <textarea id="about" name="about">$about</textarea>
            <button class="SaveButton" onclick="saveAbout()">Save</button>
        </div>
    </div>
HTML

    my $script = <<SCRIPT;
    <script>
        function saveAbout() {
            var about = document.getElementsByName("about")[0].value;
            fetch("/update/streaming/manage/channel/$username/channel/about", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                },
                body: JSON.stringify({
                    about: about,
                }),
            }).then(response => {
                if (response.ok) {
                    document.getElementsByName("about")[0].value = about;
                } else {
                    alert("Failed to save about");
                }
            }).catch(error => {
                alert("Network error: " + error.message);
            });
        }
    </script>
SCRIPT

    $html .= $script;

    return $html;
}

sub get_main_manage {
    my ($username, $client_socket) = @_;
    
    my $uuid = user_utils::get_uuid_by_username($username);
    my $displayname = user_utils::decode_uri(user_utils::get_displayname_with_uuid($uuid));
    my $html = <<HTML;
    <div class="ChannelInfo">
        <div class="ChannelBanner">
            <img src="/streaming/image/channel_banner/$uuid" class="channel_banner">
            <form action="/update/streaming/manage/channel/$username/channel/banner" method="post" enctype="multipart/form-data">
                <input type="file" name="banner" id="banner">
                <input type="submit" value="Upload Banner">
            </form>
        </div>
        <div class="ChannelIcon">
            Must be 40x40 pixels<br>
            <img src="/streaming/image/channel_icon/$uuid" class="channel_icon">
            <form action="/update/streaming/manage/channel/$username/channel/icon" method="post" enctype="multipart/form-data">
                <input type="file" name="icon" id="iconInput" accept="image/png">
                <input type="submit" value="Upload Icon" id="iconSubmit">
            </form>
        </div>
        <div class="ChannelText">
            <div class="ChannelName">
                <div id="ChannelNameText" class="ChannelNameText">
                    <h1>Channel Name</h1><br>
                    <h1>$displayname</h1>
                </div>
                <input type="text" id="displayname" name="displayname" value="$displayname">
                <button class="ChangeDisplaynameButton" onclick="changeDisplayname()">Change Displayname</button>
            </div>
        </div>
    </div>
HTML

    #! img size validation perl on uplaod again
    my $script = <<SCRIPT;
    <script>
        var channelUsername = "$username";
        document.getElementById("iconInput").addEventListener("change", function(event) {
            var iconFile = event.target.files[0];
            
            var img = new Image();
            img.onload = function() {
                if (img.width != 40 || img.height != 40) {
                    alert("Icon must be 40x40 pixels");
                    event.preventDefault();
                    document.getElementById("iconInput").value = "";
                } else {
                    alert("Icon is 40x40 pixels");
                }
            };
            img.src = URL.createObjectURL(iconFile);
        });

        function changeDisplayname() {
            var displayname = document.getElementById("displayname").value;
            fetch("/update/streaming/manage/channel/" + channelUsername + "/channel/displayname", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                },
                body: JSON.stringify({
                    displayname: displayname,
                }),
            }).then(response => {
                if (response.ok) {
                    document.getElementById("ChannelNameText").innerHTML = ("<h1>Channel Name</h1><br><h1>" + displayname + "</h1>");
                } else {
                    alert("Failed to change displayname");
                }
            }).catch(error => {
                alert("Network error: " + error.message);
            });
        }
    </script>
SCRIPT

    $html .= $script;

    return $html;
}


1;
