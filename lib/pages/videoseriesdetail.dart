import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:myBonus/model/liveeventmodel.dart' as liveevent;
import 'package:myBonus/music/musicdetails.dart';
import 'package:myBonus/pages/home.dart';
import 'package:myBonus/pages/nodata.dart';
import 'package:myBonus/provider/videoseriesprovider.dart';
import 'package:myBonus/utils/color.dart';
import 'package:myBonus/utils/constant.dart';
import 'package:myBonus/utils/customwidget.dart';
import 'package:myBonus/utils/dimens.dart';
import 'package:myBonus/utils/utils.dart';
import 'package:myBonus/widget/abidjan_header.dart';
import 'package:myBonus/widget/myappbar.dart';
import 'package:myBonus/widget/mynetworkimg.dart';
import 'package:myBonus/widget/mytext.dart';

// A series is just a header — its episodes are ordinary video rows (same
// Result/tap-dispatch as liveevent.dart), fetched as one list via
// get_video_series_detail rather than a dedicated episode screen.
class VideoSeriesDetail extends StatefulWidget {
  final int seriesId;
  final String title;
  final String? landscapeImg;

  const VideoSeriesDetail({
    required this.seriesId,
    required this.title,
    this.landscapeImg,
    super.key,
  });

  @override
  State<VideoSeriesDetail> createState() => _VideoSeriesDetailState();
}

class _VideoSeriesDetailState extends State<VideoSeriesDetail> {
  late VideoSeriesProvider videoSeriesProvider;

  @override
  void initState() {
    videoSeriesProvider =
        Provider.of<VideoSeriesProvider>(context, listen: false);
    videoSeriesProvider.getSeriesDetail(widget.seriesId);
    super.initState();
  }

  @override
  void dispose() {
    videoSeriesProvider.clearDetail();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isNight = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Scaffold(
          backgroundColor: homeAccueilBg(context),
          body: Column(
            children: [
              isNight
                  ? MyAppbar(
                      title: widget.title,
                      isSimpleappbar: 1,
                      isMultiLang: false,
                      icon: "back.png",
                      useAccueilTheme: true,
                      onBack: () => Navigator.pop(context),
                    )
                  : AbidjanHeader(
                      title: widget.title,
                      multilanguage: false,
                      showBack: true,
                      onBack: () => Navigator.pop(context),
                    ),
              Expanded(
                child: Consumer<VideoSeriesProvider>(
                  builder: (context, provider, child) {
                    if (provider.detailLoading) {
                      return _buildShimmer();
                    }
                    final detail = provider.seriesDetail;
                    final episodes = detail?.episodes ?? [];
                    if (detail == null) {
                      return const NoData(text: "", subTitle: "");
                    }
                    return SingleChildScrollView(
                      padding:
                          const EdgeInsets.only(bottom: playerMinHeight),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBanner(detail.landscapeImg),
                          if ((detail.description ?? "").isNotEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 15, 20, 5),
                              child: MyText(
                                color: Theme.of(context).colorScheme.surface,
                                text: detail.description.toString(),
                                multilanguage: false,
                                inter: 1,
                                fontsize: Dimens.textMedium,
                                fontwaight: FontWeight.w400,
                                maxline: 10,
                                textalign: TextAlign.left,
                                fontstyle: FontStyle.normal,
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
                            child: MyText(
                              color: Theme.of(context).colorScheme.surface,
                              text: "Épisodes",
                              multilanguage: false,
                              inter: isNight ? 1 : 4,
                              fontsize: Dimens.textBig,
                              fontwaight: FontWeight.w700,
                              maxline: 1,
                              textalign: TextAlign.left,
                              fontstyle: FontStyle.normal,
                            ),
                          ),
                          if (episodes.isEmpty)
                            const NoData(text: "", subTitle: "")
                          else
                            ...episodes
                                .map((episode) => _buildEpisodeRow(episode)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Utils.showBannerAd(context),
            ],
          ),
        ),
        buildMusicPanel(context),
      ],
    );
  }

  Widget _buildBanner(String? landscapeImg) {
    final image = (landscapeImg ?? "").isNotEmpty
        ? landscapeImg
        : widget.landscapeImg;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: MyNetworkImage(
            imgWidth: double.infinity,
            imgHeight: double.infinity,
            fit: BoxFit.cover,
            imageUrl: image ?? "",
          ),
        ),
      ),
    );
  }

  Widget _buildEpisodeRow(liveevent.Result episode) {
    final bool isPaidLocked = episode.isPaid == 1 && episode.isJoin == 0;
    return InkWell(
      onTap: () => Utils.handleVideoContentTap(context, episode),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 110,
                height: 70,
                child: MyNetworkImage(
                  imgWidth: 110,
                  imgHeight: 70,
                  fit: BoxFit.cover,
                  imageUrl: episode.landscapeImg?.toString() ?? "",
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(
                    color: Theme.of(context).colorScheme.surface,
                    text: episode.episodeNumber != null
                        ? "Épisode ${episode.episodeNumber} — ${episode.title ?? ""}"
                        : episode.title?.toString() ?? "",
                    multilanguage: false,
                    inter: 1,
                    fontsize: Dimens.textMedium,
                    fontwaight: FontWeight.w600,
                    maxline: 2,
                    overflow: TextOverflow.ellipsis,
                    textalign: TextAlign.left,
                    fontstyle: FontStyle.normal,
                  ),
                  const SizedBox(height: 4),
                  MyText(
                    color: isPaidLocked
                        ? colorPrimary
                        : Theme.of(context).colorScheme.surface,
                    text: isPaidLocked
                        ? "${Constant.currencySymbol}${episode.price ?? ""}"
                        : "Gratuit",
                    multilanguage: false,
                    inter: 1,
                    fontsize: Dimens.textSmall,
                    fontwaight: FontWeight.w600,
                    maxline: 1,
                    textalign: TextAlign.left,
                    fontstyle: FontStyle.normal,
                  ),
                ],
              ),
            ),
            Icon(Icons.play_circle_fill, color: colorPrimary, size: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomWidget.roundrectborder(
            width: MediaQuery.of(context).size.width,
            height: 180,
            shapeBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(height: 15),
          for (var i = 0; i < 3; i++) ...[
            CustomWidget.roundrectborder(
              width: MediaQuery.of(context).size.width,
              height: 70,
              shapeBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget buildMusicPanel(BuildContext context) {
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
