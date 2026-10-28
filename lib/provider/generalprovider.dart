import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:myBonus/model/generalsettingmodel.dart';
import 'package:myBonus/model/introscreenmodel.dart';
import 'package:myBonus/model/loginmodel.dart';
import 'package:myBonus/model/pagesmodel.dart';
import 'package:myBonus/model/registermodel.dart';
import 'package:myBonus/model/sociallinkmodel.dart';
import 'package:myBonus/utils/adhelper.dart';
import 'package:myBonus/utils/constant.dart';
import 'package:myBonus/utils/utils.dart';
import 'package:myBonus/utils/sharedpref.dart';
import 'package:uuid/uuid.dart';
import 'package:myBonus/webservice/apiservices.dart';

class GeneralProvider extends ChangeNotifier {
  GeneralsettingModel generalSettingModel = GeneralsettingModel();
  IntroScreenModel introScreenModel = IntroScreenModel();
  LoginModel loginModel = LoginModel();
  SocialLinkModel socialLinkModel = SocialLinkModel();
  RegisterModel registerModel = RegisterModel();
  PagesModel pagesModel = PagesModel();
  bool loading = false;
  SharedPref sharedPre = SharedPref();
  bool isProgressLoading = false;

  // Anonymous id generated once per install (no personal data) — lets the
  // backend tell unique users from repeat impressions in ad stats.
  Future<void> _loadDeviceId() async {
    String? id = await sharedPre.read('device_uid');
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await sharedPre.save('device_uid', id);
    }
    Constant.deviceId = id;
  }

  // Startup settings the app needs everywhere, without the side effects of
  // getGeneralsetting (AdMob/OneSignal init — Splash, which used to call
  // it, is no longer the entry screen). Device id first (ad stats), then
  // the last saved headline weight, then fresh values from the backend.
  Future<void> loadAppSettings() async {
    await _loadDeviceId();
    await _applyAppearanceSettings();
    try {
      final model = await ApiService().generalSetting();
      if (model.status == 200) {
        for (final setting in model.result ?? []) {
          await sharedPre.save(
              setting.key.toString(), setting.value.toString());
        }
        await _applyAppearanceSettings();
      }
    } catch (e) {
      printLog('loadAppSettings error: $e');
    }
    notifyListeners();
  }

  // Appearance settings from admin Settings > App (saved values).
  Future<void> _applyAppearanceSettings() async {
    Constant.titleFontWeight =
        int.tryParse(await sharedPre.read('title_font_weight') ?? '') ?? 700;
    Constant.showRadioMetadata =
        (await sharedPre.read('show_radio_metadata') ?? '1') != '0';
    Constant.thumbnailShimmer =
        (await sharedPre.read('thumbnail_loading') ?? 'shimmer') != 'image';
    Constant.mobileDataWarning =
        (await sharedPre.read('mobile_data_warning') ?? '1') != '0';
    Constant.mobileDataWarningMb =
        int.tryParse(await sharedPre.read('mobile_data_warning_mb') ?? '') ??
            100;
    Constant.playStoreUrl =
        (await sharedPre.read('play_store_url') ?? '').trim();
    Constant.appStoreUrl = (await sharedPre.read('app_store_url') ?? '').trim();
    Constant.mobileDataWarningInterval = int.tryParse(
            await sharedPre.read('mobile_data_warning_interval') ?? '') ??
        30;
  }

  Future<void> getGeneralsetting(BuildContext context) async {
    await _loadDeviceId();
    loading = true;
    generalSettingModel = await ApiService().generalSetting();
    printLog("genaral_setting status :==> ${generalSettingModel.status}");
    loading = false;
    printLog('generalSettingData status ==> ${generalSettingModel.status}');
    if (generalSettingModel.status == 200) {
      if (generalSettingModel.result != null) {
        for (var i = 0; i < (generalSettingModel.result?.length ?? 0); i++) {
          await sharedPre.save(
            generalSettingModel.result?[i].key.toString() ?? "",
            generalSettingModel.result?[i].value.toString() ?? "",
          );
        }
        Constant.userID = await sharedPre.read('userid');
        Constant.userImage = await sharedPre.read('userimage');
        Constant.titleFontWeight =
            int.tryParse(await sharedPre.read('title_font_weight') ?? '') ??
                700;

        /* Get Ads Init */
        if (context.mounted && !kIsWeb) {
          AdHelper.getAds(context);
          Utils.initializeOneSignal();
        }
      }
    }
  }

  Future<void> getIntroPages() async {
    loading = true;
    introScreenModel = await ApiService().getOnboardingScreen();
    loading = false;
    notifyListeners();
  }

  Future<void> getRegister(dynamic type, fullName, email, mobile, password,
      countCode, countryName, deviceToken, deviceType) async {
    loading = true;
    registerModel = await ApiService().register(type, fullName, email, mobile,
        password, countCode, countryName, deviceToken, deviceType);
    loading = false;
    notifyListeners();
  }

  Future<void> getLogin(dynamic type, mobile, email, password, deviceToken,
      deviceType, countryCode, countryName) async {
    loading = true;
    loginModel = await ApiService().login(type, mobile, email, password,
        deviceToken, deviceType, countryCode, countryName);
    loading = false;
    notifyListeners();
  }

  Future<void> getPages() async {
    loading = true;
    pagesModel = await ApiService().getPages();
    printLog("getPages status :==> ${pagesModel.status}");
    loading = false;
    notifyListeners();
  }

  Future<void> getSocialLink() async {
    loading = true;
    socialLinkModel = await ApiService().getSocialLink();
    loading = false;
    notifyListeners();
  }

  void setLoading(bool loading) {
    isProgressLoading = loading;
    notifyListeners();
  }
}
