import 'package:flutter/material.dart';
import 'package:myBonus/model/languagemodel.dart';
import 'package:myBonus/webservice/apiservices.dart';

class LanguageProvider extends ChangeNotifier {
  LanguageModel languageModel = LanguageModel();
  bool loading = false;

  Future<void> getLanguage(String pageno) async {
    loading = true;
    languageModel = await ApiService().language(pageno);
    loading = false;
    notifyListeners();
  }
}
