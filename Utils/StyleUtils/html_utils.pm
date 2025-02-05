package html_utils;

use strict;
use warnings;
use JSON;
use Cwd;

sub get_footer {

    my $langauge_button = language_utils::change_language_button();
    my $dark_mode_button = dark_mode_button();
    my $html_footer = <<HTML;
    <footer class="footer">
        $langauge_button
        <p>© 2024 - Perl Webserver</p>
        $dark_mode_button
    </footer>
HTML
    return $html_footer;
}

sub dark_mode_button {
    my $translations = language_utils::load_language("footer");

    my $mode = "$translations->{darkMode}";

    if ($main::scheme eq "dark") {
        $mode = "$translations->{lightMode}";
    }


    my $dark_mode_button = <<HTML;
    <form action="/dark_mode" method="post" class="dark-mode-form">
        <button type="submit">$mode</button>
    </form>
HTML
    return $dark_mode_button;
}

sub get_ploud_items {
    my $translations = language_utils::load_language("ploud");
    
    my $ploud_items = <<HTML;
    <div class="ploud">
        <p>Ploud</p>
        <table>
            <tr>
                <th>$translations->{uploaded_at}</th>
                <th>$translations->{size}</th>
                <th>$translations->{filename}</th>
                <th>$translations->{actions}</th>
            </tr>
HTML
    if (!$main::user) {
        return 0;
    }
    my @uploads = user_utils::get_uploads();
    if (!@uploads) {
        $ploud_items .= <<HTML;
        <p>$translations->{noUploads}</p>
HTML
    }
    foreach my $upload_file (@uploads) {
        my $metadata = user_utils::get_metadata($upload_file);
        my $human_file_name = user_utils::decode_uri($upload_file);
        my $parsed_date;
        my $size;
        if (!$metadata) {
            $parsed_date = "Unknown";
        } else {   
            my $uploaded_at = $metadata->{uploaded_at};
            $parsed_date = calender_utils::parse_date($uploaded_at);
        }
        if (!$metadata) {
            $size = "Unknown";
        } else {
            $size = $metadata->{size};
            if (!$size) {
                $size = "Unknown";
            }
            $size = user_utils::format_bytes($size);
        }
        
        $ploud_items .= <<HTML;
            <tr>
                <td>$parsed_date</td>
                <td>$size</td>
                <td>$human_file_name</td>
                <td>
                    <a href="/profile/ploud/download/$upload_file">$translations->{download}</a>
                    <a href="/profile/ploud/delete/$upload_file">$translations->{delete}</a>
                </td>
            </tr>
HTML
    }
    $ploud_items .= <<HTML;
        </table>
    </div>
HTML
    return $ploud_items;
}

sub get_no_input_layer {
    my $html = <<HTML;
    <div class="no-input-layer" id="no-input-layer"></div>
}
HTML
    return $html;
}

sub show_ranks {
    my $rank_file = "Utils/ranks.json";

    my $user_data = user_utils::get_json_data($main::user->{uuid});
    if (!$user_data) {
        return 0;
    }
    my $rank = $user_data->{rank}{name};
    my $owned_rank_id = $user_data->{rank}{id};

    open my $fh, "<", $rank_file or die "Could not open file $rank_file: $!";
    my $json = do { local $/; <$fh> };
    close $fh;

    my $ranks = decode_json($json);
    # print("RANKS: $ranks\n");

    my $html = <<HTML;
    <div class="ranks">
        <h1>Ranks</h1>
        <table>
            <tr>
                <th>Name</th>
                <th>Storage</th>
                <th>Price</th>
                <th>Buy</th>
            </tr>
HTML

    foreach my $rank_id (sort keys %$ranks) {
        # print("RANK ID: $rank_id\n");
        my $rank = $ranks->{$rank_id};
        my $formatted_storage = user_utils::format_bytes($rank->{benefits}->{max_storage});
        $html .= <<HTML;
            <tr>
                <td>$rank->{name}</td>
                <td>$formatted_storage</td>
HTML
        if ($rank_id <= $owned_rank_id) {
            $html .= <<HTML;
                <td>Owned</td>
                <td>Owned</td>
            </tr>
HTML
        } else {
            $html .= <<HTML;
                <td>$rank->{price}</td>
                <td>
                    <a href="/profile/ploud/upgrade/$rank->{name}">Buy </a>
                </td>
            </tr>
HTML
        }
    }
    $html .= <<HTML;
        </table>
    </div>
HTML
    return $html;
}

sub create_breadcrumbs {
    my ($path) = @_;

    my @path = split(",", $path);

    my $html = <<HTML;
    <div class="breadcrumbs">
        <a href="/">Home</a>
        <span>/</span>
HTML
    my $current_path = "";
    foreach my $part (@path) {
        my $print_part = $part;
        $part =~ s/\s+//g;
        if ($part =~ /\/(.*)/) {
            # print("Invalid path: $part\n");
            $print_part = $1;
        }
        $current_path .= "/$part";
        $html .= <<HTML;
        <a href="$current_path">$print_part</a>
        <span>/</span>
HTML
    }
    $html .= <<HTML;
    </div>
HTML
    return $html;
}

sub get_blog_top_bar_account {
    my ($translations) = @_;
    my $html = <<HTML;
    <div class="blog_top_bar_account">
HTML
    if ($main::user) {
        $html .= <<HTML;
        <a href="/profile">$translations->{profile}</a>
        <a href="/blog/notifications">$translations->{notifications}</a>
HTML
    } else {
        $html .= <<HTML;
        <a href="/login">$translations->{login}</a>
        <a href="/register">$translations->{register}</a>
HTML
    }
    $html .= <<HTML;
    </div>
HTML
    return $html;
}

sub get_blog_logo {
    my $html = <<HTML;
    <div class="blog_logo">
        <a href="/blog">
            Blog
        </a>
    </div>
HTML
    return $html;
}

sub get_game_online_status {
    my ($translations) = @_;
    my $html = <<HTML;
    <div class="online_status">
        <h2>$translations->{onlineStatus}</h2>
HTML
    if ($main::user->{username}) {
        $html .= <<HTML;
        <p>$translations->{isOnline}</p>
HTML
    } else {
        $html .= <<HTML;
        <p>$translations->{isOffline}</p>
HTML
    }
    $html .= <<HTML;
    </div>
HTML
    return $html;
}

sub get_memory_restart_button {
    my ($translations) = @_;
    my $html = <<HTML;
    <div class="memory_restart_button">
        <a href="restart">$translations->{restart}</a>
    </div>
HTML
    return $html;
}

sub get_wait_connection_layer {
    my ($translations) = @_;

    my $html = <<HTML;
    <div class="wait_connection_layer" id="wait_connection_layer">
        <div class="wait_connection">
            <p>$translations->{waitingForConnection}</p>
        </div>
    </div>
HTML
    return $html;
}

sub get_ping_display {
    my ($translations) = @_;

    my $html = <<HTML;
    <div class="ping_display">
        <p>$translations->{ping}: 
            <span id="ping">0</span>ms
        </p>
    </div>
HTML
    return $html;
}
1;