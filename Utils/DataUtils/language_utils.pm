package language_utils;

use strict;
use warnings;
use Cwd;

use utf8;

use JSON;

sub load_language {
    my ($route) = @_;
    my @routes = split /,/, $route;
    my %combined_language_data;

    my $base_path = getcwd();

    my $language_path = "$base_path/Data/Languages/";

    my ($language) = get_language($language_path);

    if (!$language) {
        $language = "en";
    }

    foreach my $single_route (@routes) {
        $single_route =~ s/\s+//g;
        my $file_path = "$language_path/$language/$single_route.json";
        # print("LOADING $file_path\n");
        my $language_data = read_json_file($file_path);
        %combined_language_data = (%combined_language_data, %$language_data) if $language_data;
    }

    filter_language_data(\%combined_language_data);

    return \%combined_language_data;

    # my $language;
    # print("ROUTE: $route\n");
    

    my $file_path = "$language_path/$language/$route.json";
    # my $language_data_file = "$language_path/$language/change_language.json";

    my $language_data = read_json_file($file_path);
    # my $change_language_data = read_json_file($language_data_file);

    # %$language_data = (%$change_language_data, %$language_data);
    return $language_data;
}


sub filter_language_data {
    my ($language_data) = @_;

    my %german_special_chars = (
        "ä" => "&auml;",
        "ö" => "&ouml;",
        "ü" => "&uuml;",
        "ß" => "&szlig;",
        "Ä" => "&Auml;",
        "Ö" => "&Ouml;",
        "Ü" => "&Uuml;",
    );

    foreach my $key (keys %$language_data) {
        my $value = $language_data->{$key};

        foreach my $special_char (keys %german_special_chars) {
            $value =~ s/\Q$special_char\E/$german_special_chars{$special_char}/g;
        }

        $language_data->{$key} = $value;
    }
}

sub get_user_language {
    my $base_path = getcwd();
    my $language_path = "$base_path/Data/Languages/";
    
    my ($language) = get_language($language_path);

    if (!$language) {
        $language = "en";
    }

    return $language;
}

sub read_json_file {
    my ($file_path) = @_;
    open my $fh, '<', $file_path or do {
        # print("Could not open '$file_path' $!\n");
        return undef;
    };
    local $/ = undef;
    my $json_text = <$fh>;
    close $fh;
    return decode_json($json_text);
}


sub change_language_button {
    my $base_path = getcwd();
    my $language_path = "$base_path/Data/Languages/";

    my ($language) = get_language($language_path);

    my $language_data_file = "$language_path/$language/footer.json";

    my $translations = read_json_file($language_data_file);

    my $html = <<HTML;
    
    <form action="/change_language" method="post" class="language-form">
        <label for="language">$translations->{languageSelection}:</label>
        <select name="language" id="language">
            <option value="en">$translations->{english} </option>
            <option value="de">$translations->{german} </option>
        </select>
        <button type="submit">$translations->{changeLanguageButton}</button>
    </form>
HTML
    return $html;
}

sub get_language {
    my ($language_path) = @_;

    my $language_data;

    my $uuid = user_utils::get_uuid();
    if ($uuid) {
        my $preferences = user_utils::get_user_stat($uuid, "preferences");
        if ($preferences) {
            # print("PREFERENCES: $preferences\n");
            
            $language_data = $preferences->{language};
    }
    } 
    if (!$language_data) {
        if ($main::accept_language) {
            $language_data = $main::accept_language;
        } else {
            $language_data = "en";
            return $language_data;
        }
    }
    




    # print("LANGUAGE: $language_data\n");
    my @languages = split /,/, $language_data;
    foreach my $lang (@languages) {
        $lang =~ s/;.*//;
    }
    my $pref_lang = $languages[0];
    my $second_pref_lang = $languages[1];
    my $third_pref_lang = $languages[2];

    if (-f "$language_path/$pref_lang/index.json") {
        return $pref_lang;
    } elsif (-f "$language_path/$second_pref_lang/index.json") {
        return $second_pref_lang;
    } elsif (-f "$language_path/$third_pref_lang/index.json") {
        return $third_pref_lang;
    } else {
        return 0;
    }
}

sub set_language {
    my ($request) = @_;
    if (!$request) {
        return;
    }
    if ($main::user) {
        my $username = $main::user->{username};
        my $preferences = user_utils::get_user_stat($username, "preferences");
        if ($preferences) {
            my $language = $preferences->{language};
            if ($language) {
                $main::accept_language = $language;
            }
        } else {
            $main::accept_language = request_utils::get_accept_language_by_cookie($main::header);
        }
    }
    else {
        $main::accept_language = request_utils::get_accept_language_by_cookie($main::header);
        if (!$main::accept_language) {
            my ($accept_language) = $main::header =~ /Accept-Language: (.*)/;
            if ($accept_language) {
                $main::accept_language = $accept_language;
            }
        }
    }

}
1;