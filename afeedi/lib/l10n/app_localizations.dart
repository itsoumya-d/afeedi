import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_id.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('id'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('ru'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Afeedi'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'All your favorite videos. One premium experience.'**
  String get tagline;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @continueBtn.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueBtn;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get alreadyHaveAccount;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get terms;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @videos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get videos;

  /// No description provided for @discover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discover;

  /// No description provided for @shorts.
  ///
  /// In en, this message translates to:
  /// **'Shorts'**
  String get shorts;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @trending.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get trending;

  /// No description provided for @forYou.
  ///
  /// In en, this message translates to:
  /// **'For You'**
  String get forYou;

  /// No description provided for @following.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get following;

  /// No description provided for @bookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarks;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @liked.
  ///
  /// In en, this message translates to:
  /// **'Liked'**
  String get liked;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @watchHistory.
  ///
  /// In en, this message translates to:
  /// **'Watch History'**
  String get watchHistory;

  /// No description provided for @continueWatching.
  ///
  /// In en, this message translates to:
  /// **'Continue Watching'**
  String get continueWatching;

  /// No description provided for @recommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommended;

  /// No description provided for @popular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popular;

  /// No description provided for @newest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get newest;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategories;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @platform.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get platform;

  /// No description provided for @allPlatforms.
  ///
  /// In en, this message translates to:
  /// **'All Platforms'**
  String get allPlatforms;

  /// No description provided for @timeRange.
  ///
  /// In en, this message translates to:
  /// **'Time Range'**
  String get timeRange;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get allTime;

  /// No description provided for @contentType.
  ///
  /// In en, this message translates to:
  /// **'Content Type'**
  String get contentType;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @short.
  ///
  /// In en, this message translates to:
  /// **'Short'**
  String get short;

  /// No description provided for @reel.
  ///
  /// In en, this message translates to:
  /// **'Reel'**
  String get reel;

  /// No description provided for @views.
  ///
  /// In en, this message translates to:
  /// **'views'**
  String get views;

  /// No description provided for @likes.
  ///
  /// In en, this message translates to:
  /// **'likes'**
  String get likes;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @like.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get like;

  /// No description provided for @follow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get follow;

  /// No description provided for @unfollow.
  ///
  /// In en, this message translates to:
  /// **'Unfollow'**
  String get unfollow;

  /// No description provided for @subscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get subscribe;

  /// No description provided for @creator.
  ///
  /// In en, this message translates to:
  /// **'Creator'**
  String get creator;

  /// No description provided for @creatorProfile.
  ///
  /// In en, this message translates to:
  /// **'Creator Profile'**
  String get creatorProfile;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @noResultsFor.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String noResultsFor(String query);

  /// No description provided for @noContent.
  ///
  /// In en, this message translates to:
  /// **'No content available'**
  String get noContent;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @pullToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Pull to refresh'**
  String get pullToRefresh;

  /// No description provided for @errorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading content'**
  String get errorLoading;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetConnection;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @allNotifications.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allNotifications;

  /// No description provided for @unread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get unread;

  /// No description provided for @achievement.
  ///
  /// In en, this message translates to:
  /// **'Achievement'**
  String get achievement;

  /// No description provided for @videosWatched.
  ///
  /// In en, this message translates to:
  /// **'Videos Watched'**
  String get videosWatched;

  /// No description provided for @watchTime.
  ///
  /// In en, this message translates to:
  /// **'Watch Time'**
  String get watchTime;

  /// No description provided for @streak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streak;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get hours;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @notifications_setting.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications_setting;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @emailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get emailNotifications;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @upgradeToPremium.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get upgradeToPremium;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'month'**
  String get month;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'year'**
  String get year;

  /// No description provided for @subscribe_action.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get subscribe_action;

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current Plan'**
  String get currentPlan;

  /// No description provided for @addToCalendar.
  ///
  /// In en, this message translates to:
  /// **'Add to Calendar'**
  String get addToCalendar;

  /// No description provided for @scheduledContent.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Content'**
  String get scheduledContent;

  /// No description provided for @noContentScheduled.
  ///
  /// In en, this message translates to:
  /// **'No content scheduled for this day'**
  String get noContentScheduled;

  /// No description provided for @contentForDate.
  ///
  /// In en, this message translates to:
  /// **'Content for {date}'**
  String contentForDate(String date);

  /// No description provided for @interests.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get interests;

  /// No description provided for @selectInterests.
  ///
  /// In en, this message translates to:
  /// **'Select your interests'**
  String get selectInterests;

  /// No description provided for @selectAtLeast3.
  ///
  /// In en, this message translates to:
  /// **'Please select at least 3'**
  String get selectAtLeast3;

  /// No description provided for @personalizingFeed.
  ///
  /// In en, this message translates to:
  /// **'Personalizing your feed...'**
  String get personalizingFeed;

  /// No description provided for @feedReady.
  ///
  /// In en, this message translates to:
  /// **'Your feed is ready!'**
  String get feedReady;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get welcomeBack;

  /// No description provided for @hi.
  ///
  /// In en, this message translates to:
  /// **'Hi'**
  String get hi;

  /// No description provided for @letsGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Let\'s get started'**
  String get letsGetStarted;

  /// No description provided for @onboardingWelcome.
  ///
  /// In en, this message translates to:
  /// **'Hi! I\'m your Afeedi assistant. I\'ll help set up your perfect content feed. What\'s your name?'**
  String get onboardingWelcome;

  /// No description provided for @onboardingComplete.
  ///
  /// In en, this message translates to:
  /// **'Your personalized feed is ready! Tap below to start exploring.'**
  String get onboardingComplete;

  /// No description provided for @gaming.
  ///
  /// In en, this message translates to:
  /// **'Gaming'**
  String get gaming;

  /// No description provided for @music.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get music;

  /// No description provided for @technology.
  ///
  /// In en, this message translates to:
  /// **'Technology'**
  String get technology;

  /// No description provided for @food.
  ///
  /// In en, this message translates to:
  /// **'Food & Cooking'**
  String get food;

  /// No description provided for @fitness.
  ///
  /// In en, this message translates to:
  /// **'Fitness'**
  String get fitness;

  /// No description provided for @travel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get travel;

  /// No description provided for @art.
  ///
  /// In en, this message translates to:
  /// **'Art & Design'**
  String get art;

  /// No description provided for @nature.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get nature;

  /// No description provided for @comedy.
  ///
  /// In en, this message translates to:
  /// **'Comedy'**
  String get comedy;

  /// No description provided for @fashion.
  ///
  /// In en, this message translates to:
  /// **'Fashion'**
  String get fashion;

  /// No description provided for @education.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get education;

  /// No description provided for @sports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get sports;

  /// No description provided for @news.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get news;

  /// No description provided for @science.
  ///
  /// In en, this message translates to:
  /// **'Science'**
  String get science;

  /// No description provided for @youtube.
  ///
  /// In en, this message translates to:
  /// **'YouTube'**
  String get youtube;

  /// No description provided for @tiktok.
  ///
  /// In en, this message translates to:
  /// **'TikTok'**
  String get tiktok;

  /// No description provided for @instagram.
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get instagram;

  /// No description provided for @facebook.
  ///
  /// In en, this message translates to:
  /// **'Facebook'**
  String get facebook;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get signingIn;

  /// No description provided for @authenticationFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed'**
  String get authenticationFailed;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @noContentYet.
  ///
  /// In en, this message translates to:
  /// **'No content yet'**
  String get noContentYet;

  /// No description provided for @startExploring.
  ///
  /// In en, this message translates to:
  /// **'Start exploring to see content here'**
  String get startExploring;

  /// No description provided for @watchedVideos.
  ///
  /// In en, this message translates to:
  /// **'Watched {count} videos'**
  String watchedVideos(int count);

  /// No description provided for @newLabel.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newLabel;

  /// No description provided for @discoverCreators.
  ///
  /// In en, this message translates to:
  /// **'Discover creators to follow'**
  String get discoverCreators;

  /// No description provided for @followCreatorsHint.
  ///
  /// In en, this message translates to:
  /// **'Follow creators to surface their content'**
  String get followCreatorsHint;

  /// No description provided for @findCreators.
  ///
  /// In en, this message translates to:
  /// **'Find creators'**
  String get findCreators;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @resetAll.
  ///
  /// In en, this message translates to:
  /// **'Reset All'**
  String get resetAll;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @seePlans.
  ///
  /// In en, this message translates to:
  /// **'See Plans'**
  String get seePlans;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get showMore;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since {date}'**
  String memberSince(String date);

  /// No description provided for @noLikedContent.
  ///
  /// In en, this message translates to:
  /// **'No liked content'**
  String get noLikedContent;

  /// No description provided for @noLikedContentHint.
  ///
  /// In en, this message translates to:
  /// **'Videos you like will appear here'**
  String get noLikedContentHint;

  /// No description provided for @nothingSavedYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing saved yet'**
  String get nothingSavedYet;

  /// No description provided for @bookmarkContentHint.
  ///
  /// In en, this message translates to:
  /// **'Bookmark content to see it here'**
  String get bookmarkContentHint;

  /// No description provided for @noHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get noHistoryYet;

  /// No description provided for @noHistoryHint.
  ///
  /// In en, this message translates to:
  /// **'Videos you watch will appear here'**
  String get noHistoryHint;

  /// No description provided for @watchedOf.
  ///
  /// In en, this message translates to:
  /// **'Watched {watched} of {total}'**
  String watchedOf(String watched, String total);

  /// No description provided for @removeFromHistory.
  ///
  /// In en, this message translates to:
  /// **'Remove from history'**
  String get removeFromHistory;

  /// No description provided for @engagementScore.
  ///
  /// In en, this message translates to:
  /// **'Engagement Score'**
  String get engagementScore;

  /// No description provided for @ofMaxKeepWatching.
  ///
  /// In en, this message translates to:
  /// **'{pct}% of max — keep watching!'**
  String ofMaxKeepWatching(int pct);

  /// No description provided for @watchedLabel.
  ///
  /// In en, this message translates to:
  /// **'Watched'**
  String get watchedLabel;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// No description provided for @nameCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty'**
  String get nameCannotBeEmpty;

  /// No description provided for @nameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Name too long (max 50 chars)'**
  String get nameTooLong;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @defaultBio.
  ///
  /// In en, this message translates to:
  /// **'Curious mind. Content explorer. Watching the world one feed at a time.'**
  String get defaultBio;

  /// No description provided for @editProfileTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfileTooltip;

  /// No description provided for @googleCalendar.
  ///
  /// In en, this message translates to:
  /// **'Google Calendar'**
  String get googleCalendar;

  /// No description provided for @readOnlyAccess.
  ///
  /// In en, this message translates to:
  /// **'Read-only access'**
  String get readOnlyAccess;

  /// No description provided for @readOnlyAccessHint.
  ///
  /// In en, this message translates to:
  /// **'We only read events, never modify them'**
  String get readOnlyAccessHint;

  /// No description provided for @seeEventsInApp.
  ///
  /// In en, this message translates to:
  /// **'See events in-app'**
  String get seeEventsInApp;

  /// No description provided for @seeEventsInAppHint.
  ///
  /// In en, this message translates to:
  /// **'Your calendar appears alongside your content schedule'**
  String get seeEventsInAppHint;

  /// No description provided for @privateAndLocal.
  ///
  /// In en, this message translates to:
  /// **'Private & local'**
  String get privateAndLocal;

  /// No description provided for @privateAndLocalHint.
  ///
  /// In en, this message translates to:
  /// **'Data stays on-device; we never share it'**
  String get privateAndLocalHint;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connecting;

  /// No description provided for @connectWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Connect with Google'**
  String get connectWithGoogle;

  /// No description provided for @couldNotConnect.
  ///
  /// In en, this message translates to:
  /// **'Could not connect — check permissions and try again.'**
  String get couldNotConnect;

  /// No description provided for @noUpcomingEvents.
  ///
  /// In en, this message translates to:
  /// **'No upcoming events'**
  String get noUpcomingEvents;

  /// No description provided for @allDay.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get allDay;

  /// No description provided for @personalizedContentSchedule.
  ///
  /// In en, this message translates to:
  /// **'Your personalized content schedule'**
  String get personalizedContentSchedule;

  /// No description provided for @contentCategories.
  ///
  /// In en, this message translates to:
  /// **'Content Categories'**
  String get contentCategories;

  /// No description provided for @categoryFilter.
  ///
  /// In en, this message translates to:
  /// **'Category Filter'**
  String get categoryFilter;

  /// No description provided for @percentageFilter.
  ///
  /// In en, this message translates to:
  /// **'Percentage Filter'**
  String get percentageFilter;

  /// No description provided for @educationPct.
  ///
  /// In en, this message translates to:
  /// **'Education: {pct}%'**
  String educationPct(int pct);

  /// No description provided for @entertainmentPct.
  ///
  /// In en, this message translates to:
  /// **'Entertainment: {pct}%'**
  String entertainmentPct(int pct);

  /// No description provided for @searchContent.
  ///
  /// In en, this message translates to:
  /// **'Search content...'**
  String get searchContent;

  /// No description provided for @monthView.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get monthView;

  /// No description provided for @weekView.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get weekView;

  /// No description provided for @dayView.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get dayView;

  /// No description provided for @noFilterContent.
  ///
  /// In en, this message translates to:
  /// **'No {filter} content'**
  String noFilterContent(String filter);

  /// No description provided for @tryDifferentFilter.
  ///
  /// In en, this message translates to:
  /// **'Try selecting a different filter or date'**
  String get tryDifferentFilter;

  /// No description provided for @itemsScheduled.
  ///
  /// In en, this message translates to:
  /// **'{count} items scheduled'**
  String itemsScheduled(int count);

  /// No description provided for @entertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get entertainment;

  /// No description provided for @aiRecommendations.
  ///
  /// In en, this message translates to:
  /// **'AI Recommendations'**
  String get aiRecommendations;

  /// No description provided for @suggestedFor.
  ///
  /// In en, this message translates to:
  /// **'Suggested for {time}'**
  String suggestedFor(String time);

  /// No description provided for @movedNear.
  ///
  /// In en, this message translates to:
  /// **'Moved \"{item}\" near \"{target}\"'**
  String movedNear(String item, String target);

  /// No description provided for @unknownTitle.
  ///
  /// In en, this message translates to:
  /// **'Unknown Title'**
  String get unknownTitle;

  /// No description provided for @unknownCreator.
  ///
  /// In en, this message translates to:
  /// **'Unknown Creator'**
  String get unknownCreator;

  /// No description provided for @playback.
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get playback;

  /// No description provided for @autoplay.
  ///
  /// In en, this message translates to:
  /// **'Autoplay'**
  String get autoplay;

  /// No description provided for @autoplayHint.
  ///
  /// In en, this message translates to:
  /// **'Automatically play next video'**
  String get autoplayHint;

  /// No description provided for @videoQuality.
  ///
  /// In en, this message translates to:
  /// **'Video Quality'**
  String get videoQuality;

  /// No description provided for @dataSaver.
  ///
  /// In en, this message translates to:
  /// **'Data Saver'**
  String get dataSaver;

  /// No description provided for @dataSaverHint.
  ///
  /// In en, this message translates to:
  /// **'Reduce data usage while streaming'**
  String get dataSaverHint;

  /// No description provided for @pushNotificationsHint.
  ///
  /// In en, this message translates to:
  /// **'New content from followed creators'**
  String get pushNotificationsHint;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @darkModeHint.
  ///
  /// In en, this message translates to:
  /// **'Use dark theme throughout the app'**
  String get darkModeHint;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguage;

  /// No description provided for @contentLanguage.
  ///
  /// In en, this message translates to:
  /// **'Content Language'**
  String get contentLanguage;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @savedVideos.
  ///
  /// In en, this message translates to:
  /// **'Saved videos'**
  String get savedVideos;

  /// No description provided for @previouslyWatchedVideos.
  ///
  /// In en, this message translates to:
  /// **'Previously watched videos'**
  String get previouslyWatchedVideos;

  /// No description provided for @privacyAndData.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Data'**
  String get privacyAndData;

  /// No description provided for @usageAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Usage Analytics'**
  String get usageAnalytics;

  /// No description provided for @usageAnalyticsHint.
  ///
  /// In en, this message translates to:
  /// **'Help improve the app with anonymous data'**
  String get usageAnalyticsHint;

  /// No description provided for @clearWatchHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear Watch History'**
  String get clearWatchHistory;

  /// No description provided for @clearWatchHistoryHint.
  ///
  /// In en, this message translates to:
  /// **'Remove all watched videos from history'**
  String get clearWatchHistoryHint;

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get clearCache;

  /// No description provided for @clearCacheHint.
  ///
  /// In en, this message translates to:
  /// **'Free up storage space'**
  String get clearCacheHint;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @afeediProActive.
  ///
  /// In en, this message translates to:
  /// **'Afeedi Pro — Active'**
  String get afeediProActive;

  /// No description provided for @upgradeToPro.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get upgradeToPro;

  /// No description provided for @proFeatures.
  ///
  /// In en, this message translates to:
  /// **'Ad-free · Unlimited saves · AI feed'**
  String get proFeatures;

  /// No description provided for @freeFeatures.
  ///
  /// In en, this message translates to:
  /// **'Ad-free, AI feed, unlimited saves'**
  String get freeFeatures;

  /// No description provided for @clearHistoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will remove all videos from your watch history. This action cannot be undone.'**
  String get clearHistoryConfirm;

  /// No description provided for @watchHistoryClearedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Watch history cleared'**
  String get watchHistoryClearedSnackbar;

  /// No description provided for @cacheClearedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared successfully'**
  String get cacheClearedSnackbar;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @minEightChars.
  ///
  /// In en, this message translates to:
  /// **'Min 8 characters'**
  String get minEightChars;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @passwordChangedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChangedSuccessfully;

  /// No description provided for @currentPasswordIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect'**
  String get currentPasswordIncorrect;

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirm;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure? This cannot be undone.'**
  String get deleteAccountConfirm;

  /// No description provided for @videosWatchedLabel.
  ///
  /// In en, this message translates to:
  /// **'Videos\nWatched'**
  String get videosWatchedLabel;

  /// No description provided for @watchTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Watch\nTime'**
  String get watchTimeLabel;

  /// In en, this message translates to: **'Good morning!'**
  String get goodMorning;

  /// In en, this message translates to: **'Good afternoon!'**
  String get goodAfternoon;

  /// In en, this message translates to: **'Good evening!'**
  String get goodEvening;

  /// In en, this message translates to: **'No notifications'**
  String get noNotifications;

  /// In en, this message translates to: **"You're all caught up!"**
  String get allCaughtUp;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'hi',
    'id',
    'ja',
    'ko',
    'pt',
    'ru',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'id':
      return AppLocalizationsId();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
