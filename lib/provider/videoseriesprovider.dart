import 'package:flutter/material.dart';
import 'package:myBonus/model/videoseriesmodel.dart';
import 'package:myBonus/webservice/apiservices.dart';

// List of series (small, unpaginated — mirrors VideoProvider's categoryList)
// plus the currently open series' header + episodes, fetched independently.
class VideoSeriesProvider extends ChangeNotifier {
  bool loading = false;
  List<Result>? seriesList = [];

  bool detailLoading = false;
  DetailResult? seriesDetail;

  Future<void> getSeriesList() async {
    loading = true;
    notifyListeners();
    final model = await ApiService().videoSeriesList();
    if (model.status == 200) {
      seriesList = model.result ?? [];
    }
    loading = false;
    notifyListeners();
  }

  Future<void> getSeriesDetail(dynamic seriesId) async {
    detailLoading = true;
    seriesDetail = null;
    notifyListeners();
    final model = await ApiService().videoSeriesDetail(seriesId);
    if (model.status == 200) {
      seriesDetail = model.result;
    }
    detailLoading = false;
    notifyListeners();
  }

  void clearDetail() {
    seriesDetail = null;
    detailLoading = false;
  }
}
