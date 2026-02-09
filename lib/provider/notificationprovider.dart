import 'package:flutter/material.dart';
import 'package:myBonus/model/notificationlistmodel.dart';
import 'package:myBonus/webservice/apiservices.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationModel notificationModel = NotificationModel();
  bool loading = false;

  Future<void> getNotification(String userid) async {
    loading = true;
    notificationModel = await ApiService().notification(userid);
    loading = false;
    notifyListeners();
  }
}
