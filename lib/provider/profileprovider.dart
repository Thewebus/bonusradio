import 'package:flutter/material.dart';
import 'package:myBonus/model/profilemodel.dart';
import 'package:myBonus/utils/utils.dart';
import 'package:myBonus/webservice/apiservices.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileModel profileModel = ProfileModel();
  bool loading = false;

  Future<void> getProfile(BuildContext context) async {
    loading = true;
    profileModel = await ApiService().profile();
    printLog("get_profile status :==> ${profileModel.status}");
    printLog("get_profile message :==> ${profileModel.message}");
    if (profileModel.status == 200 && profileModel.result != null) {
      if ((profileModel.result?.length ?? 0) > 0) {
        Utils.updatePremium(profileModel.result?[0].isBuy.toString() ?? "0");
        if (context.mounted) {
          printLog("========= get_profile loadAds =========");
          Utils.loadAds(context);
        }
      }
    }
    loading = false;
    notifyListeners();
  }

  void clearProvider() {
    profileModel = ProfileModel();
  }
}
