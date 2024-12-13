package about_html;

use strict;
use warnings;

sub get_about {
    my $translations = language_utils::load_language("about");

    my $html_body = <<HTML;
    <div class="about">
        <h1>$translations->{aboutMyWebserver}</h1>

        <div class="overview">
            <h2>$translations->{features}</h2>
            <p>$translations->{featuresText}</p>
            <div class="features">
                <ul>
                    <li>$translations->{featuresHttpWs}</li>
                    <li>$translations->{featuresEpoll}</li>
                    <li>$translations->{featuresUserSystem}</li>
                    <li>$translations->{featuresAuthentication}</li>
                    <li>$translations->{featuresAdminUtils}</li>
                    <li>$translations->{featuresCloud}</li>
                    <li>$translations->{featuresSeverStorageViewer}</li>
                    <li>$translations->{featuresEmailServer}</li>
                    <li>$translations->{featuresEmailNotification}</li>
                    <li>$translations->{featuresForumBlog}</li>
                    <li>$translations->{featuresGameroom}</li>
                    <li>$translations->{featuresCalender}</li>
                    <li>$translations->{featuresLanguageSupport}</li>
                    <li>$translations->{featuresDarkLightMode}</li>
                    <li>$translations->{featuresDynamicUserDisplay}</li>
                    <li>$translations->{featuresBreadCrumbs}</li>
                    <li>$translations->{featuresWCAG}</li>
                <ul>
            </div>
        </div>

        <div class="overview">
            <h2>$translations->{toDo}</h2>
            <p>$translations->{toDoText}</p>
            <div class="to-do">
                <ul>
                    <li>$translations->{todoMUA}</li>
                    <li>$translations->{todoEmailImprovement}</li>
                    <li>$translations->{todoRegisterImproveWithMail}</li>
                    <li>$translations->{todoSupportPage}</li>
                    <li>$translations->{todoStreaming}</li>
                    <li>$translations->{todoFastSerialisation}</li>
                    <li>$translations->{todoSpectatorMode}</li>
                    <li>$translations->{todoUserProfile}</li>
                    <li>$translations->{todoUUID}</li>
                    <li>$translations->{todoMatchHistory}</li>
                    <li>$translations->{todoReplayMode}</li>
                    <li>$translations->{todoLiveChat}</li>
                    <li>$translations->{todoFriendSystem}<li>
                    <li>$translations->{todoLeaderboard}<li>
                    <li>$translations->{todoAchievements}<li>
                    <li>$translations->{todoLevelSystem}<li>
                    <li>$translations->{todoCurrencySystem}<li>
                    <li>$translations->{todoImproveRanks}</li>
                    <li>$translations->{todoCustomDomainDMARC}</li>
                    <li>$translations->{todoGames}</li>
                    <li>$translations->{todoImproveGuiWCAG}</li>
                    <li>$translations->{todoImproveGui}</li>
                    <li>$translations->{todoImpressum}</li>
                    <li>$translations->{todoPrivacyPolicy}</li>
                    <li>$translations->{todoTermsOfService}</li>
                    <li>$translations->{todoBreadCrumbsImprovement}</li>
                    <li>$translations->{todoAPI}</li>
                    <li>$translations->{todoToDoApp}</li>
                    <li>$translations->{todoCookiesImprove}</li>
                    <li>$translations->{todoMObileAuthLogin}</li>
                <ul>
            </div>
        </div>

        <div class="overview">
            <h2>$translations->{knownErrors}</h2>
            <p>$translations->{knownErrorsText}</p>
            <div class="known-errors">
                <ul>
                    <li>$translations->{knwonErrorCalenderBreadcrumbs}</li>
                    <li>$translations->{knwonErrorEmail}</li>
                    <li>$translations->{knwonErrorMemoryWS}</li>
                    <li>$translations->{knwonErrorLightModeLanguageChange}</li>
                <ul>
            </div>
        </div>

        <div class="overview">
            <h2>$translations->{additionalNotes}</h2>
            <p>$translations->{additionalNotesText}</p>
            <div class="additional-notes">
                <ul>
                    <li>$translations->{additionalNotesVantaBG}</li>
                    <li>$translations->{additionalNotesFont}</li>
                <ul>
            </div>
        </div>
    </div>
HTML

    $html_body .= html_utils::create_breadcrumbs("About");

    my $html_content = html_structure::get_html($html_body, "About");

    return ($html_content);
}

1;