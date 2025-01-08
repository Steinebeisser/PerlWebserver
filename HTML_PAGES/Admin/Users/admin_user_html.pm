package admin_user_html;

use strict;
use warnings;


sub get_user_list {
    my ($current_page, $user_per_page) = @_;
    if ($main::user) {
        my $role = user_utils::get_role();
        if ($role ne "admin") {
            return 0;
        }
    } else {
        return 0;
    }
    if (!$current_page) {
        $current_page = 1;
    }
    if (!$user_per_page) {
        $user_per_page = 3;
    }
    my $html_body = <<HTML;
    <h1>Users</h1>
    <div style="text-align: center;\">
        <input type="text\" id="search\" name="search\" placeholder="Search for users\">
        <button type="submit\">Search</button>
        <br>
    </div>
    <br>
    <div style="text-align: center;">
        <form action="/admin/users" method="post\">
HTML

    if ($user_per_page == 3) {
        $html_body .= "<input type=\"text\" id=\"userperpage\" name=\"userperpage\" placeholder=\"User per page, default: 3\">";    
    } else {
        $html_body .= "<input type=\"text\" id=\"userperpage\" name=\"userperpage\" placeholder=\"User per page, default: 3\" value=\"$user_per_page\">";
    }
    $html_body .= <<HTML;

            <input type="submit" value="Submit">
        </form>
    </div>
    <br>
    <br>
    <table>
        <tr>
            <th>Username</th>
            <th>Role</th>
            <th>Action</th>
        </tr>
HTML

my $start_index = ($current_page - 1) * $user_per_page;
if ($start_index > 2147483647) {
    $start_index = 1;
}
if ($start_index < 0) {
    $start_index = 0;
}

if ($user_per_page > 2147483647) {
    $user_per_page = 2147483647;
}
if ($current_page > 2147483647) {
    $current_page = 2147483647;
}
if ($current_page < 1) {
    $current_page = 1;
}
if ($user_per_page < 1) {
    $user_per_page = 1;
}

my $end_index = $start_index + $user_per_page - 1;
if ($end_index > 2147483647) {
    $end_index = 3;
}
if ($end_index < 0) {
    $end_index = 0;
}
if ($end_index + $start_index > 2147483647) {
    $end_index = 3;
    $start_index = 0;
}

my ($users_ref, $total_user_amount) = user_utils::get_all_users($start_index, $user_per_page);
# print("TOTAL USER AMOUNT: $total_user_amount\n");
my $current_user_amount = 0;


foreach my $user (@$users_ref) {
    # print("USer: $user\n");

    my $human_username = $user->{username};
    if (user_utils::is_encoded($user->{username})) {
        $human_username = user_utils::decode_uri($user->{username});
    }


    $html_body .= <<HTML;
        <tr>
            <td>$human_username</td>
            <td>$user->{role}</td>
            <td style="text-align: end;">
                <span class="inline_link">
                    <a href="/admin/users/view/$user->{username}">View</a>
                    <a href="/admin/users/edit/$user->{username}">Edit</a> 
                    <a href="/admin/users/ban/$user->{username}">Ban</a>
                    <a href="/admin/users/delete/$user->{username}">Delete</a>
                </span>
            </td>
        </tr>
HTML


    $current_user_amount++;
}
$html_body .= <<HTML;

    </table>
    <br>
    <span class="inline_buttons_blue">
HTML

if ($current_page > 1) {
    my $previus_page = $current_page - 1;
    $html_body .=<<HTML;
        <a href="/admin/users/?page=$previus_page&userperpage=$user_per_page\">Previous</a>
HTML
}
if (($total_user_amount - ($current_page * $user_per_page)) >= 1) {
    # print("Total user amount: $total_user_amount\n");
    # print("Current page: $current_page\n");
    # print("User per page: $user_per_page\n");
    # print("MATHEMATIC: " . ($total_user_amount - ($current_page * $user_per_page)));
    my $next_page = $current_page + 1;
    $html_body .=<<HTML;
        <a href="/admin/users/?page=$next_page&userperpage=$user_per_page\">Next</a>
HTML
    
}
$html_body .=<<HTML;
    </span>
HTML

    $html_body .= admin_utils::return_buttons();
    
    my $html_content = html_structure::get_html($html_body, "Users");
    return ($html_content);
}

1;