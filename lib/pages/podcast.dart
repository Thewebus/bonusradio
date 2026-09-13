import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:myBonus/music/musicdetails.dart';
import 'package:myBonus/pages/home.dart';
import 'package:myBonus/pages/login.dart';
import 'package:myBonus/pages/podcastviewall.dart';
import 'package:myBonus/provider/addfavouriteprovider.dart';
import 'package:myBonus/provider/musicdetailprovider.dart';
import 'package:myBonus/provider/podcastprovider.dart';
import 'package:myBonus/utils/adhelper.dart';
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
import 'package:myBonus/widget/myimage.dart';
import 'package:myBonus/widget/mynetworkimg.dart';
import 'package:myBonus/widget/mytext.dart';
import 'package:myBonus/model/podcastsectionmodel.dart' as podcastsection;

class Podcast extends StatefulWidget {
  final VoidCallback? onBack;
  const Podcast({super.key, this.onBack});

  @override
  State<Podcast> createState() => _PodcastState();
}

class _PodcastState extends State<Podcast> {
  CarouselSliderController bannerController = CarouselSliderController();
  late PodcatsProvider podcatsProvider;
  late ScrollController _scrollController;
  static const String _allCategoriesOption = "Tous";
  String _selectedCategory = _allCategoriesOption;

  @override
  void initState() {
    podcatsProvider = Provider.of<PodcatsProvider>(context, listen: false);
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    super.initState();
    _fetchData(0);
  }

  Future<void> _scrollListener() async {
    if (!_scrollController.hasClients) return;
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange &&
        (podcatsProvider.sectioncurrentPage ?? 0) <
            (podcatsProvider.sectiontotalPage ?? 0)) {
      podcatsProvider.setLoadMore(true);
      _fetchData(podcatsProvider.sectioncurrentPage ?? 0);
    }
  }

  Future<void> _fetchData(int? nextPage) async {
    printLog("isMorePage  ======> ${podcatsProvider.sectionisMorePage}");
    printLog("currentPage ======> ${podcatsProvider.sectioncurrentPage}");
    printLog("totalPage   ======> ${podcatsProvider.sectiontotalPage}");
    printLog("nextpage   ======> $nextPage");
    printLog("Call MyCourse");
    printLog("Pageno:== ${(nextPage ?? 0) + 1}");
    await podcatsProvider.getSeactionList((nextPage ?? 0) + 1);
    podcatsProvider.setLoadMore(false);
  }

  @override
  void dispose() {
    podcatsProvider.clearProvider();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isNight = Theme.of(context).brightness == Brightness.dark;
    return isNight ? _buildLiveNeonScaffold() : _buildAbidjanScaffold();
  }

  // LIVE NEON (night theme): same structure as ABIDJAN (flat header, real
  // category-pill filter, featured card) recolored for the neon palette.
  // Business logic (playback, favourites, pagination) is fully shared with
  // day via the theme-neutral provider/section helpers below.
  Widget _buildLiveNeonScaffold() {
    return Scaffold(
      backgroundColor: liveNeonBg,
      body: Container(
        decoration: liveNeonBackgroundDecoration(),
        child: Column(
          children: [
            LiveNeonHeader(
              title: "podcast",
              showBack: true,
              onBack: () => widget.onBack?.call(),
            ),
            Consumer<PodcatsProvider>(
              builder: (context, podcastprovider, child) {
                final options = _availableCategoryOptions();
                if (options.length <= 1) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: LiveNeonPillFilterRow(
                    options: options,
                    selected: _selectedCategory,
                    onSelected: (value) =>
                        setState(() => _selectedCategory = value),
                  ),
                );
              },
            ),
            Expanded(
              child: RefreshIndicator(
                backgroundColor: liveNeonCardBg,
                color: colorPrimary,
                displacement: 70,
                edgeOffset: 1.0,
                triggerMode: RefreshIndicatorTriggerMode.anywhere,
                strokeWidth: 3,
                onRefresh: () async {
                  podcatsProvider.clearProvider();
                  _fetchData(0);
                },
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(0, 5, 0, 160),
                  child: Consumer<PodcatsProvider>(
                    builder: (context, podcastprovider, child) {
                      if (podcastprovider.loading &&
                          !podcastprovider.loadmore) {
                        return shimmer();
                      }
                      final filtered = _filteredSections();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            _buildLiveNeonFeaturedCard(filtered),
                            setSectioByType(overrideSections: filtered),
                            if (podcastprovider.loadmore)
                              SizedBox(
                                height: 50,
                                child: Utils.pageLoader(),
                              )
                            else
                              const SizedBox.shrink(),
                          ],
                        ),
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

  // ABIDJAN (day theme): flat header, real category-pill filter, featured
  // card. Business logic (playback, favourites, pagination) is shared with
  // night via the unchanged provider/section helpers below.
  Widget _buildAbidjanScaffold() {
    return Scaffold(
      backgroundColor: homeAccueilBg(context),
      body: Column(
        children: [
          AbidjanHeader(
            title: "podcast",
            showBack: true,
            onBack: () => widget.onBack?.call(),
          ),
          Consumer<PodcatsProvider>(
            builder: (context, podcastprovider, child) {
              final options = _availableCategoryOptions();
              if (options.length <= 1) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AbidjanPillFilterRow(
                  options: options,
                  selected: _selectedCategory,
                  onSelected: (value) =>
                      setState(() => _selectedCategory = value),
                ),
              );
            },
          ),
          Expanded(
            child: RefreshIndicator(
              backgroundColor: white,
              color: colorAccent,
              displacement: 70,
              edgeOffset: 1.0,
              triggerMode: RefreshIndicatorTriggerMode.anywhere,
              strokeWidth: 3,
              onRefresh: () async {
                podcatsProvider.clearProvider();
                _fetchData(0);
              },
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(0, 5, 0, 160),
                child: Consumer<PodcatsProvider>(
                  builder: (context, podcastprovider, child) {
                    if (podcastprovider.loading && !podcastprovider.loadmore) {
                      return shimmer();
                    }
                    final filtered = _filteredSections();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          _buildAbidjanFeaturedCard(filtered),
                          setSectioByType(overrideSections: filtered),
                          if (podcastprovider.loadmore)
                            SizedBox(
                              height: 50,
                              child: Utils.pageLoader(),
                            )
                          else
                            const SizedBox.shrink(),
                        ],
                      ),
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

  List<String> _availableCategoryOptions() {
    final names = <String>{};
    for (final section
        in podcatsProvider.sectionList ?? <podcastsection.Result>[]) {
      for (final d in section.data ?? <podcastsection.Datum>[]) {
        final name = d.categoryName?.trim();
        if (name != null && name.isNotEmpty) names.add(name);
      }
    }
    final sorted = names.toList()..sort();
    return [_allCategoriesOption, ...sorted];
  }

  List<podcastsection.Result> _filteredSections() {
    final sections = podcatsProvider.sectionList ?? <podcastsection.Result>[];
    if (_selectedCategory == _allCategoriesOption) return sections;
    return sections
        .map((s) {
          final filteredData = (s.data ?? <podcastsection.Datum>[])
              .where((d) => d.categoryName == _selectedCategory)
              .toList();
          return podcastsection.Result(
            id: s.id,
            title: s.title,
            subTitle: s.subTitle,
            categoryId: s.categoryId,
            languageId: s.languageId,
            screenLayout: s.screenLayout,
            isPremium: s.isPremium,
            orderByUpload: s.orderByUpload,
            orderByPlay: s.orderByPlay,
            noOfContent: s.noOfContent,
            viewAll: s.viewAll,
            sortable: s.sortable,
            status: s.status,
            createdAt: s.createdAt,
            updatedAt: s.updatedAt,
            data: filteredData,
          );
        })
        .where((s) => (s.data?.length ?? 0) > 0)
        .toList();
  }

  Future<void> _playPodcastEpisode(podcastsection.Datum item) async {
    final musicdetailProvider =
        Provider.of<MusicDetailProvider>(context, listen: false);
    await musicdetailProvider.getEpisodebyPodcastList(
        item.id.toString(), 0);

    if (!musicdetailProvider.loading) {
      if (musicdetailProvider.getEpisodeByPodcstModel.status == 200 &&
          ((musicdetailProvider.getEpisodeByPodcstModel.result?.length ?? 0) >
              0)) {
        if (!context.mounted) return;
        Utils.playAudio(
            context,
            "podcast",
            item.isPremium ?? 0,
            item.isBuy ?? 0,
            item.landscapeImg?.toString() ?? "",
            item.title?.toString() ?? "",
            '',
            musicdetailProvider.episodeList?[0].episodeAudio.toString() ?? "",
            "",
            item.description?.toString() ?? "",
            musicdetailProvider.episodeList?[0].id.toString() ?? "",
            item.id.toString(),
            0,
            musicdetailProvider.episodeList?.toList() ?? []);
      }
    }
  }

  Widget _buildAbidjanFeaturedCard(List<podcastsection.Result> sections) {
    podcastsection.Datum? item;
    for (final s in sections) {
      final data = s.data ?? [];
      if (data.isNotEmpty) {
        item = data.first;
        break;
      }
    }
    if (item == null) return const SizedBox.shrink();
    final featured = item;
    final bool isPremiumLocked =
        featured.isPremium == 1 && featured.isBuy == 0;

    void onFavourite() {
      if (Constant.userID == null) {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => const Login()));
        return;
      }
      Provider.of<AddFavouriteProvider>(context, listen: false)
          .getAddFavourite(Constant.userID ?? "", featured.id.toString());
      Utils.showToast("Ajouté aux favoris");
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 20),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _playPodcastEpisode(featured),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: 210,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MyNetworkImage(
                  fit: BoxFit.cover,
                  imgWidth: double.infinity,
                  imgHeight: double.infinity,
                  imageUrl: featured.landscapeImg?.toString() ??
                      featured.portraitImg?.toString() ??
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
                      "Épisode de la semaine",
                      style: TextStyle(
                        color: white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (isPremiumLocked)
                  const Positioned(
                    top: 14,
                    right: 14,
                    child: Icon(Icons.lock, color: white, size: 18),
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
                        text: featured.title?.toString() ?? "",
                        multilanguage: false,
                        inter: 4,
                        fontsize: Dimens.textlargeBig,
                        fontwaight: FontWeight.w700,
                        maxline: 2,
                        textalign: TextAlign.left,
                        overflow: TextOverflow.ellipsis,
                        fontstyle: FontStyle.normal,
                      ),
                      if ((featured.artistName ?? "").isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          featured.artistName!,
                          style: TextStyle(
                            color: white.withValues(alpha: 0.75),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 12),
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
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.play_arrow,
                                    color: black, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  "Écouter",
                                  style: TextStyle(
                                    color: black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: onFavourite,
                            child: Container(
                              width: 38,
                              height: 38,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: black.withValues(alpha: 0.35),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.favorite_border,
                                  color: white, size: 18),
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

  // LIVE NEON (night theme) featured card. Same shared logic as ABIDJAN's
  // version (_playPodcastEpisode, favourite closure) — only the palette
  // differs: gradient button instead of solid white, dark cast unaffected.
  Widget _buildLiveNeonFeaturedCard(List<podcastsection.Result> sections) {
    podcastsection.Datum? item;
    for (final s in sections) {
      final data = s.data ?? [];
      if (data.isNotEmpty) {
        item = data.first;
        break;
      }
    }
    if (item == null) return const SizedBox.shrink();
    final featured = item;
    final bool isPremiumLocked =
        featured.isPremium == 1 && featured.isBuy == 0;

    void onFavourite() {
      if (Constant.userID == null) {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => const Login()));
        return;
      }
      Provider.of<AddFavouriteProvider>(context, listen: false)
          .getAddFavourite(Constant.userID ?? "", featured.id.toString());
      Utils.showToast("Ajouté aux favoris");
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 20),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _playPodcastEpisode(featured),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: 210,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MyNetworkImage(
                  fit: BoxFit.cover,
                  imgWidth: double.infinity,
                  imgHeight: double.infinity,
                  imageUrl: featured.landscapeImg?.toString() ??
                      featured.portraitImg?.toString() ??
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
                      "Épisode de la semaine",
                      style: TextStyle(
                        color: white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (isPremiumLocked)
                  const Positioned(
                    top: 14,
                    right: 14,
                    child: Icon(Icons.lock, color: white, size: 18),
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
                        text: featured.title?.toString() ?? "",
                        multilanguage: false,
                        inter: 4,
                        fontsize: Dimens.textlargeBig,
                        fontwaight: FontWeight.w700,
                        maxline: 2,
                        textalign: TextAlign.left,
                        overflow: TextOverflow.ellipsis,
                        fontstyle: FontStyle.normal,
                      ),
                      if ((featured.artistName ?? "").isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          featured.artistName!,
                          style: const TextStyle(
                            color: liveNeonTextSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          LiveNeonGradientButton(
                            icon: Icons.play_arrow,
                            label: "Écouter",
                            onTap: () => _playPodcastEpisode(featured),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: onFavourite,
                            child: Container(
                              width: 38,
                              height: 38,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: black.withValues(alpha: 0.35),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.favorite_border,
                                  color: white, size: 18),
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

  Widget setSectioByType({List<podcastsection.Result>? overrideSections}) {
    final sections = overrideSections ?? podcatsProvider.sectionList;
    if (podcatsProvider.podcastSectionModel.status == 200 &&
        sections != null) {
      if ((sections.length) > 0) {
        return MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: ListView.builder(
            itemCount: sections.length,
            shrinkWrap: true,
            reverse: false,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (BuildContext context, int index) {
              if (sections[index].data != null &&
                  (sections[index].data?.length ?? 0) > 0) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(15, 25, 15, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                MyText(
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                    text: sections[index].title.toString(),
                                    fontsize: Dimens.textBig,
                                    fontwaight: FontWeight.w600,
                                    maxline: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textalign: TextAlign.start,
                                    fontstyle: FontStyle.normal,
                                    multilanguage: false),
                                const SizedBox(height: 5),
                                MyText(
                                    color: gray,
                                    multilanguage: false,
                                    text: sections[index].subTitle.toString(),
                                    textalign: TextAlign.center,
                                    fontsize: Dimens.textSmall,
                                    maxline: 1,
                                    fontwaight: FontWeight.w400,
                                    overflow: TextOverflow.ellipsis,
                                    fontstyle: FontStyle.normal),
                              ],
                            ),
                          ),
                          sections[index].viewAll == 1
                              ? InkWell(
                                  onTap: () {
                                    AdHelper.showFullscreenAd(
                                        context, Constant.interstialAdType, () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) {
                                            return PodcastViewAll(
                                              sectionId: sections[index]
                                                      .id
                                                      .toString(),
                                              appbarTitle: sections[index]
                                                      .title
                                                      .toString(),
                                              isTitleMultiLang: false,
                                              screenLayout: sections[index]
                                                      .screenLayout
                                                      .toString(),
                                              sectionType: 2,
                                            );
                                          },
                                        ),
                                      );
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: MyText(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surface,
                                        text: "viewall",
                                        fontsize: Dimens.textMedium,
                                        fontwaight: FontWeight.w500,
                                        maxline: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textalign: TextAlign.right,
                                        fontstyle: FontStyle.normal,
                                        multilanguage: true),
                                  ))
                              : const SizedBox.shrink(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: getRemainingDataHeight(
                          sectionindex: index,
                          screenLayout:
                              sections[index].screenLayout.toString(),
                          sectionList: sections),
                      child: setSectionData(
                          index: index, sectionList: sections),
                    ),
                  ],
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
        );
      } else {
        return const SizedBox.shrink();
      }
    } else {
      return const SizedBox.shrink();
    }
  }

  double getRemainingDataHeight(
      {int? sectionindex,
      String? screenLayout,
      List<podcastsection.Result>? sectionList}) {
    if (screenLayout == "sqaure") {
      return Dimens.squarePodcastHeight;
    } else if (screenLayout == "landscape") {
      return Dimens.landscapPodcastHeight;
    } else if (screenLayout == "portrait") {
      return Dimens.portraitPodcastHeight;
    } else {
      return 0.0;
    }
  }

  Widget setSectionData(
      {required int index, required List<podcastsection.Result>? sectionList}) {
    if ((sectionList?[index].screenLayout.toString() ?? "") == "sqaure") {
      return squarePodcast(index, sectionList);
    } else if ((sectionList?[index].screenLayout.toString() ?? "") ==
        "landscape") {
      return landscapPodcast(index, sectionList);
    } else if ((sectionList?[index].screenLayout.toString() ?? "") ==
        "portrait") {
      return portraitPodcast(index, sectionList);
    } else {
      return const SizedBox.shrink();
    }
  }

/* ================ Podcast Layout's ================ */

  Widget squarePodcast(
      int sectionindex, List<podcastsection.Result>? sectionList) {
    return ListView.separated(
      separatorBuilder: (context, index) => const SizedBox(width: 8),
      scrollDirection: Axis.horizontal,
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
      itemCount: sectionList?[sectionindex].data?.length ?? 0,
      itemBuilder: (BuildContext context, int index) {
        return InkWell(
          onTap: () async {
            final musicdetailProvider =
                Provider.of<MusicDetailProvider>(context, listen: false);
            await musicdetailProvider.getEpisodebyPodcastList(
                sectionList?[sectionindex].data?[index].id.toString() ?? "", 0);

            if (!musicdetailProvider.loading) {
              if (musicdetailProvider.getEpisodeByPodcstModel.status == 200 &&
                  ((musicdetailProvider
                              .getEpisodeByPodcstModel.result?.length ??
                          0) >
                      0)) {
                if (!context.mounted) return;
                Utils.playAudio(
                    context,
                    "podcast",
                    sectionList?[sectionindex].data?[index].isPremium ?? 0,
                    sectionList?[sectionindex].data?[index].isBuy ?? 0,
                    sectionList?[sectionindex]
                            .data?[index]
                            .landscapeImg
                            .toString() ??
                        "",
                    sectionList?[sectionindex].data?[index].title.toString() ??
                        "",
                    '',
                    musicdetailProvider.episodeList?[0].episodeAudio
                            .toString() ??
                        "",
                    "",
                    "",
                    musicdetailProvider.episodeList?[0].id.toString() ?? "",
                    sectionList?[sectionindex].data?[index].id.toString() ?? "",
                    0,
                    musicdetailProvider.episodeList?.toList() ?? []);
              }
            }
          },
          child: SizedBox(
            width: 145,
            height: MediaQuery.sizeOf(context).height,
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: MediaQuery.sizeOf(context).width,
                      height: 145,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: colorPrimary.withValues(alpha: 0.40),
                      ),
                    ),
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: MediaQuery.sizeOf(context).width,
                          height: 140,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: colorPrimary.withValues(alpha: 0.30),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: MyNetworkImage(
                              imgWidth: MediaQuery.sizeOf(context).width,
                              imgHeight: 135,
                              fit: BoxFit.cover,
                              imageUrl: sectionList?[sectionindex]
                                      .data?[index]
                                      .portraitImg
                                      .toString() ??
                                  ""),
                        ),
                      ),
                    ),
                    sectionList?[sectionindex].data?[index].isPremium == 1 &&
                            sectionList?[sectionindex].data?[index].isBuy == 0
                        ? Positioned.fill(
                            top: 8,
                            left: 8,
                            right: 8,
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Container(
                                  width: 30,
                                  height: 30,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(50),
                                    color: colorPrimary,
                                  ),
                                  child: MyImage(
                                      width: 15,
                                      height: 15,
                                      color: white,
                                      imagePath: "ic_primium.png")),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: MyText(
                      color: Theme.of(context).colorScheme.surface,
                      text: sectionList?[sectionindex]
                              .data?[index]
                              .title
                              .toString() ??
                          "",
                      fontsize: Dimens.textMedium,
                      fontwaight: FontWeight.w500,
                      maxline: 2,
                      overflow: TextOverflow.ellipsis,
                      textalign: TextAlign.left,
                      fontstyle: FontStyle.normal),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget landscapPodcast(
      int sectionindex, List<podcastsection.Result>? sectionList) {
    return ListView.separated(
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
        itemCount: sectionList?[sectionindex].data?.length ?? 0,
        itemBuilder: (BuildContext context, int index) {
          return InkWell(
            focusColor: transparent,
            splashColor: transparent,
            hoverColor: transparent,
            highlightColor: transparent,
            onTap: () async {
              final musicdetailProvider =
                  Provider.of<MusicDetailProvider>(context, listen: false);
              await musicdetailProvider.getEpisodebyPodcastList(
                  sectionList?[sectionindex].data?[index].id.toString() ?? "",
                  0);

              if (!musicdetailProvider.loading) {
                if (musicdetailProvider.getEpisodeByPodcstModel.status == 200 &&
                    ((musicdetailProvider
                                .getEpisodeByPodcstModel.result?.length ??
                            0) >
                        0)) {
                  if (!context.mounted) return;
                  Utils.playAudio(
                      context,
                      "podcast",
                      sectionList?[sectionindex].data?[index].isPremium ?? 0,
                      sectionList?[sectionindex].data?[index].isBuy ?? 0,
                      sectionList?[sectionindex]
                              .data?[index]
                              .landscapeImg
                              .toString() ??
                          "",
                      sectionList?[sectionindex]
                              .data?[index]
                              .title
                              .toString() ??
                          "",
                      '',
                      musicdetailProvider
                              .episodeList?[0].episodeAudio
                              .toString() ??
                          "",
                      "",
                      musicdetailProvider.episodeList?[0].description
                              .toString() ??
                          "",
                      musicdetailProvider.episodeList?[0].id.toString() ?? "",
                      sectionList?[sectionindex].data?[index].id.toString() ??
                          "",
                      0,
                      musicdetailProvider.episodeList?.toList() ?? []);
                }
              }
            },
            child: Container(
              width: 185,
              height: 150,
              margin: const EdgeInsets.fromLTRB(5, 0, 5, 0),
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: MyNetworkImage(
                            imgWidth: MediaQuery.sizeOf(context).width,
                            imgHeight: 110,
                            fit: BoxFit.cover,
                            imageUrl: sectionList?[sectionindex]
                                    .data?[index]
                                    .landscapeImg
                                    .toString() ??
                                ""),
                      ),
                      sectionList?[sectionindex].data?[index].isPremium == 1 &&
                              sectionList?[sectionindex].data?[index].isBuy == 0
                          ? Positioned.fill(
                              top: 15,
                              left: 15,
                              right: 15,
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: Container(
                                    width: 30,
                                    height: 30,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(50),
                                      color: colorPrimary,
                                    ),
                                    child: MyImage(
                                        width: 15,
                                        height: 15,
                                        color: white,
                                        imagePath: "ic_primium.png")),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Expanded(
                    child: MyText(
                        color: Theme.of(context).colorScheme.surface,
                        multilanguage: false,
                        text: sectionList?[sectionindex]
                                .data?[index]
                                .title
                                .toString() ??
                            "",
                        textalign: TextAlign.left,
                        fontsize: Dimens.textMedium,
                        inter: 1,
                        maxline: 2,
                        fontwaight: FontWeight.w500,
                        overflow: TextOverflow.ellipsis,
                        fontstyle: FontStyle.normal),
                  ),
                ],
              ),
            ),
          );
        });
  }

  Widget portraitPodcast(
      int sectionindex, List<podcastsection.Result>? sectionList) {
    return ListView.separated(
      separatorBuilder: (context, index) => const SizedBox(width: 8),
      scrollDirection: Axis.horizontal,
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
      itemCount: sectionList?[sectionindex].data?.length ?? 0,
      itemBuilder: (BuildContext context, int index) {
        return InkWell(
          onTap: () async {
            final musicdetailProvider =
                Provider.of<MusicDetailProvider>(context, listen: false);
            await musicdetailProvider.getEpisodebyPodcastList(
                sectionList?[sectionindex].data?[index].id.toString() ?? "", 0);

            if (!musicdetailProvider.loading) {
              if (musicdetailProvider.getEpisodeByPodcstModel.status == 200 &&
                  ((musicdetailProvider
                              .getEpisodeByPodcstModel.result?.length ??
                          0) >
                      0)) {
                if (!context.mounted) return;
                Utils.playAudio(
                    context,
                    "podcast",
                    sectionList?[sectionindex].data?[index].isPremium ?? 0,
                    sectionList?[sectionindex].data?[index].isBuy ?? 0,
                    sectionList?[sectionindex]
                            .data?[index]
                            .landscapeImg
                            .toString() ??
                        "",
                    sectionList?[sectionindex].data?[index].title.toString() ??
                        "",
                    '',
                    musicdetailProvider.episodeList?[0].episodeAudio
                            .toString() ??
                        "",
                    "",
                    "",
                    musicdetailProvider.episodeList?[0].id.toString() ?? "",
                    sectionList?[sectionindex].data?[index].id.toString() ?? "",
                    0,
                    musicdetailProvider.episodeList?.toList() ?? []);
              }
            }
          },
          child: SizedBox(
            width: 135,
            height: MediaQuery.sizeOf(context).height,
            child: Column(
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: MyNetworkImage(
                          imgWidth: MediaQuery.sizeOf(context).width,
                          imgHeight: 170,
                          fit: BoxFit.cover,
                          imageUrl: sectionList?[sectionindex]
                                  .data?[index]
                                  .portraitImg
                                  .toString() ??
                              ""),
                    ),
                    sectionList?[sectionindex].data?[index].isPremium == 1 &&
                            sectionList?[sectionindex].data?[index].isBuy == 0
                        ? Positioned.fill(
                            top: 8,
                            left: 8,
                            right: 8,
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Container(
                                  width: 30,
                                  height: 30,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(50),
                                    color: colorPrimary,
                                  ),
                                  child: MyImage(
                                      width: 15,
                                      height: 15,
                                      color: white,
                                      imagePath: "ic_primium.png")),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: MyText(
                      color: Theme.of(context).colorScheme.surface,
                      text: sectionList?[sectionindex]
                              .data?[index]
                              .title
                              .toString() ??
                          "",
                      fontsize: Dimens.textMedium,
                      inter: 1,
                      fontwaight: FontWeight.w500,
                      maxline: 2,
                      overflow: TextOverflow.ellipsis,
                      textalign: TextAlign.left,
                      fontstyle: FontStyle.normal),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

/* ============================ Podcast Layout's ============================ */

  Widget shimmer() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 25, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomWidget.roundrectborder(height: 8, width: 150),
                  SizedBox(height: 5),
                  CustomWidget.roundrectborder(height: 8, width: 80),
                ],
              ),
              CustomWidget.roundrectborder(height: 5, width: 50),
            ],
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          width: MediaQuery.of(context).size.width,
          height: 180,
          child: ListView.separated(
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
              itemCount: 10,
              itemBuilder: (BuildContext context, int index) {
                return Container(
                  width: 185,
                  height: 150,
                  margin: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CustomWidget.roundrectborder(
                              width: MediaQuery.sizeOf(context).width,
                              height: 110,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      const CustomWidget.roundrectborder(height: 5),
                      const CustomWidget.roundrectborder(height: 5)
                    ],
                  ),
                );
              }),
        ),
        const SizedBox(height: 15),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 25, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomWidget.roundrectborder(height: 10, width: 150),
                  SizedBox(height: 5),
                  CustomWidget.roundrectborder(height: 10, width: 80),
                ],
              ),
              CustomWidget.roundrectborder(height: 10, width: 50),
            ],
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          width: MediaQuery.of(context).size.width,
          height: 180,
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: ListView.separated(
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
                scrollDirection: Axis.horizontal,
                itemCount: 10,
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return Container(
                    alignment: Alignment.center,
                    width: 130,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        CustomWidget.roundrectborder(
                          width: MediaQuery.of(context).size.width,
                          height: 130,
                        ),
                        const SizedBox(height: 8),
                        CustomWidget.roundrectborder(
                          width: MediaQuery.of(context).size.width,
                          height: 5,
                        ),
                        CustomWidget.roundrectborder(
                          width: MediaQuery.of(context).size.width,
                          height: 5,
                        ),
                      ],
                    ),
                  );
                }),
          ),
        ),
        const SizedBox(height: 15),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 25, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomWidget.roundrectborder(height: 10, width: 150),
                  SizedBox(height: 5),
                  CustomWidget.roundrectborder(height: 10, width: 80),
                ],
              ),
              CustomWidget.roundrectborder(height: 10, width: 50),
            ],
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          width: MediaQuery.of(context).size.width,
          height: 180,
          child: ListView.separated(
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
              itemCount: 10,
              itemBuilder: (BuildContext context, int index) {
                return Container(
                  width: 185,
                  height: 150,
                  margin: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CustomWidget.roundrectborder(
                              width: MediaQuery.sizeOf(context).width,
                              height: 110,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      const CustomWidget.roundrectborder(height: 5),
                      const CustomWidget.roundrectborder(height: 5)
                    ],
                  ),
                );
              }),
        ),
      ],
    );
  }

  Widget _buildMusicPanel(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: currentlyPlaying,
      builder: (BuildContext context, AudioPlayer? audioObject, Widget? child) {
        if (audioObject?.audioSource != null) {
          return const MusicDetails(
            ishomepage: true,
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}
