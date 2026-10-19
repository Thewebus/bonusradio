import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:myBonus/model/liveeventmodel.dart';
import 'package:myBonus/pages/nodata.dart';
import 'package:myBonus/model/videocategorymodel.dart' as videocategory;
import 'package:myBonus/provider/videoprovider.dart';
import 'package:myBonus/utils/color.dart';
import 'package:myBonus/utils/constant.dart';
import 'package:myBonus/utils/customwidget.dart';
import 'package:myBonus/utils/dimens.dart';
import 'package:myBonus/utils/utils.dart';
import 'package:myBonus/widget/abidjan_header.dart';
import 'package:myBonus/widget/abidjan_pill_filter.dart';
import 'package:myBonus/widget/liveneon_buttons.dart';
import 'package:myBonus/widget/liveneon_header.dart';
import 'package:myBonus/widget/liveneon_pill_filter.dart';
import 'package:myBonus/widget/mynetworkimg.dart';
import 'package:myBonus/widget/mytext.dart';

// This screen is labelled "Films" to the user. It used to show two sources
// (live events + videos) side by side; "live event" had no real live/
// real-time behavior left, so the two were merged into one video catalog —
// this screen is now a single catalog view, not a juxtaposition of two.
// A series is listed like any video (its latest episode's cover) and opens
// its episode list on tap; standalone videos play directly. The category
// pills filter everything below them: banner, Tendances, and the catalog.
class LiveEvent extends StatefulWidget {
  const LiveEvent({super.key});

  @override
  State<LiveEvent> createState() => _LiveEventState();
}

class _LiveEventState extends State<LiveEvent> {
  static const String _allVideoCategoriesOption = "Tous";

  late VideoProvider videoProvider;
  final ScrollController categoryController = ScrollController();
  late ScrollController _scrollController;

  @override
  void initState() {
    videoProvider = Provider.of<VideoProvider>(context, listen: false);
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    videoProvider
        .getCategoryList()
        .then((_) => videoProvider.getCategoryVideos());
    _fetchVideos(0);
    videoProvider.getTrendingList();
    super.initState();
  }

  Future<void> _scrollListener() async {
    if (!_scrollController.hasClients) return;
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      if ((videoProvider.currentPage ?? 0) < (videoProvider.totalPage ?? 0)) {
        videoProvider.setLoadMore(true);
        _fetchVideos(videoProvider.currentPage ?? 0);
      }
    }
  }

  Future<void> _fetchVideos(int? nextPage) async {
    await videoProvider.getVideoList((nextPage ?? 0) + 1);
    videoProvider.setLoadMore(false);
  }

  List<String> _videoCategoryOptions() {
    final names = (videoProvider.categoryList ?? [])
        .map((c) => c.name ?? '')
        .where((n) => n.isNotEmpty)
        .toList();
    return [_allVideoCategoriesOption, ...names];
  }

  String get _selectedVideoCategoryLabel {
    final id = videoProvider.selectedCategoryId;
    if (id == null) return _allVideoCategoriesOption;
    return (videoProvider.categoryList ?? [])
            .firstWhere((c) => c.id == id,
                orElse: () => videocategory.Result())
            .name ??
        _allVideoCategoriesOption;
  }

  void _onVideoCategorySelected(String label) {
    final int? categoryId = label == _allVideoCategoriesOption
        ? null
        : (videoProvider.categoryList ?? [])
            .firstWhere((c) => c.name == label,
                orElse: () => videocategory.Result())
            .id;
    videoProvider.selectCategory(categoryId);
    _fetchVideos(0);
    videoProvider.getTrendingList();
  }

  Future<void> _refresh() async {
    videoProvider.clearProvider();
    _fetchVideos(0);
    videoProvider.getTrendingList();
    videoProvider.getCategoryVideos();
  }

  @override
  void dispose() {
    videoProvider.clearProvider();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isNight = Theme.of(context).brightness == Brightness.dark;
    return isNight ? _buildLiveNeonScaffold() : _buildAbidjanScaffold();
  }

  // LIVE NEON (night theme): same structure as ABIDJAN, recolored for the
  // neon palette. Tap-dispatch logic (_handleVideoTap) and data fetching
  // are fully shared with day.
  Widget _buildLiveNeonScaffold() {
    return Scaffold(
      backgroundColor: liveNeonBg,
      body: Container(
        decoration: liveNeonBackgroundDecoration(),
        child: Column(
          children: [
            const LiveNeonHeader(
              title: "liveevents",
            ),
            Expanded(
              child: RefreshIndicator(
                backgroundColor: liveNeonCardBg,
                color: colorPrimary,
                displacement: 70,
                edgeOffset: 1.0,
                triggerMode: RefreshIndicatorTriggerMode.anywhere,
                strokeWidth: 3,
                onRefresh: _refresh,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(0, 5, 0, 160),
                  scrollDirection: Axis.vertical,
                  physics: const BouncingScrollPhysics(),
                  child: Consumer<VideoProvider>(
                    builder: (context, videoprovider, child) {
                      if (videoprovider.loading && !videoprovider.loadMore) {
                        return buildVideoListShimmer();
                      }
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20),
                            child:
                                _buildCategoryPillRow(isNight: true),
                          ),
                          _buildLiveNeonFeaturedCard(),
                          _buildLiveNeonVideosSection(),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ABIDJAN (day theme): header, real category pills, featured card, then
  // the series strip and grid below — all one catalog, same shared
  // tap-dispatch logic throughout.
  Widget _buildAbidjanScaffold() {
    return Scaffold(
      backgroundColor: homeAccueilBg(context),
      body: Column(
        children: [
          const AbidjanHeader(
            title: "liveevents",
          ),
          Expanded(
            child: RefreshIndicator(
              backgroundColor: white,
              color: colorAccent,
              displacement: 70,
              edgeOffset: 1.0,
              triggerMode: RefreshIndicatorTriggerMode.anywhere,
              strokeWidth: 3,
              onRefresh: _refresh,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(0, 5, 0, 160),
                scrollDirection: Axis.vertical,
                physics: const BouncingScrollPhysics(),
                child: Consumer<VideoProvider>(
                  builder: (context, videoprovider, child) {
                    if (videoprovider.loading && !videoprovider.loadMore) {
                      return buildVideoListShimmer();
                    }
                    return Column(
                      children: [
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildCategoryPillRow(isNight: false),
                        ),
                        _buildAbidjanFeaturedCard(),
                        _buildAbidjanVideosSection(),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleVideoTap(int index) async {
    await _handleContentTap(videoProvider.videoList?[index]);
  }

  Future<void> _handleContentTap(Result? item) async {
    await Utils.openVideoCatalogItem(context, item);
  }

  // Caption under a catalog tile: episode count for a series, otherwise
  // the price (locked paid video) or "free".
  Widget _buildTileCaption(Result item) {
    final bool isSeries = item.isSeries == 1;
    final bool isPaidLocked = item.isPaid == 1 && item.isJoin == 0;
    final int episodes = item.episodeCount ?? 0;
    return MyText(
      color: colorPrimary,
      inter: 1,
      text: isSeries
          ? "Série · $episodes épisode${episodes > 1 ? 's' : ''}"
          : isPaidLocked
              ? "${Constant.currencySymbol}${item.price ?? ""}"
              : "free",
      fontsize: Dimens.textExtraSmall,
      multilanguage: !isSeries && !isPaidLocked,
      fontwaight: FontWeight.w600,
      maxline: 1,
      overflow: TextOverflow.ellipsis,
      textalign: TextAlign.left,
      fontstyle: FontStyle.normal,
    );
  }

  // Label of the featured card's button.
  String _featuredButtonLabel(Result item) {
    if (item.isSeries == 1) return "Voir les épisodes";
    if (item.isPaid == 1 && item.isJoin == 0) {
      return "${Constant.currencySymbol}${item.price ?? ""}";
    }
    return "Regarder";
  }

  Widget _buildAbidjanFeaturedCard() {
    final list = videoProvider.videoList;
    if (list == null || list.isEmpty) return const SizedBox.shrink();
    final Result item = list.first;
    bool isNew = false;
    final createdAt = item.createdAt;
    if (createdAt != null) {
      final parsed = DateTime.tryParse(createdAt);
      if (parsed != null) {
        isNew = DateTime.now().difference(parsed).inDays <= 7;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 20),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _handleVideoTap(0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: 220,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MyNetworkImage(
                  fit: BoxFit.cover,
                  imgWidth: double.infinity,
                  imgHeight: double.infinity,
                  imageUrl: item.landscapeImg?.toString() ??
                      item.portraitImg?.toString() ??
                      "",
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [transparent, Color(0xB3000000)],
                    ),
                  ),
                ),
                if (isNew)
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: colorPrimary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "Nouveau",
                        style: TextStyle(
                          color: white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: black.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    // Visual-only — there is no watch-list feature in the app.
                    child: const Icon(Icons.bookmark_border,
                        color: white, size: 18),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MyText(
                        color: white,
                        text: item.title?.toString() ?? "",
                        multilanguage: false,
                        inter: 4,
                        fontsize: Dimens.textlargeBig,
                        fontwaight: FontWeight.w700,
                        maxline: 2,
                        textalign: TextAlign.left,
                        overflow: TextOverflow.ellipsis,
                        fontstyle: FontStyle.normal,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.play_arrow,
                                    color: black, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  _featuredButtonLabel(item),
                                  style: const TextStyle(
                                    color: black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // "Tendances" — most viewed catalog entries (series count the views of
  // all their episodes), following the selected category pill like the
  // rest of the screen. Hidden when nothing matches.
  Widget _buildTrendingStrip({required bool isNight}) {
    return Consumer<VideoProvider>(
      builder: (context, provider, child) {
        final list = provider.trendingList;
        if (list.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: MyText(
                color: isNight ? white : black,
                text: "Tendances",
                multilanguage: false,
                inter: isNight ? 1 : 4,
                fontsize: Dimens.textBig,
                fontwaight: FontWeight.w700,
                maxline: 1,
                textalign: TextAlign.left,
                fontstyle: FontStyle.normal,
              ),
            ),
            SizedBox(
              height: 230,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                itemCount: list.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) =>
                    _buildPortraitTile(list[index], rank: index + 1),
              ),
            ),
            const SizedBox(height: 10),
          ],
        );
      },
    );
  }

  // Portrait cover tile shared by Tendances and the per-category rows.
  // `rank` adds the Tendances position badge.
  Widget _buildPortraitTile(Result item, {int? rank}) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _handleContentTap(item),
      child: SizedBox(
        width: 130,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: MyNetworkImage(
                    imgWidth: 130,
                    imgHeight: 180,
                    fit: BoxFit.cover,
                    imageUrl: item.portraitImg?.toString() ?? "",
                  ),
                ),
                if (rank != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colorPrimary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "#$rank",
                        style: const TextStyle(
                          color: white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                if (item.isSeries == 1)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.video_library_outlined,
                          color: white, size: 14),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            MyText(
              color: Theme.of(context).colorScheme.surface,
              inter: 1,
              text: item.title?.toString() ?? "",
              fontsize: Dimens.textSmall,
              fontwaight: FontWeight.w600,
              maxline: 1,
              overflow: TextOverflow.ellipsis,
              textalign: TextAlign.left,
              fontstyle: FontStyle.normal,
            ),
            _buildTileCaption(item),
          ],
        ),
      ),
    );
  }

  // Below the featured card: Tendances, then the catalog — one row per
  // category for "Tous", or the selected category as a grid.
  Widget _buildAbidjanVideosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTrendingStrip(isNight: false),
        _selectedVideoCategoryLabel == _allVideoCategoriesOption
            ? _buildCategoryRows(isNight: false)
            : buildVideoList(),
      ],
    );
  }

  // LIVE NEON (night theme) featured card. Same shared _handleVideoTap
  // logic as ABIDJAN's version — only the palette differs.
  Widget _buildLiveNeonFeaturedCard() {
    final list = videoProvider.videoList;
    if (list == null || list.isEmpty) return const SizedBox.shrink();
    final Result item = list.first;
    bool isNew = false;
    final createdAt = item.createdAt;
    if (createdAt != null) {
      final parsed = DateTime.tryParse(createdAt);
      if (parsed != null) {
        isNew = DateTime.now().difference(parsed).inDays <= 7;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 20),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _handleVideoTap(0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: 220,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MyNetworkImage(
                  fit: BoxFit.cover,
                  imgWidth: double.infinity,
                  imgHeight: double.infinity,
                  imageUrl: item.landscapeImg?.toString() ??
                      item.portraitImg?.toString() ??
                      "",
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [transparent, Color(0xCC000000)],
                    ),
                  ),
                ),
                if (isNew)
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: colorPrimary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "Nouveau",
                        style: TextStyle(
                          color: white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: black.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    // Visual-only — there is no watch-list feature in the app.
                    child: const Icon(Icons.bookmark_border,
                        color: white, size: 18),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MyText(
                        color: white,
                        text: item.title?.toString() ?? "",
                        multilanguage: false,
                        inter: 4,
                        fontsize: Dimens.textlargeBig,
                        fontwaight: FontWeight.w700,
                        maxline: 2,
                        textalign: TextAlign.left,
                        overflow: TextOverflow.ellipsis,
                        fontstyle: FontStyle.normal,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          LiveNeonGradientButton(
                            icon: Icons.play_arrow,
                            label: _featuredButtonLabel(item),
                            onTap: () => _handleVideoTap(0),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveNeonVideosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTrendingStrip(isNight: true),
        _selectedVideoCategoryLabel == _allVideoCategoriesOption
            ? _buildCategoryRows(isNight: true)
            : buildVideoList(),
      ],
    );
  }

  // Real server-side category pills (tbl_video_category) — sit right below
  // the header, above the featured card, same spot the target design
  // mockup shows them. Consumer, not a direct read — getCategoryList()
  // resolves after this section's first (synchronous) build, so the row
  // needs its own listener to appear once the categories actually arrive.
  Widget _buildCategoryPillRow({required bool isNight}) {
    return Consumer<VideoProvider>(
      builder: (context, videoprovider, child) {
        if ((videoprovider.categoryList ?? []).isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
          child: isNight
              ? LiveNeonPillFilterRow(
                  options: _videoCategoryOptions(),
                  selected: _selectedVideoCategoryLabel,
                  onSelected: _onVideoCategorySelected,
                )
              : AbidjanPillFilterRow(
                  options: _videoCategoryOptions(),
                  selected: _selectedVideoCategoryLabel,
                  onSelected: _onVideoCategorySelected,
                ),
        );
      },
    );
  }

  // "Tous" browse view — one horizontal row per video category, each
  // showing real portrait covers (a series shows its latest episode's
  // cover and sits among the category's videos). Replaces the flat grid only when
  // no specific category pill is selected; picking a pill still shows
  // that one category as the existing flat grid below.
  Widget _buildCategoryRows({required bool isNight}) {
    return Consumer<VideoProvider>(
      builder: (context, provider, child) {
        if (provider.categoryRowsLoading && provider.categoryVideos.isEmpty) {
          return buildVideoListShimmer();
        }
        final categories = provider.categoryList ?? [];
        final rows = categories
            .where((c) =>
                c.id != null && (provider.categoryVideos[c.id] ?? []).isNotEmpty)
            .toList();
        if (rows.isEmpty) {
          return const NoData(text: "", subTitle: "");
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rows
              .map((category) => _buildCategoryRow(category, isNight: isNight))
              .toList(),
        );
      },
    );
  }

  Widget _buildCategoryRow(videocategory.Result category,
      {required bool isNight}) {
    final items = videoProvider.categoryVideos[category.id] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: MyText(
            color: isNight ? white : black,
            text: category.name ?? "",
            multilanguage: false,
            inter: isNight ? 1 : 4,
            fontsize: Dimens.textBig,
            fontwaight: FontWeight.w700,
            maxline: 1,
            textalign: TextAlign.left,
            fontstyle: FontStyle.normal,
          ),
        ),
        SizedBox(
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _buildPortraitTile(items[index]),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget buildVideoList() {
    return Consumer<VideoProvider>(builder: (context, videoprovider, child) {
      if (videoprovider.loading && !videoprovider.loadMore) {
        return buildVideoListShimmer();
      } else {
        if (videoprovider.videoModel.status == 200 &&
            videoprovider.videoList != null) {
          if ((videoprovider.videoList?.length ?? 0) > 0) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildVideoListItem(),
                if (videoprovider.loadMore)
                  SizedBox(
                    height: 50,
                    child: Utils.pageLoader(),
                  )
                else
                  const SizedBox.shrink(),
              ],
            );
          } else {
            return const NoData(text: "", subTitle: "");
          }
        } else {
          return const NoData(text: "", subTitle: "");
        }
      }
    });
  }

  Widget buildVideoListItem() {
    return buildContentGridItem(videoProvider.videoList, _handleVideoTap);
  }

  // Shared 2-column grid for the video catalog.
  Widget buildContentGridItem(
      List<Result>? items, void Function(int index) onTapItem) {
    return AlignedGridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 20,
      crossAxisSpacing: 15,
      itemCount: items?.length ?? 0,
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 8),
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        final item = items?[index];
        return InkWell(
          focusColor: transparent,
          splashColor: transparent,
          hoverColor: transparent,
          highlightColor: transparent,
          onTap: () => onTapItem(index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: MyNetworkImage(
                    imgWidth: MediaQuery.of(context).size.width,
                    imgHeight: 250,
                    fit: BoxFit.cover,
                    imageUrl: item?.portraitImg.toString() ?? ""),
              ),
              const SizedBox(height: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(
                    color: Theme.of(context).colorScheme.surface,
                    inter: 1,
                    text: item?.title.toString() ?? "",
                    fontsize: Dimens.textSmall,
                    fontwaight: FontWeight.w600,
                    maxline: 1,
                    overflow: TextOverflow.ellipsis,
                    textalign: TextAlign.left,
                    fontstyle: FontStyle.normal,
                  ),
                  const SizedBox(height: 4),
                  if (item?.isSeries == 1)
                    _buildTileCaption(item!)
                  else if (item?.isPaid.toString() == "1" &&
                      item?.isJoin.toString() == "0")
                    MyText(
                      color: colorPrimary,
                      inter: 1,
                      text:
                          "${Constant.currencySymbol}${item?.price.toString() ?? ""}",
                      fontsize: Dimens.textTitle,
                      fontwaight: FontWeight.w600,
                      maxline: 2,
                      overflow: TextOverflow.ellipsis,
                      textalign: TextAlign.left,
                      fontstyle: FontStyle.normal,
                    )
                  else if (item?.isPaid.toString() == "1" &&
                      item?.isJoin.toString() == "1")
                    Container(
                      padding: const EdgeInsets.fromLTRB(5, 3, 5, 3),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: colorPrimary),
                      child: MyText(
                        color: white,
                        inter: 1,
                        text: "playyourevent",
                        fontsize: Dimens.textSmall,
                        multilanguage: true,
                        fontwaight: FontWeight.w600,
                        maxline: 2,
                        overflow: TextOverflow.ellipsis,
                        textalign: TextAlign.left,
                        fontstyle: FontStyle.normal,
                      ),
                    )
                  else
                    MyText(
                      color: colorPrimary,
                      inter: 1,
                      text: "free",
                      fontsize: Dimens.textTitle,
                      multilanguage: true,
                      fontwaight: FontWeight.w600,
                      maxline: 2,
                      overflow: TextOverflow.ellipsis,
                      textalign: TextAlign.left,
                      fontstyle: FontStyle.normal,
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildVideoListShimmer() {
    return AlignedGridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 20,
      crossAxisSpacing: 15,
      itemCount: 10,
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 8),
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CustomWidget.roundcorner(
                width: MediaQuery.of(context).size.width,
                height: 250,
              ),
            ),
            const SizedBox(height: 10),
            const Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomWidget.roundcorner(
                  width: 120,
                  height: 8,
                ),
                SizedBox(height: 3),
                CustomWidget.roundcorner(
                  width: 120,
                  height: 8,
                ),
                SizedBox(height: 3),
                CustomWidget.roundcorner(
                  width: 120,
                  height: 8,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
