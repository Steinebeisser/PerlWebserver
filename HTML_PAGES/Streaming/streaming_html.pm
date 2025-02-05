package streaming_html;

use strict;
use warnings;

sub get_streaming_home {

    my $translations = language_utils::load_language("streaming");

    my @videos = video_utils::get_top_videos();
    my $html = <<HTML;
    <div class="StreamingView">
HTML
        $html .= get_streaming_top();
        $html .= <<HTML;
        <div class="StreamingMain">
HTML
        $html .= get_streaming_left();
        $html .= <<HTML;
            <div class="StreamingMainCenter">
                <div class="StreamingMainCenterTop">
                    <div class="Videos">
HTML

    foreach my $video (@videos) {
        $html .= video_utils::create_video_emblem($video);
    }

    $html .= <<HTML;
                    </div>
                </div>
            </div>
HTML
    $html .= get_streaming_right();
    $html .= <<HTML;
        </div>
    </div>
HTML

    my $html_content = html_structure::get_html($html, "Streaming");

    return $html_content;

}

sub get_streaming_top {
    my $username;
    if ($main::user) {
        $username = $main::user->{username};
    }
    my $html = <<HTML;
        <div class="StreamingTop">
            <div class="StreamingTopLeft">
                <a href="/streaming">Home</a>
            </div>
            <div class="StreamingTopCenter">
                <div class="Search">
                    <input type="text" placeholder="Search..." name="search">
                    <button type="submit">Search</button>
                </div>
            </div>
            <div class="StreamingTopRight">
                <a href="/streaming/channel/$username">Channel</a>
            </div>
        </div>
HTML
    return $html;
}

#! NEED TO GET FOLLOWING AGAIN
sub get_streaming_left {
    my $html = <<HTML;
            <div class="StreamingMainLeft">
                <div class="StreamingMainLeftTop">
                    <div class="MainPage">
                        <a href="/streaming">Video Main</a>
                    </div>
                </div>
                <div class="StreamingMainLeftCenter">
                    <div class="Following">
                    </div>
                </div>
            </div>
HTML
    return $html;
}

sub get_streaming_right {
    my $html = <<HTML;
                <div class="StreamingMainRight">
HTML
    if ($main::user) {
        $html .= <<HTML;
                <div class="Account">
                    <a href="/streaming/channel/$main::user->{username}">My Channel</a>
                </div>
                <div class="ManageAccount">
                    <a href="/streaming/manage/channel/$main::user->{username}">Manage Account</a>
                </div>
HTML
    }
    $html .= <<HTML;
                <div class="Upload">
                    <a href="/streaming/upload">Upload</a>
                </div>
            </div>
HTML
    return $html;
}

#! logic if subscribed with data and so on
sub get_subscribe_button {
    my ($channel_username) = @_;
    my $html = <<HTML;
    <div class="SubscribeButton">
        <button onclick="subscribeChannel($channel_username)">Subscribe</button>
    </div>
HTML

    my $script = <<'SCRIPT';
    <script>
    function subscribeTo(username) {
        //username = decodeURIComponent(username);
        fetch(`/streaming/channel/${username}/subscribe`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
        }).then(response => {
            if (response.ok) {
                document.getElementById("SubscribeButton").innerHTML = `<button type='button' onclick='unsubscribeFrom(\`${username}\`)'>Unsubscribe</button>`;
                document.getElementById("SubscriberCount").innerHTML = `${parseInt(document.getElementById("SubscriberCount").innerHTML) + 1} subscriber`;
            } else {
                alert('Failed to subscribe');
            }
        }).catch(error => {
            alert('Error: ' + error);
        });
    }

    function unsubscribeFrom(username) {
        //username = decodeURIComponent(username);
        fetch(`/streaming/channel/${username}/unsubscribe`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
        }).then(response => {
            if (response.ok) {
                document.getElementById("SubscribeButton").innerHTML = `<button type='button' onclick='subscribeTo(\`${username}\`)'>Subscribe</button>`;
                document.getElementById("SubscriberCount").innerHTML = `${parseInt(document.getElementById("SubscriberCount").innerHTML) - 1} subscriber`;
            } else {
                alert('Failed to unsubscribe');
            }
        }).catch(error => {
            alert('Error: ' + error);
        });
    }

    function subscribeToLogin () {
        alert('Please login to subscribe');
    }
</script>
SCRIPT

    $html .= $script;

    return $html;
}

sub get_video_loading_script  {
    my ($channel_uuid) = @_;
    my $script = <<SCRIPT;
    <script>
        var channelUuid = $channel_uuid;
        var noMoreVideos = false;
        var isLoading = false;

        function loadMoreVideos() {
            if(isLoading) {
                return;
            }
            startLoading();

            var videos = document.getElementsByClassName("Video");
            var lastVideoID = videos.length - 1;
            lastVideoID++;
            
            var fetchUri;
            if (channelUuid) {
                fetchUri = "/streaming/videos/" + channelUuid + "/" + lastVideoID;
            } else {
                fetchUri = "/streaming/videos/" + lastVideoID;
            }
            fetch(fetchUri, {
                method: "GET",
                headers: {
                    "Content-Type": "application/json"
                }
            }).then(response => {
                if (response.ok) {
                    if (response.status == 204) {
                        noMoreVideos = true;
                        stopLoading();
                        return;
                    }
                    return response.json();
                } else {
                    stopLoading();
                }
            }).then(data => {
                for (var i = 0; i < data.length; i++) {
                    createVideoEmblem(data[i]);
                }
                stopLoading();
            }).catch(error => {
                stopLoading();
            });
        }

        function startLoading() {
            isLoading = true;
            var loadingDiv = document.getElementsByClassName("Loading")[0];
            loadingDiv.style.display = "block";
        }

        function stopLoading() {
            isLoading = false;
            var loadingDiv = document.getElementsByClassName("Loading")[0];
            loadingDiv.style.display = "none";
        }
        window.onscroll = function() {
        var {scrollTop, clientHeight, scrollHeight} = document.documentElement;

            if (scrollTop + clientHeight + 50 >= scrollHeight && !noMoreVideos) {
                loadMoreVideos();
            }
        };

        function createVideoEmblem(video) {
            var videosContainer = document.getElementsByClassName("Videos")[0];
            if (!videosContainer) {
                videosContainer = document.getElementsByClassName("OtherVideos")[0];
            }
            var videoTemplate = document.getElementsByClassName("Video")[0];
            var newVideo = videoTemplate.cloneNode(true);

            var thumbnailButton = newVideo.querySelector(".Thumbnail");
            var thumbnailImg = thumbnailButton.querySelector("img");
            thumbnailImg.src = "/streaming/image/src/" + video.video_id;
            thumbnailImg.alt = "Video Thumbnail: " + video.title;
            thumbnailButton.onclick = function() {
                window.location.href = "/streaming/watch/v=" + video.video_id;
            };

            var channelIconButton = newVideo.querySelector(".ChannelIcon");
            if (channelIconButton) {
                var channelIconImg = channelIconButton.querySelector("img");
                channelIconImg.src = "/streaming/image/channel_icon/" + video.channel_uuid;
                channelIconButton.onclick = function() {
                    window.location.href = "/streaming/channel/" + video.channel_username;
                };
            }

            var videoTitleDiv = newVideo.querySelector(".VideoTitle");
            var videoTitleLink = videoTitleDiv.querySelector("a");
            videoTitleLink.href = "/streaming/watch/v=" + video.video_id;
            videoTitleLink.title = video.title;
            videoTitleLink.innerText = video.title;

            var channelNameDiv = newVideo.querySelector(".ChannelName");
            if (channelNameDiv) {
                channelNameDiv.innerHTML = '<a href="/streaming/channel/' + video.channel_username + '">' + decodeURI(video.channel_name) + '</a>';
            }

            var videoViewsDiv = newVideo.querySelector(".VideoViews");
            if (videoViewsDiv) {
                videoViewsDiv.innerText = video.views + " views";
            }

            var videoUploadDateDiv = newVideo.querySelector(".VideoUploadDate");
            if (videoUploadDateDiv) {
                videoUploadDateDiv.innerText = getAgoTime(video.uploaded_at);
            }

            videosContainer.appendChild(newVideo);
        }

        function getAgoTime(timestamp) {
            var currentTime = Math.floor(Date.now() / 1000);
            var timeDiff = currentTime - timestamp;
            
            var seconds = timeDiff % 60;
            var minutes = Math.floor(timeDiff / 60);
            var hours = Math.floor(minutes / 60);
            var days = Math.floor(hours / 24);
            var months = Math.floor(days / 30);
            var years = Math.floor(months / 12);
            
            if (years > 0) {
                return years + " years ago";
            } else if (months > 0) {
                return months + " months ago";
            } else if (days > 0) {
                return days + " days ago";
            } else if (hours > 0) {
                return hours + " hours ago";
            } else if (minutes > 0) {
                return minutes + " minutes ago";
            } else {
                return seconds + " seconds ago";
            }
        }

        const observer = new IntersectionObserver(entries => {
            if (!noMoreVideos && !isLoading) {
                loadMoreVideos();
            }
        })
        observer.observe(document.getElementsByClassName("Loading")[0]);
    </script>
SCRIPT

    return $script;
}
1;