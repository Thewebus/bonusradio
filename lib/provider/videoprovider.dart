import 'package:flutter/material.dart';
import 'package:myBonus/model/liveeventmodel.dart';
import 'package:myBonus/model/videocategorymodel.dart' as videocategory;
import 'package:myBonus/webservice/apiservices.dart';

// Drives the whole Films screen catalog (former "live events" were merged
// into the video catalog — there's no separate provider for them anymore).
// Standard pagination/dedupe pattern, plus the category filter and the
// separate category list that the Films screen's pill row needs — the two
// are fetched independently since switching category restarts the video
// pagination but never needs to refetch the categories themselves.
class VideoProvider extends ChangeNotifier {
  /* Video Pagination */
  LiveEventModel videoModel = LiveEventModel();
  bool loading = false, loadMore = false;
  int? totalRows, totalPage, currentPage, morePage;
  List<Result>? videoList = [];

  /* Category filter */
  int? selectedCategoryId;
  bool categoriesLoading = false;
  List<videocategory.Result>? categoryList = [];

  /* Browse-by-category rows ("Tous" view) — one short list per category,
     fetched via the same get_video endpoint as the main list, just called
     once per category instead of once overall. Independent of the
     paginated videoList above, which only ever holds one category (or
     none) at a time. */
  bool categoryRowsLoading = false;
  Map<int, List<Result>> categoryVideos = {};

  Future<void> getCategoryVideos() async {
    if ((categoryList ?? []).isEmpty) return;
    categoryRowsLoading = true;
    notifyListeners();
    final Map<int, List<Result>> rows = {};
    for (final category in categoryList!) {
      if (category.id == null) continue;
      final model = await ApiService().videoList(1, category.id, '');
      if (model.status == 200) {
        rows[category.id!] = model.result ?? [];
      }
    }
    categoryVideos = rows;
    categoryRowsLoading = false;
    notifyListeners();
  }

  /* "Tendances" strip — most viewed catalog entries (videos and series),
     same category filter as the main list. */
  bool trendingLoading = false;
  List<Result> trendingList = [];

  Future<void> getTrendingList() async {
    trendingLoading = true;
    final int? categoryId = selectedCategoryId;
    final model = await ApiService()
        .videoList(1, categoryId, '', sort: 'trending');
    // A pill tapped while this was in flight already started a newer fetch.
    if (categoryId != selectedCategoryId) return;
    trendingList = model.status == 200 ? (model.result ?? []) : [];
    trendingLoading = false;
    notifyListeners();
  }

  Future<void> getVideoList(dynamic pageNo) async {
    loading = true;
    videoModel =
        await ApiService().videoList(pageNo, selectedCategoryId, '');
    if (videoModel.status == 200) {
      setPagination(videoModel.totalRows, videoModel.totalPage,
          videoModel.currentPage, videoModel.morePage);
      if (videoModel.result != null && (videoModel.result?.length ?? 0) > 0) {
        for (var i = 0; i < (videoModel.result?.length ?? 0); i++) {
          videoList?.add(videoModel.result?[i] ?? Result());
        }
        final Map<int, Result> postMap = {};
        videoList?.forEach((item) {
          postMap[item.id ?? 0] = item;
        });
        videoList = postMap.values.toList();
        setLoadMore(false);
      }
    }
    loading = false;
    notifyListeners();
  }

  Future<void> getCategoryList() async {
    categoriesLoading = true;
    final model = await ApiService().videoCategoryList();
    if (model.status == 200) {
      categoryList = model.result ?? [];
    }
    categoriesLoading = false;
    notifyListeners();
  }

  void selectCategory(int? categoryId) {
    if (selectedCategoryId == categoryId) return;
    selectedCategoryId = categoryId;
    videoModel = LiveEventModel();
    totalRows = null;
    totalPage = null;
    currentPage = null;
    morePage = null;
    videoList = [];
    trendingList = [];
    notifyListeners();
  }

  void setPagination(
      int? totalRows, int? totalPage, int? currentPage, bool? morePage) {
    this.currentPage = currentPage;
    this.totalRows = totalRows;
    this.totalPage = totalPage;
    notifyListeners();
  }

  void setLoadMore(bool loadMore) {
    this.loadMore = loadMore;
    notifyListeners();
  }

  void clearProvider() {
    videoModel = LiveEventModel();
    loading = false;
    loadMore = false;
    totalRows = null;
    totalPage = null;
    currentPage = null;
    morePage = null;
    videoList = [];
  }
}
