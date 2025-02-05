package streaming_video;

use strict;
use warnings;

sub get_streaming_video {
    my ($video_id) = @_;

    my $translations = language_utils::load_language("streaming");

    my $html = <<HTML;
    <div class="StreamingView">
HTML
    $html .= streaming_html::get_streaming_top();
    $html .= <<HTML;
        <div class="StreamingMain">
HTML
    $html .= streaming_html::get_streaming_left();
    $html .= <<HTML;
            <div class="StreamingMainCenter">
                <div class="streaming_video">
                    <video src="/streaming/video/src/$video_id" width="60%" controls></video>
                </div>
                <div class="streaming_video_info">
                    <div class="VideoTitle">
                        <h1>#!title</h1>
                    </div>
                    <div class="Group">
                        <div class="ChannelInfo">
                            <div class="ChannelIcon" onclick="window.location.href='/streaming/channel/#!username'">
                                <img src="/streaming/image/channel_icon/#!uuid" class="channel_icon">
                            </div>
                            <div class="ChannelText">
                                <div class="ChannelName">
                                    <a href="/streaming/channel/#!displayname">aye♥</a>
                                </div>
                                <div class="Subscribers" id="SubscriberCount">
                                    #!subscirbercount
                                </div>
                            </div>
HTML
    $html .= streaming_html::get_subscribe_button();#!channel_username
    $html .= <<HTML;     
                        </div>
                        <div class="VideoUtils">
                            <div class="Reviews">
                                <div class="Like">
                                    <button type="button" class="LikeButton" onclick="likeVideo(`#!video_id`)" id=Like0>
                                        <div class="LikeAmount" id="LikeAmount">
                                            #!likes
                                        </div>
                                        👍
                                    </button>
                                </div>
                                <div class="Dislike">
                                    <button type="button" class="DislikeButton" onclick="dislikeVideo(`#!video_id`)" id=Dislike-1>
                                        <div class="DislikeAmount" id="DislikeAmount">
                                            #!dislikes
                                        </div>
                                        👎
                                    </button>
                                </div>
                            </div>
                            <div class="Share">
                                <button type="button" id="ShareButton" onclick="shareVideo(`#!video_id`)">Share</button>
                            </div>
                        </div>
                    </div>
                    <div class="VideoInfo" onclick="expandDescription()">
                        <div class="Group">
                            <div class="VideoViews">
                                #!views
                            </div>
                            <div class="VideoUploadDate">
                                #!upload_date
                            </div>
                        </div>
                        <br>
                        <div class="VideoDescription" id="VideoDescription">
                            #!description
                            <br>
                            <div class="CloseDescription">
                                <button type="button" onclick="event.stopPropagation(); collapseDescription()">Close</button>
                            </div>

                        </div>
                    </div>
                </div>
                <div class="Comments">
                    <h2>Comments</h2>
                    <div class="CommentInput">
                        <div class="CommentUser">
                            <img src="/streaming/image/channel_icon/#!user_uuid" alt="User Icon" onclick="window.location.href='/streaming/channel/#!username'" onload="loadNextComments(`#!video_id`)"/>
                        </div>
                        <div class="CommentSetup">
                            <textarea placeholder="Write a comment..." id="CommentInput"></textarea>
                            <button type="button" onclick="commentVideo(`#!video_id`)">Comment</button>
                        </div>
                    </div>
                    <div class="CommentsList"></div>
                    <div class="Loading" id="Loading">
                        LOADING COMMENTS
                    </div>
                </div> 
            </div>
            <div class="StreamingMainRight">
                <div class="OtherVideos">
                    <h2>Other videos</h2>
                    #! get videos
                    <div class="Video">
                        <button type="button" class="Thumbnail" onclick="window.location.href='/streaming/watch/v=NGUwNzQwODU'">
                            <img src="/streaming/image/src/NGUwNzQwODU" alt="Video Thumbnail: YEYE">
                        </button>
                        <div class="VideoMetadata">
                            <button type="button" class="ChannelIcon" onclick="window.location.href='/streaming/channel/%E2%99%A5'">
                                <img src="/streaming/image/channel_icon/b5ab5ec9-7ccb-f96c-0f42-89715eb52cd9" alt="Channel Icon">
                            </button>
                            <div class="OtherMetadata">
                                <div class="VideoTitle">
                                    <a href="/streaming/watch/v=NGUwNzQwODU" title="YEYE">YEYE</a>
                                </div>
                                <div class="ChannelName">
                                    <a href="/streaming/channel/%E2%99%A5">aye♥</a>
                                </div>
                                <div class="VideoInline">
                                    <div class="VideoViews">
                                        3 views
                                    </div>
                                    <div class="VideoSeparator">
                                        •
                                    </div>
                                    <div class="VideoUploadDate">
                                        6 days ago
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
HTML

    $html .= streaming_html::get_video_loading_script();

    my $script = <<SCRIPT;
    <script>
        var isLiked = 0;
        var isDisliked = 1;
        const video_id = `$video_id`;
        var isLoading = false;
        var noMoreComments = false;
        var textWritten;
        var myUUID = ``; //#! channel_uuid
SCRIPT
    
    $script .= <<'SCRIPT';
        function expandDescription() {
            var description = document.getElementsByClassName('VideoDescription')[0];
            description.style.display = 'block';
        }

        function collapseDescription() {
            var description = document.getElementById('VideoDescription');
            description.style.display = '-webkit-box';
            console.log(description);
        }

        function likeVideo(video_id) {
            fetch(`/update/streaming/video/like/${video_id}`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
            }).then(response => {
                if (response.ok) {
                    var likesAmount = document.getElementById('LikeAmount').innerHTML;
                    var likeButton = document.getElementsByClassName('LikeButton')[0];
                    var dislikeButton = document.getElementsByClassName('DislikeButton')[0];
                    if (isLiked) {
                        document.getElementById('LikeAmount').innerHTML = parseInt(likesAmount) - 1;
                        isLiked = 0;
                        likeButton.id = 'Like0';
                        return;
                    } else if (isDisliked) {
                        var dislikesAmount = document.getElementById('DislikeAmount').innerHTML;
                        document.getElementById('DislikeAmount').innerHTML = parseInt(dislikesAmount) - 1;
                        isDisliked = 0;
                        dislikeButton.id = 'Dislike0';
                    }
                    document.getElementById('LikeAmount').innerHTML = parseInt(likesAmount) + 1;
                    isLiked = 1;
                    likeButton.id = 'Like1';
                }
            })
        }

        function dislikeVideo(video_id) {
            fetch(`/update/streaming/video/dislike/${video_id}`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
            }).then(response => {
                if (response.ok) {
                    var dislikesAmount = document.getElementById('DislikeAmount').innerHTML;
                    var dislikeButton = document.getElementsByClassName('DislikeButton')[0];
                    var likeButton = document.getElementsByClassName('LikeButton')[0];
                    if (isDisliked) {
                        document.getElementById('DislikeAmount').innerHTML = parseInt(dislikesAmount) - 1;
                        isDisliked = 0;
                        dislikeButton.id = 'Dislike0';
                        return;
                    } else if (isLiked) {
                        var likesAmount = document.getElementById('LikeAmount').innerHTML;
                        document.getElementById('LikeAmount').innerHTML = parseInt(likesAmount) - 1;
                        isLiked = 0;
                        likeButton.id = 'Like0';
                    }
                    document.getElementById('DislikeAmount').innerHTML = parseInt(dislikesAmount) + 1;
                    isDisliked = 1;
                    dislikeButton.id = 'Dislike-1';
                }
            })
        }

        function shareVideo(video_id) {
            document.getElementById('ShareField').style.display = 'flex';
        }

        function commentVideo(video_id) {
            var comment = document.getElementById('CommentInput').value;
            document.getElementById('CommentInput').value = '';
            fetch(`/update/streaming/video/comment/${video_id}`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    comment: comment,
                }),
            }).then(response => {
                if (response.ok) {
                    response.json().then(data => {
                        var commentList = document.getElementsByClassName('CommentsList')[0];
                        commentList.innerHTML = createCommentHtml(data) + commentList.innerHTML;
                        console.log('Commented');
                    })
                } else {
                    console.log('Failed to comment');
                }
            }).catch(error => {
                console.log('Failed to comment');
            })
        }

        function loadNextComments(video_id) {
            console.log('Loading next comments');
            if (isLoading) {
                return;
            }
            startLoading();
            var commentList = document.getElementsByClassName('CommentsList')[0];
            var comments = document.getElementsByClassName('Comment');
            var lastCommentID;
            if (comments.length > 0) {
                lastCommentID = comments[comments.length - 1].id;
            } else {
                lastCommentID = 0;
            }

            
            fetch(`/streaming/video/comments/${video_id}/${lastCommentID}`, {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json',
                },
            }).then(response => {
                if (response.ok) {
                    if (response.status === 204) {
                        console.log('No more comments');
                        noMoreComments = true;
                        stopLoading();
                        return;
                    }
                    console.log('Loaded comments');
                    response.json().then(data => {
                        for (var i = 0; i < data.length; i++) {
                            console.log(data[i]);
                            console.log(commentList);
                            commentList.innerHTML += createCommentHtml(data[i]);
                        }
                        stopLoading();
                    });
                } else {
                    console.log('Failed to load comments');
                    stopLoading();
                }
            }).catch(error => {
                console.log('Failed to load comments');
                stopLoading();
            })
        }

        function startLoading() {
            isLoading = true;
            displayLoading();
        }

        function displayLoading() {
            var loading = document.getElementById('Loading');
            loading.style.display = 'block';
        }

        function stopLoading() {
            isLoading = false;
            hideLoading();
        }

        function hideLoading() {
            var loading = document.getElementById('Loading');
            loading.style.display = 'none';
        }

        function createCommentHtml(comment, isReply) {
            var displayName = decodeURI(comment.author_displayname);
            var userUUID = comment.author_uuid;
            var repliesHTML = '';
            console.log(comment.replies);

            if (comment.replies && Object.keys(comment.replies).length > 0) {
                repliesHTML = `
                    <div class="Replies">
                        <button class="RepliesButton" onclick="toggleReplies('${comment.comment_id}')">
                            Show replies (${Object.keys(comment.replies).length})
                        </button>
                        <div class="RepliesContainer" id="replies-${comment.comment_id}">
                `;
                        
                Object.values(comment.replies).forEach(reply => {
                    var replyHTML = createCommentHtml(reply, true);
                    repliesHTML += replyHTML;
                    console.log("REPLY: ", reply);
                });

                repliesHTML += `</div></div>`;
            }

            var initReplyInput = '';
            if (!isReply) {
                initReplyInput = `
                    <div class="ReplyInput">
                        <div class="UserSuggestions" id="UserSuggestions"></div>
                        <input type="text" class="ReplyTextfield" placeholder="Write a reply..." id="@$userUUID"><p class=">@${displayName} </textarea>
                        <button type="button" class="ReplyReplyButton" onclick="replyToComment('${comment.comment_id}')">Reply</button>
                        <button type="button" class="ReplyCloseButton" onclick="closeReply('${comment.comment_id}')">X</button>
                    </div>
                `;
            } else {
                initReplyInput = `
                    <div class="ReplyInput">
                        <div class="UserSuggestions" id="UserSuggestions"></div>
                        <div class="ReplyTextfield" placeholder="Write a reply..." contenteditable="true"><span class="user-mention" data-uuid="${userUUID}" onclick="showUser('${userUUID}')">@${displayName}</span> </div>
                        <button type="button" class="ReplyReplyButton" onclick="replyToReply('${comment.parent_comment_id}', '${comment.comment_id}')">Reply</button>
                        <button type="button" class="ReplyCloseButton" onclick="closeReply('${comment.comment_id}', '${comment.parent_comment_id}')">X</button>
                    </div>
                `;
            }

            var initReplyButton = '';
            if (!isReply) {
                initReplyButton = `
                    <button class="Reply" onclick="replyComment('${comment.comment_id}')">
                        Reply
                    </button>
                `;
            } else {
                initReplyButton = `
                    <button class="Reply" onclick="replyReply('${comment.parent_comment_id}', '${comment.comment_id}')">
                        Reply
                    </button>
                `;
            }

            var divId = `<div class="Comment" id="${comment.comment_id}">`;
            if (isReply) {
                divId = `<div class="ReplyComment" id="Reply-${comment.parent_comment_id}-${comment.comment_id}">`;
            }

            var likeButton;
            if (!isReply) {
                likeButton = `
                                <button type="button" class="LikeButton" onclick="likeComment('${comment.comment_id}')" id="Like${comment.liked}">
                                    <div class="LikeAmount">
                                        ${comment.likes}
                                    </div>
                                    👍
                                </button>
                `;
            } else {
                likeButton = `
                                <button type="button" class="LikeButton" onclick="likeReply('${comment.parent_comment_id}', '${comment.comment_id}')" id="Like${comment.liked}">
                                    <div class="LikeAmount">
                                        ${comment.likes}
                                    </div>
                                    👍
                                </button>
                `;
            }

            var dislikeButton;
            if (!isReply) {
                dislikeButton = `
                                <button type="button" class="DislikeButton" onclick="dislikeComment('${comment.comment_id}')" id="Dislike${comment.liked}">
                                    <div class="DislikeAmount">
                                        ${comment.dislikes}
                                    </div>
                                    👎
                                </button>
                `;
            } else {
                dislikeButton = `
                                <button type="button" class="DislikeButton" onclick="dislikeReply('${comment.parent_comment_id}', '${comment.comment_id}')" id="Dislike${comment.liked}">
                                    <div class="DislikeAmount">
                                        ${comment.dislikes}
                                    </div>
                                    👎
                                </button>
                `;
            }

            
            var commentText = decodeURI(comment.comment);
            if (commentText.match(/class="user-mention"/))
            {
                console.log("MENTIONS SOMEONE");
                var mention_uuid = commentText.match(/data-uuid="(.*)" onclick/)[1];
                console.log("MENTION_UUID", mention_uuid);
                console.log("MY UUID", myUUID);
                if (mention_uuid === myUUID) {
                    console.log("MENTIONS MEEEEEEE");
                    commentText = commentText.replace(/class="user-mention"/, 'class="user-mention" id="MentionedMe"');
                }
            }
            
            var commentHtml = `
                ${divId}
                    <div class="topCommentBar">
                        <div class="Displayname">
                            ${displayName}
                        </div>
                        •
                        <div class="Date">
                            ${comment.comment_date}
                        </div>
                    </div>
                    <div class="CommentUser">
                        <img src="/streaming/image/channel_icon/${comment.author_username}" alt="User Icon"
                            onclick="window.location.href='/streaming/channel/${comment.author_username}'"/>
                    </div>
                    <div class="CommentText">
                        ${commentText}
                    </div>
                    <div class="CommentOneLine">
                        <div class="Reviews">
                            <div class="Like">
                                ${likeButton}
                            </div>
                            <div class="Dislike">
                                ${dislikeButton}
                            </div>
                        </div>
                        ${initReplyButton}
                    </div>
                    ${initReplyInput}
                    <div class="Liked" id="Liked${comment.liked}"></div>
                    ${repliesHTML}
                </div>

            `;
        
    return commentHtml;
}


    function closeReply(commentID, parentCommentID) {
        var comment;    
        if (parentCommentID) {
            comment = document.getElementById(`Reply-${parentCommentID}-${commentID}`);
        } else {
            comment = document.getElementById(commentID);
        }
        console.log("COMMENT", comment);
        var displaynameElement = comment.querySelector('.Displayname');
        var displayName = displaynameElement.textContent.trim();
        var replyInput = comment.getElementsByClassName('ReplyInput')[0];
        replyInput.style.display = 'none';
        var replyTextfield = replyInput.getElementsByClassName('ReplyTextfield')[0];
        replyTextfield.value = '@' + displayName + ' ';
    }

    function replyReply(parentCommentID, commentID) {
        console.log("REPLYING TO REPLY");
        var comment = document.getElementById(`Reply-${parentCommentID}-${commentID}`);
        console.log(comment);
        var replyInput = comment.getElementsByClassName('ReplyInput')[0];
        console.log(replyInput);
        replyInput.style.display = 'flex';
    }

    function replyComment(commentID) {
        var comment = document.getElementById(commentID);
        var replyInput = comment.getElementsByClassName('ReplyInput')[0];
        replyInput.style.display = 'flex';
    }

    function replyToComment(commentID) {
        var comment = document.getElementById(commentID);
        var replyInput = comment.getElementsByClassName('ReplyInput')[0];
        var replyTextfield = replyInput.getElementsByClassName('ReplyTextfield')[0];
        var reply = replyTextfield.value;
        var pingedUserUUID = replyTextfield.id;
        fetch(`/update/streaming/video/comments/reply/${video_id}/${commentID}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                reply: reply,
                pingedUserUUID: pingedUser
            }),
        }).then(response => {
            if (response.ok) {
                response.json().then(data => {
                    var commentList = document.getElementsByClassName('CommentsList')[0];
                    commentList.innerHTML = createCommentHtml(data) + commentList.innerHTML;
                    console.log('Replied');
                })
            } else {
                console.log('Failed to reply');
            }
        }).catch(error => {
            console.log('Failed to reply');
        })
    }

    function replyToReply(ParentCommentID, commentID) {
        var comment = document.getElementById(`Reply-${ParentCommentID}-${commentID}`);
        var replyInput = comment.getElementsByClassName('ReplyInput')[0];
        var replyTextfield = replyInput.getElementsByClassName('ReplyTextfield')[0];
        var reply = replyTextfield.innerHTML;
        fetch(`/update/streaming/video/comments/reply/${video_id}/${commentID}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                reply: reply,
            }),
        }).then(response => {
            if (response.ok) {
                response.json().then(data => {
                    var commentList = document.getElementsByClassName('CommentsList')[0];
                    commentList.innerHTML = createCommentHtml(data) + commentList.innerHTML;
                    console.log('Replied');
                })
            } else {
                console.log('Failed to reply');
            }
        }).catch(error => {
            console.log('Failed to reply');
        })
    }


    function likeComment(commentID) {
        console.log('Liking comment');
        fetch(`/update/streaming/video/comments/like/${video_id}/${commentID}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
        }).then(response => {
            if (response.ok) {
                console.log('Liked comment');
                var Comment = document.getElementById(commentID);
                var LikeButton = Comment.getElementsByClassName('LikeButton')[0];
                var DislikeButton = Comment.getElementsByClassName('DislikeButton')[0];
                var LikeAmount = Comment.getElementsByClassName('LikeAmount')[0];
                var DislikeAmount = Comment.getElementsByClassName('DislikeAmount')[0];
                if (LikeButton.id === 'Like1') {
                    LikeButton.id = 'Like0';
                    DislikeButton.id = 'Dislike0';
                    LikeAmount.innerHTML = parseInt(LikeAmount.innerHTML) - 1;
                } else if (LikeButton.id === 'Like-1') {
                    LikeButton.id = 'Like1';
                    LikeAmount.innerHTML = parseInt(LikeAmount.innerHTML) + 1;
                    DislikeButton.id = 'Dislike1';
                    DislikeAmount.innerHTML = parseInt(DislikeAmount.innerHTML) - 1;
                } else {
                    LikeButton.id = 'Like1';
                    DislikeButton.id = 'Dislike1';
                    LikeAmount.innerHTML = parseInt(LikeAmount.innerHTML) + 1;
                }
            } else {
                console.log('Failed to like comment');
            }
        }).catch(error => {
            console.log('Failed to like comment');
        })
    }

    function likeReply(ParentCommentID, commentID) {
        console.log('Liking reply');
        fetch(`/update/streaming/video/replies/like/${video_id}/${ParentCommentID}/${commentID}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
        }).then(response => {
            if (response.ok) {
                var comment = document.getElementById(`Reply-${ParentCommentID}-${commentID}`);
                var likesAmount = comment.getElementsByClassName('LikeAmount')[0].innerHTML;
                var dislikesAmount = comment.getElementsByClassName('DislikeAmount')[0].innerHTML;
                var likeButton = comment.getElementsByClassName('LikeButton')[0];
                var dislikeButton = comment.getElementsByClassName('DislikeButton')[0];
                if (likeButton.id === 'Like1') {
                    comment.getElementsByClassName('LikeAmount')[0].innerHTML = parseInt(likesAmount) - 1;
                    likeButton.id = 'Like0';
                    dislikeButton.id = 'Dislike0';
                    return;
                } else if (likeButton.id === 'Like-1') {
                    comment.getElementsByClassName('DislikeAmount')[0].innerHTML = parseInt(dislikesAmount) - 1;
                    dislikeButton.id = 'Dislike0';
                }
                comment.getElementsByClassName('LikeAmount')[0].innerHTML = parseInt(likesAmount) + 1;
                dislikeButton.id = 'Dislike1';
                likeButton.id = 'Like1';
                console.log('Liked reply');
            } else {
                console.log('Failed to like reply');
            }
        }).catch(error => {
            console.log('Failed to like reply');
        })
    }

    function dislikeComment(commentID) {
        console.log('Disliking comment');
        fetch(`/update/streaming/video/comments/dislike/${video_id}/${commentID}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
        }).then(response => {
            if (response.ok) {
                console.log('Disliked comment');
                var Comment = document.getElementById(commentID);
                var LikeButton = Comment.getElementsByClassName('LikeButton')[0];
                var DislikeButton = Comment.getElementsByClassName('DislikeButton')[0];
                var LikeAmount = Comment.getElementsByClassName('LikeAmount')[0];
                var DislikeAmount = Comment.getElementsByClassName('DislikeAmount')[0];
                if (DislikeButton.id === 'Dislike-1') {
                    DislikeButton.id = 'Dislike0';
                    LikeButton.id = 'Like0';
                    DislikeAmount.innerHTML = parseInt(DislikeAmount.innerHTML) - 1;
                } else if (DislikeButton.id === 'Dislike1') {
                    LikeButton.id = 'Like-1';
                    LikeAmount.innerHTML = parseInt(LikeAmount.innerHTML) - 1;
                    DislikeButton.id = 'Dislike-1';
                    DislikeAmount.innerHTML = parseInt(DislikeAmount.innerHTML) + 1;
                } else {
                    DislikeButton.id = 'Dislike-1';
                    LikeButton.id = 'Like-1';
                    DislikeAmount.innerHTML = parseInt(DislikeAmount.innerHTML) + 1;
                }
            } else {
                console.log('Failed to dislike comment');
            }
        }).catch(error => {
            console.log('Failed to dislike comment');
        })
    }

    function dislikeReply(ParentCommentID, commentID) {
        console.log('Disliking reply');
        fetch(`/update/streaming/video/replies/dislike/${video_id}/${ParentCommentID}/${commentID}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
        }).then(response => {
            if (response.ok) {
                console.log('Disliked reply');
                var comment = document.getElementById(`Reply-${ParentCommentID}-${commentID}`);
                var likesAmount = comment.getElementsByClassName('LikeAmount')[0].innerHTML;
                var dislikesAmount = comment.getElementsByClassName('DislikeAmount')[0].innerHTML;
                var likeButton = comment.getElementsByClassName('LikeButton')[0];
                var dislikeButton = comment.getElementsByClassName('DislikeButton')[0];
                if (dislikeButton.id === 'Dislike-1') {
                    comment.getElementsByClassName('DislikeAmount')[0].innerHTML = parseInt(dislikesAmount) - 1;
                    likeButton.id = 'Like0';
                    dislikeButton.id = 'Dislike0';
                    return;
                } else if (dislikeButton.id === 'Dislike1') {
                    comment.getElementsByClassName('LikeAmount')[0].innerHTML = parseInt(likesAmount) - 1;
                    likeButton.id = 'Like0';
                }
                comment.getElementsByClassName('DislikeAmount')[0].innerHTML = parseInt(dislikesAmount) + 1;
                dislikeButton.id = 'Dislike-1';
                likeButton.id = 'Like-1';
                console.log('Disliked reply');
            } else {
                console.log('Failed to dislike reply');
            }
        }).catch(error => {
            console.log('Failed to dislike reply');
        })
    }
        
    window.onscroll = function() {
        var {scrollTop, clientHeight, scrollHeight} = document.documentElement;

        // console.log(scrollTop, clientHeight, scrollHeight);
        if (scrollTop + clientHeight + 50 >= scrollHeight && !noMoreComments) {
            loadNextComments(video_id);
        }
    };

    document.addEventListener('input', function(event) {
        if (event.target && event.target.matches('.ReplyTextfield')) {
            event.target.style.height = "auto";
            event.target.style.height = event.target.scrollHeight + "px";  
            console.log(event);
            var textBeforeCursor, userMatching;
            [textBeforeCursor, userMatching] = checkWhereAt(event.target);
            console.log("TEXTBFCS", textBeforeCursor);
            console.log("USMATCH", userMatching);
            
            
            console.log("MATCHING USER", userMatching);
            if (userMatching) {
                requestMatchingUsers(userMatching, event.target).then(data => {
                    console.log(data);
                    if (data) {
                        displayMatchingUsers(data, event.target, textBeforeCursor, userMatching);
                    }
                });
            } else {
                var UserSuggestions = event.target.parentNode.getElementsByClassName('UserSuggestions')[0];
                UserSuggestions.innerHTML = '';
                UserSuggestions.style.display = 'none';
            }
        }
    });



    function checkWhereAt(target) {
        const selection = document.getSelection();
        let cursorPosition = 0;
        let textBeforeCursor = "";

        if (!selection.rangeCount) return [textBeforeCursor, null];

        const range = selection.getRangeAt(0);
        const preCaretRange = range.cloneRange();
        preCaretRange.selectNodeContents(target);
        preCaretRange.setEnd(range.endContainer, range.endOffset);

        textBeforeCursor = preCaretRange.toString().trim();

        const mentionMatch = textBeforeCursor.match(/@(\w*)$/);
        const userPart = mentionMatch ? mentionMatch[1] : null;

        console.log("Text before cursor:", textBeforeCursor);
        return [textBeforeCursor, userPart];
    }

    function requestMatchingUsers(userPart, target) {
        console.log(userPart);
        return fetch(`/get/users/` + userPart, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json',
            },
        }).then(response => {
            if (response.ok) {
                return response.json().then(data => {
                    console.log(data);
                    return data;
                })
            } else {
                var UserSuggestions = target.parentNode.getElementsByClassName('UserSuggestions')[0];
                UserSuggestions.innerHTML = '';
                UserSuggestions.style.display = 'none';
                console.log('Failed to get matching users');
                return null;
            }
        }).catch(error => {
            var UserSuggestions = target.parentNode.getElementsByClassName('UserSuggestions')[0];
            console.log(UserSuggestions);
            UserSuggestions.innerHTML = '';
            UserSuggestions.style.display = 'none';    
            console.log('Failed to get matching users');
            return null;
        })
    }

    function displayMatchingUsers(data, target, textBeforeCursor, userMatching) {
        console.log(data);
        console.log(target.parentNode);
        var UserSuggestions = target.parentNode.getElementsByClassName('UserSuggestions')[0];
        console.log(UserSuggestions);
        UserSuggestions.innerHTML = '';
        UserSuggestions.style.display = 'block';
        data.forEach(user => {
            var userElement = document.createElement('div');
            userElement.className = 'UserMatch';
            userElement.innerHTML = `
                <div class="UserIcon">
                    <img src="/streaming/image/channel_icon/${user.uuid}" alt="User Icon">
                </div>
                <div class="Names">
                    <div class="Displayname">
                        ${decodeURI(user.displayname)}
                    </div>
                    <div class="Username">
                        @${decodeURI(user.username)}
                    </div>
                </div>
            `;
            userElement.onclick = function() {
                var currentText = target.innerText;
                console.log("CURRENT TEXT:", currentText);
                console.log("USERMATCH", userMatching);
                console.log("TEXT BEFORE CURSOR", textBeforeCursor);
                console.log("CURRENT TEXT", currentText);

                var regex = new RegExp("@" + userMatching + "$");
                var newTextBeforeCursor = textBeforeCursor.replace(regex, `<span class="user-mention" data-uuid="${user.uuid}">@${decodeURI(user.displayname)}</span> `);
                var newText = newTextBeforeCursor + currentText.substring(textBeforeCursor.length);
                target.innerHTML = newText;
                UserSuggestions.innerHTML = '';
            };
            UserSuggestions.appendChild(userElement);
        });
    }


    </script>
SCRIPT

    $html .= $script;

    my $html_content = html_structure::get_html($html, "Streaming");

    return $html_content;
}

1;