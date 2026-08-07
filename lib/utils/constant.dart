class Constant {
  final String baseurl = "https://admin.mybonusmultimedia.com/public/api/";

  static String appName = "Bonus Radio";
  static String? appPackageName = "com.bonusmultimedia.mybonus";
  static String? appleAppId = "";
  static String? appVersion = "1";
  static String? appBuildNumber = "1.0";

  /* SherdPrefrence OneSignal App ID keyId */
  static const String oneSignalAppIdKey = "onesignal_apid";

  static String? userID;
  static String? userImage;
  static String currencySymbol = "";
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
  static String initialCountryCode = "IN";
  static String otpLoginType = "1";
  static String googleLoginType = "2";
  static String appleLoginType = "3";
  static String normalLoginType = "4";
}
