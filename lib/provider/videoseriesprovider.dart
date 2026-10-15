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

  // No notifyListeners() before the first await: both methods are called
  // synchronously from a page's initState() (no `await` there, since
  // initState can't be async), and initState runs while the parent widget
  // is still building — notifying synchronously at that point throws
  // "setState() or markNeedsBuild() called during build".
  Future<void> getSeriesList() async {
    loading = true;
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
