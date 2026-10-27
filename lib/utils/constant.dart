class Constant {
  final String baseurl = "https://admin.mybonusmultimedia.com/public/api/";

  static String appName = "myBonus";
  static String? appPackageName = "com.bonusmultimedia.mybonus";
  static String? appleAppId = "";
  static String? appVersion = "1";
  static String? appBuildNumber = "1.0";

  /* SherdPrefrence OneSignal App ID keyId */
  static const String oneSignalAppIdKey = "onesignal_apid";

  static String? userID;
  static String? userImage;
  static String currencySymbol = "";
  // Weight of the serif headline font (Playfair Display, MyText inter: 4),
  // set in admin Settings > App (general_setting "title_font_weight").
  static int titleFontWeight = 700;
  // Admin Settings > App: show AzuraCast live song/cover/listeners.
  static bool showRadioMetadata = true;
  // Admin Settings > App: thumbnail while loading — shimmer or logo image.
  static bool thumbnailShimmer = true;
  // Admin Settings > App: warn when streaming on mobile data — on/off, the
  // MB threshold, and minutes between two reminders.
  static bool mobileDataWarning = true;
  static int mobileDataWarningMb = 100;
  static int mobileDataWarningInterval = 30;
  // Anonymous random id of this install — ads' unique-users stats.
  static String? deviceId;
  static String currency = "";
  static String themeMode = "auto";
  static String radioType = "radio";
  static String podcastType = "podcast";

  // Toast Message All App

  static String androidAppShareUrlDesc =
      "Let me recommend you this application\n\n$androidAppUrl";
  static String iosAppShareUrlDesc =
      "Let me recommend you this application\n\n$iosAppUrl";

  static String androidAppUrl =
      "https://play.google.com/store/apps/details?id=${Constant.appPackageName}";
  static String iosAppUrl =
      "https://apps.apple.com/us/app/id${Constant.appleAppId}";

  static int fixFourDigit = 1317;
  static int fixSixDigit = 161613;
  static int bannerDuration = 10000; // in milliseconds
  static int animationDuration = 800; // in milliseconds

  /* Live Event ArrayList Static */

  /* Show Ad By Type */
  static String rewardAdType = "rewardAd";
  static String interstialAdType = "interstialAd";

  /* Show Ad By Type */
  static String initialCountryCode = "CI";
  static String otpLoginType = "1";
  static String googleLoginType = "2";
  static String appleLoginType = "3";
  static String normalLoginType = "4";
}
