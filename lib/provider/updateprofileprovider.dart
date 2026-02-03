import 'dart:io';
import 'package:flutter/material.dart';
import 'package:yourappname/model/updateprofilemodel.dart';
import 'package:yourappname/webservice/apiservices.dart';
import 'package:yourappname/utils/utils.dart';

class UpdateProfileProvider extends ChangeNotifier {
  UpdateprofileModel updateprofileModel = UpdateprofileModel();
  bool loading = false, loadingUpdate = false;

  Future<void> getUpdateProfile(String userid, String name, String email,
      String mobile, String countryCode, String countryName, File image) async {
    loading = true;
    updateprofileModel = await ApiService().updateprofile(
        userid, name, email, mobile, countryCode, countryName, image);
    loading = false;
    notifyListeners();
  }

  Future<void> getUpdateDataForPayment(
      dynamic fullName, email, mobileNumber) async {
    printLog("getUpdateDataForPayment fullname :==> $fullName");
    printLog("getUpdateDataForPayment email :=====> $email");
    printLog("getUpdateDataForPayment mobile :====> $mobileNumber");
    loadingUpdate = true;
    updateprofileModel =
        await ApiService().updateDataForPayment(fullName, email, mobileNumber);
    printLog(
        "getUpdateDataForPayment status :==> ${updateprofileModel.status}");
    printLog(
        "getUpdateDataForPayment message :==> ${updateprofileModel.message}");
    loadingUpdate = false;
    notifyListeners();
  }

  void setUpdateLoading(bool isLoading) {
    loadingUpdate = isLoading;
    notifyListeners();
  }
}
