import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:myBonus/model/liveeventmodel.dart';
import 'package:myBonus/music/musicdetails.dart';
import 'package:myBonus/pages/login.dart';
import 'package:myBonus/pages/nodata.dart';
import 'package:myBonus/provider/liveeventsprovider.dart';
import 'package:myBonus/subscription/allpayment.dart';
import 'package:myBonus/utils/color.dart';
import 'package:myBonus/utils/constant.dart';
import 'package:myBonus/utils/customwidget.dart';
import 'package:myBonus/utils/dimens.dart';
import 'package:myBonus/utils/utils.dart';
import 'package:myBonus/widget/abidjan_bokeh_card.dart';
import 'package:myBonus/widget/abidjan_header.dart';
import 'package:myBonus/widget/abidjan_pill_filter.dart';
import 'package:myBonus/widget/liveneon_bokeh_card.dart';
import 'package:myBonus/widget/liveneon_buttons.dart';
import 'package:myBonus/widget/liveneon_header.dart';
import 'package:myBonus/widget/liveneon_pill_filter.dart';
import 'package:myBonus/widget/mynetworkimg.dart';
import 'package:myBonus/widget/mytext.dart';

class LiveEvent extends StatefulWidget {
  final VoidCallback? onBack;
  const LiveEvent({super.key, this.onBack});

  @override
  State<LiveEvent> createState() => _LiveEventState();
}

class _LiveEventState extends State<LiveEvent> {
  late LiveEventProvider liveEventProvider;
  final ScrollController categoryController = ScrollController();
  late ScrollController _scrollController;

  @override
  void initState() {
    liveEventProvider = Provider.of<LiveEventProvider>(context, listen: false);
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    _fetchData(0);
    super.initState();
  }

  Future<void> _scrollListener() async {
    if (!_scrollController.hasClients) return;
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange &&
        (liveEventProvider.currentPage ?? 0) <
            (liveEventProvider.totalPage ?? 0)) {
      liveEventProvider.setLoadMore(true);
      _fetchData(liveEventProvider.currentPage ?? 0);
    }
  }

  Future<void> _fetchData(int? nextPage) async {
    printLog("isMorePage  ======> ${liveEventProvider.morePage}");
    printLog("currentPage ======> ${liveEventProvider.currentPage}");
    printLog("totalPage   ======> ${liveEventProvider.totalPage}");
    printLog("nextpage   ======> $nextPage");
    printLog("Call MyCourse");
    printLog("Pageno:== ${(nextPage ?? 0) + 1}");
    await liveEventProvider.getLiveEventList((nextPage ?? 0) + 1);
    liveEventProvider.setLoadMore(false);
  }

  @override
  void dispose() {
    liveEventProvider.clearProvider();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isNight = Theme.of(context).brightness == Brightness.dark;
    return isNight ? _buildLiveNeonScaffold() : _buildAbidjanScaffold();
  }

  // LIVE NEON (night theme): same structure as ABIDJAN (flat header, single
  // cosmetic filter pill, featured card + "Tendances" strip) recolored for
  // the neon palette. Tap-dispatch logic (_handleLiveEventTap) and data
  // fetching are fully shared with day.
  Widget _buildLiveNeonScaffold() {
    return Scaffold(
      backgroundColor: liveNeonBg,
      body: Container(
        decoration: liveNeonBackgroundDecoration(),
        child: Column(
          children: [
            LiveNeonHeader(
              title: "liveevents",
              showBack: true,
              onBack: () => widget.onBack?.call(),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: LiveNeonPillFilterRow(
                options: const ["Tous"],
                selected: "Tous",
                onSelected: (_) {},
              ),
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
                  liveEventProvider.clearProvider();
                  _fetchData(0);
                },
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(0, 5, 0, 160),
                  scrollDirection: Axis.vertical,
                  physics: const BouncingScrollPhysics(),
                  child: Consumer<LiveEventProvider>(
                    builder: (context, liveeventprovider, child) {
                      if (liveeventprovider.loading &&
                          !liveeventprovider.loadMore) {
                        return buildLiveEventListShimmer();
                      }
                      return Column(
                        children: [
                          _buildLiveNeonFeaturedCard(),
                          _buildLiveNeonTrendingStrip(),
                          buildLiveEventList(),
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

  // ABIDJAN (day theme): flat header, single cosmetic filter pill (decision:
  // LiveEventModel has no category field, so no real filtering is possible),
  // featured card + "Tendances" strip built from the same real event data
  // and the same shared tap-dispatch logic as the grid below.
  Widget _buildAbidjanScaffold() {
    return Scaffold(
      backgroundColor: homeAccueilBg(context),
      body: Column(
        children: [
          AbidjanHeader(
            title: "liveevents",
            showBack: true,
            onBack: () => widget.onBack?.call(),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AbidjanPillFilterRow(
              options: const ["Tous"],
              selected: "Tous",
              onSelected: (_) {},
            ),
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
                liveEventProvider.clearProvider();
                _fetchData(0);
              },
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(0, 5, 0, 160),
                scrollDirection: Axis.vertical,
                physics: const BouncingScrollPhysics(),
                child: Consumer<LiveEventProvider>(
                  builder: (context, liveeventprovider, child) {
                    if (liveeventprovider.loading &&
                        !liveeventprovider.loadMore) {
                      return buildLiveEventListShimmer();
                    }
                    return Column(
                      children: [
                        _buildAbidjanFeaturedCard(),
                        _buildAbidjanTrendingStrip(),
                        buildLiveEventList(),
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

  Future<void> _handleLiveEventTap(int index) async {
    if (Constant.userID == null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return const Login();
          },
        ),
      );
      return;
    }
    final item = liveEventProvider.liveEventList?[index];
    if (item == null) return;
    if (item.isPaid == 1 && item.isJoin == 0) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return AllPayment(
              payType: 'liveevent',
              itemId: item.id.toString(),
              price: item.price.toString(),
              itemTitle: item.title.toString(),
              typeId: '',
              contentType: item.type.toString(),
              productPackage: '',
              currency: '',
            );
          },
        ),
      );
    } else {
      if (item.type == 1) {
        /* Audio */
        musicManager.playSingleSong(
          item.id.toString(),
          item.title.toString(),
          item.link.toString(),
          item.landscapeImg.toString(),
          "",
        );
      } else {
        /* Video */
        Utils.openPlayer(
            context: context,
            videoId: item.id.toString(),
            videoUrl: item.link.toString(),
            vUploadType: "external",
            videoThumb: item.landscapeImg.toString(),
            stoptime: "",
            iscontinueWatching: false);
      }
    }
  }

  Widget _buildAbidjanFeaturedCard() {
    final list = liveEventProvider.liveEventList;
    if (list == null || list.isEmpty) return const SizedBox.shrink();
    final Result item = list.first;
    final bool isPaidLocked = item.isPaid == 1 && item.isJoin == 0;
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
        onTap: () => _handleLiveEventTap(0),
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
                                  isPaidLocked
                                      ? "${Constant.currencySymbol}${item.price ?? ""}"
                                      : "Regarder",
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

  Widget _buildAbidjanTrendingStrip() {
    final list = liveEventProvider.liveEventList;
    if (list == null || list.length < 2) return const SizedBox.shrink();
    final items = list.length > 8 ? list.sublist(0, 8) : list;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: MyText(
            color: black,
            text: "Tendances",
            multilanguage: false,
            inter: 4,
            fontsize: Dimens.textBig,
            fontwaight: FontWeight.w700,
            maxline: 1,
            textalign: TextAlign.left,
            fontstyle: FontStyle.normal,
          ),
        ),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              final originalIndex = list.indexOf(item);
              final bool isPaidLocked =
                  item.isPaid == 1 && item.isJoin == 0;
              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _handleLiveEventTap(originalIndex),
                child: SizedBox(
                  width: 150,
                  child: AbidjanBokehCard(
                    index: index,
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            item.title?.toString() ?? "",
                            style: const TextStyle(
                              color: white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isPaidLocked
                                ? "${Constant.currencySymbol}${item.price ?? ""}"
                                : "Gratuit",
                            style: TextStyle(
                              color: white.withValues(alpha: 0.85),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  // LIVE NEON (night theme) featured card. Same shared _handleLiveEventTap
  // logic as ABIDJAN's version — only the palette differs.
  Widget _buildLiveNeonFeaturedCard() {
    final list = liveEventProvider.liveEventList;
    if (list == null || list.isEmpty) return const SizedBox.shrink();
    final Result item = list.first;
    final bool isPaidLocked = item.isPaid == 1 && item.isJoin == 0;
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
        onTap: () => _handleLiveEventTap(0),
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
                            label: isPaidLocked
                                ? "${Constant.currencySymbol}${item.price ?? ""}"
                                : "Regarder",
                            onTap: () => _handleLiveEventTap(0),
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

  Widget _buildLiveNeonTrendingStrip() {
    final list = liveEventProvider.liveEventList;
    if (list == null || list.length < 2) return const SizedBox.shrink();
    final items = list.length > 8 ? list.sublist(0, 8) : list;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: MyText(
            color: white,
            text: "Tendances",
            multilanguage: false,
            inter: 4,
            fontsize: Dimens.textBig,
            fontwaight: FontWeight.w700,
            maxline: 1,
            textalign: TextAlign.left,
            fontstyle: FontStyle.normal,
          ),
        ),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              final originalIndex = list.indexOf(item);
              final bool isPaidLocked =
                  item.isPaid == 1 && item.isJoin == 0;
              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _handleLiveEventTap(originalIndex),
                child: SizedBox(
                  width: 150,
                  child: LiveNeonBokehCard(
                    index: index,
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            item.title?.toString() ?? "",
                            style: const TextStyle(
                              color: white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isPaidLocked
                                ? "${Constant.currencySymbol}${item.price ?? ""}"
                                : "Gratuit",
                            style: TextStyle(
                              color: white.withValues(alpha: 0.85),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget buildLiveEventList() {
    return Consumer<LiveEventProvider>(
        builder: (context, liveeventprovider, child) {
      if (liveeventprovider.loading && !liveeventprovider.loadMore) {
        return buildLiveEventListShimmer();
      } else {
        if (liveeventprovider.liveEventModel.status == 200 &&
            liveeventprovider.liveEventList != null) {
          if ((liveeventprovider.liveEventList?.length ?? 0) > 0) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildLiveEventListItem(),
                if (liveeventprovider.loadMore)
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

  Widget buildLiveEventListItem() {
    return AlignedGridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 20,
      crossAxisSpacing: 15,
      itemCount: liveEventProvider.liveEventList?.length ?? 0,
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 8),
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        return InkWell(
          focusColor: transparent,
          splashColor: transparent,
          hoverColor: transparent,
          highlightColor: transparent,
          onTap: () => _handleLiveEventTap(index),
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
                    imageUrl: liveEventProvider
                            .liveEventList?[index].portraitImg
                            .toString() ??
                        ""),
              ),
              const SizedBox(height: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: colorPrimary.withValues(alpha: 0.09),
                    ),
                    child: Row(
                      children: [
                        MyText(
                          color: colorPrimary,
                          inter: 1,
                          text: Utils.dateformat(DateTime.parse(
                              liveEventProvider.liveEventList?[index].createdAt
                                      .toString() ??
                                  "")),
                          fontsize: Dimens.textSmall,
                          fontwaight: FontWeight.w600,
                          maxline: 1,
                          overflow: TextOverflow.ellipsis,
                          textalign: TextAlign.center,
                          fontstyle: FontStyle.normal,
                        ),
                        const SizedBox(width: 5),
                        MyText(
                          color: colorPrimary,
                          inter: 1,
                          text: "onwards",
                          fontsize: Dimens.textSmall,
                          multilanguage: true,
                          fontwaight: FontWeight.w600,
                          maxline: 1,
                          overflow: TextOverflow.ellipsis,
                          textalign: TextAlign.center,
                          fontstyle: FontStyle.normal,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  MyText(
                    color: Theme.of(context).colorScheme.surface,
                    inter: 1,
                    text: liveEventProvider.liveEventList?[index].title
                            .toString() ??
                        "",
                    fontsize: Dimens.textSmall,
                    fontwaight: FontWeight.w600,
                    maxline: 1,
                    overflow: TextOverflow.ellipsis,
                    textalign: TextAlign.left,
                    fontstyle: FontStyle.normal,
                  ),
                  const SizedBox(height: 4),
                  if (liveEventProvider.liveEventList?[index].isPaid
                              .toString() ==
                          "1" &&
                      liveEventProvider.liveEventList?[index].isJoin
                              .toString() ==
                          "0")
                    MyText(
                      color: colorPrimary,
                      inter: 1,
                      text:
                          "${Constant.currencySymbol}${liveEventProvider.liveEventList?[index].price.toString() ?? ""}",
                      fontsize: Dimens.textTitle,
                      fontwaight: FontWeight.w600,
                      maxline: 2,
                      overflow: TextOverflow.ellipsis,
                      textalign: TextAlign.left,
                      fontstyle: FontStyle.normal,
                    )
                  else if (liveEventProvider.liveEventList?[index].isPaid
                              .toString() ==
                          "1" &&
                      liveEventProvider.liveEventList?[index].isJoin
                              .toString() ==
                          "1")
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

  Widget buildLiveEventListShimmer() {
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
