package get_profile_ploud_upgrade_rank;

use strict;
use warnings;

sub get_profile_ploud_upgrade_rank {
    my ($rank_to_purchase, $username) = @_;


    my $translations = language_utils::load_language("profile, ploud");

    # print("UPGRADEEEEEEEEE\n");

    my $html_body = <<HTML;
    <h1>$translations->{ploud}</h1>
    <br>
    <p>$translations->{username}: $main::user->{human_username}</p>
HTML

    $html_body .= html_utils::create_breadcrumbs("profile, ploud, upgrade, $rank_to_purchase");

    my $userdata = user_utils::get_json_data($main::user->{uuid});
    my $rank_id = $userdata->{rank}{id};
    # print("RANK ID: $rank_id\n");
    my $rank_to_purchase_id = user_utils::get_rank_id($rank_to_purchase);
    # print("RANK TO PURCHASE ID: $rank_to_purchase_id\n");

    if ($rank_id >= $rank_to_purchase_id) {
        $html_body .= <<HTML;
        <p>$translations->{alreadyRank}</p>
        <a href="/profile/ploud/upgrade">$translations->{back}</a>
        <br>
HTML
        my $html_content = html_structure::get_html($html_body, "Profile");

        return ($html_content);
    }

    $html_body .= <<HTML;
    <br>
    <div class="upgrade_rank_button">
        <form action="/profile/ploud/upgrade/$rank_to_purchase" method="post">
            <input type="submit" value="$translations->{buy}">
        </form>
    </div>
    <a href="/profile/ploud/upgrade">$translations->{back}</a>
    <br>
HTML
    
    my $html_content = html_structure::get_html($html_body, "Profile");

    return ($html_content);

}

1;