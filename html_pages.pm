package html_pages;

use strict;
use warnings;

use HTML_PAGES::index_html;

use HTML_PAGES::Login::login_html;
use HTML_PAGES::Login::logined_html;

use HTML_PAGES::Register::register_html;
use HTML_PAGES::Register::registered_html;

use HTML_PAGES::Logout::logout_html;

use HTML_PAGES::Profile::profile_html;
use HTML_PAGES::Profile::get_profile_ploud;
use HTML_PAGES::Profile::get_profile_ploud_upload;
use HTML_PAGES::Profile::get_profile_ploud_upgrade;
use HTML_PAGES::Profile::get_profile_ploud_upgrade_rank;

use HTML_PAGES::Blog::get_blog;
use HTML_PAGES::Blog::get_blog_view;
use HTML_PAGES::Blog::get_blog_create;

use HTML_PAGES::Calender::get_calender_year;
use HTML_PAGES::Calender::get_calender_month;

use HTML_PAGES::Gameroom::get_gameroom;
use HTML_PAGES::Gameroom::Memory::get_memory;
use HTML_PAGES::Gameroom::Memory::get_memory_alone;
use HTML_PAGES::Gameroom::Memory::get_memory_2player;
use HTML_PAGES::Gameroom::Memory::get_memory_2player_waiting;

use HTML_PAGES::Admin::admin_html;
use HTML_PAGES::Admin::Users::admin_user_html;
use HTML_PAGES::Admin::Users::get_admin_edit_user;
use HTML_PAGES::Admin::Users::get_admin_ban_user;
use HTML_PAGES::Admin::Users::get_admin_view_user;
use HTML_PAGES::Admin::Users::get_admin_delete_user;

use HTML_PAGES::Admin::Announcements::get_blog_announcements_manage;
use HTML_PAGES::Admin::Announcements::get_announcement_edit;
use HTML_PAGES::Admin::Announcements::get_announcement_create;


use HTML_PAGES::shutdown_html;

use HTML_PAGES::html_structure;

# use User::Utils::utils;

use lib 'Webserver';
use Utils::DataUtils::calender_utils;
use Utils::DataUtils::language_utils;
use Utils::DataUtils::memory_utils;
use Utils::DataUtils::websocket_utils;
use Utils::DataUtils::blog_utils;
use Utils::DataUtils::connection_utils;
use Utils::DataUtils::request_utils;
use Utils::DataUtils::user_utils;
use Utils::DataUtils::admin_utils;
use Utils::DataUtils::http_utils;

use Utils::DataUtils::User::register_user;
use Utils::DataUtils::User::login_user;
use Utils::DataUtils::User::logout_user;

use Utils::StyleUtils::html_utils;
use Utils::StyleUtils::css_utils;
use Utils::StyleUtils::scheme_utils;

use Utils::HtmlPagesUtils::Blog::get_blog_pages;
use Utils::HtmlPagesUtils::Blog::post_blog_pages;

use Utils::HtmlPagesUtils::Gameroom::get_gameroom_page;
use Utils::HtmlPagesUtils::Gameroom::Memory::get_memory_pages;

use Utils::LoadStuffUtils::load_fonts;
use Utils::LoadStuffUtils::load_js;

use Utils::HtmlPagesUtils::Profile::get_profile_pages;
use Utils::HtmlPagesUtils::Profile::post_profile_pages;

use Utils::HtmlPagesUtils::Preferences::post_preferences;

use Utils::HtmlPagesUtils::Admin::get_admin_page;
use Utils::HtmlPagesUtils::Admin::Users::post_admin_users_pages;
use Utils::HtmlPagesUtils::Admin::Users::get_admin_users_pages;

use Utils::HtmlPagesUtils::Calender::get_calender_pages;

use Utils::HtmlPagesUtils::User::get_operation_finished_pages;

use Utils::HtmlPagesUtils::Index::get_index_page;

use Utils::HtmlPagesUtils::Register::get_register_page;
use Utils::HtmlPagesUtils::Login::get_login_page;

use Utils::HtmlPagesUtils::Shutdown::get_shutdown_page;

use Utils::HtmlPagesUtils::Favicon::get_favicon;
1;