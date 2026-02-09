import 'package:myBonus/model/historymodel.dart';
import 'package:myBonus/webservice/apiservices.dart';
import 'package:flutter/material.dart';
import 'package:myBonus/utils/utils.dart';

class SubHistoryProvider extends ChangeNotifier {
  HistoryModel historyModel = HistoryModel();

  bool loading = false;

  Future<void> getTransactionList() async {
    loading = true;
    historyModel = await ApiService().transactionList();
    printLog("getTransactionList status :==> ${historyModel.status}");
    printLog("getTransactionList message :==> ${historyModel.message}");
    loading = false;
    notifyListeners();
  }

  void clearProvider() {
    printLog("============ clearProvider ============");
    historyModel = HistoryModel();
  }
}
