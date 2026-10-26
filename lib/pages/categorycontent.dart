import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:myBonus/model/categorycontentmodel.dart';
import 'package:myBonus/model/sectionlistmodel.dart' as section;
import 'package:myBonus/music/musicdetails.dart';
import 'package:myBonus/pages/home.dart';
import 'package:myBonus/pages/nodata.dart';
import 'package:myBonus/pages/radiobyid.dart';
import 'package:myBonus/provider/musicdetailprovider.dart';
import 'package:myBonus/utils/color.dart';
import 'package:myBonus/utils/customwidget.dart';
import 'package:myBonus/utils/dimens.dart';
import 'package:myBonus/utils/utils.dart';
import 'package:myBonus/webservice/apiservices.dart';
import 'package:myBonus/widget/abidjan_header.dart';
import 'package:myBonus/widget/myappbar.dart';
import 'package:myBonus/widget/mynetworkimg.dart';
import 'package:myBonus/widget/mytext.dart';

// A rubrique (category) — categories are shared by songs, podcasts, videos
// and series, so its page shows one row per kind of content it holds.
// Tapping reuses the existing behaviors: songs play (with the usual
// premium checks), a podcast plays its first episode, a series opens its
// episode list and a video plays.
class CategoryContentPage extends StatefulWidget {
  final String categoryId;
  final String title;

  const CategoryContentPage({
    required this.categoryId,
    required this.title,
    super.key,
  });

  @override
  State<CategoryContentPage> createState() => _CategoryContentPageState();
}

class _CategoryContentPageState extends State<CategoryContentPage> {
  bool _loading = true;
  CategoryContent? _content;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final model = await ApiService().categoryContent(widget.categoryId);
      if (!mounted) return;
      setState(() {
        _content = model.status == 200 ? model.result : null;
        _loading = false;
      });
    } catch (e) {
      printLog('CategoryContentPage load error: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
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
              Expanded(child: _buildBody(isNight)),
              Utils.showBannerAd(context),
            ],
          ),
        ),
        buildMusicPanel(context),
      ],
    );
  }

  Widget _buildBody(bool isNight) {
    if (_loading) return _buildShimmer();
    final content = _content;
    if (content == null ||
        (content.songs.isEmpty &&
            content.podcasts.isEmpty &&
            content.videos.isEmpty)) {
      return const NoData(text: "", subTitle: "");
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 10, bottom: playerMinHeight + 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (content.songs.isNotEmpty)
            _buildRow(
              isNight: isNight,
              title: "Titres",
              count: content.songCount,
              onSeeAll: content.songCount > content.songs.length
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RadioById(
                            itemId: widget.categoryId,
                            viewType: "category",
                            title: widget.title,
                            languagegId: "",
                          ),
                        ),
                      )
                  : null,
              itemCount: content.songs.length,
              itemBuilder: (index) => _buildTile(
                isNight: isNight,
                imageUrl: content.songs[index].image?.toString() ?? "",
                title: content.songs[index].name?.toString() ?? "",
                caption: content.songs[index].artistName?.toString() ?? "",
                square: true,
                onTap: () => _playSong(content.songs, index),
              ),
            ),
          if (content.podcasts.isNotEmpty)
            _buildRow(
              isNight: isNight,
              title: "Podcasts",
              count: content.podcastCount,
              itemCount: content.podcasts.length,
              itemBuilder: (index) => _buildTile(
                isNight: isNight,
                imageUrl: content.podcasts[index].portraitImg?.toString() ?? "",
                title: content.podcasts[index].title?.toString() ?? "",
                caption: "Podcast",
                onTap: () => _playPodcast(content.podcasts[index]),
              ),
            ),
          if (content.videos.isNotEmpty)
            _buildRow(
              isNight: isNight,
              title: "Vidéos & séries",
              count: content.videoCount,
              itemCount: content.videos.length,
              itemBuilder: (index) {
                final item = content.videos[index];
                final int episodes = item.episodeCount ?? 0;
                return _buildTile(
                  isNight: isNight,
                  imageUrl: item.portraitImg?.toString() ?? "",
                  title: item.title?.toString() ?? "",
                  caption: item.isSeries == 1
                      ? "Série · $episodes épisode${episodes > 1 ? 's' : ''}"
                      : "Vidéo",
                  onTap: () => Utils.openVideoCatalogItem(context, item),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRow({
    required bool isNight,
    required String title,
    required int count,
    required int itemCount,
    required Widget Function(int index) itemBuilder,
    VoidCallback? onSeeAll,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: MyText(
                  color: isNight ? white : black,
                  text: "$title ($count)",
                  multilanguage: false,
                  inter: isNight ? 1 : 4,
                  fontsize: Dimens.textBig,
                  fontwaight: FontWeight.w700,
                  maxline: 1,
                  overflow: TextOverflow.ellipsis,
                  textalign: TextAlign.left,
                  fontstyle: FontStyle.normal,
                ),
              ),
              if (onSeeAll != null)
                InkWell(
                  onTap: onSeeAll,
                  child: MyText(
                    color: colorPrimary,
                    text: "seeallhome",
                    multilanguage: true,
                    fontsize: Dimens.textMedium,
                    fontwaight: FontWeight.w600,
                    maxline: 1,
                    textalign: TextAlign.right,
                    fontstyle: FontStyle.normal,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 215,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            itemCount: itemCount,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) => itemBuilder(index),
          ),
        ),
      ],
    );
  }

  // Portrait cover by default; square for songs (their artwork is square).
  Widget _buildTile({
    required bool isNight,
    required String imageUrl,
    required String title,
    required String caption,
    required VoidCallback onTap,
    bool square = false,
  }) {
    const double width = 125;
    final double height = square ? width : 165;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: MyNetworkImage(
                imgWidth: width,
                imgHeight: height,
                fit: BoxFit.cover,
                imageUrl: imageUrl,
              ),
            ),
            const SizedBox(height: 6),
            MyText(
              color: isNight ? white : black,
              text: title,
              multilanguage: false,
              inter: 1,
              fontsize: Dimens.textSmall,
              fontwaight: FontWeight.w600,
              maxline: 1,
              overflow: TextOverflow.ellipsis,
              textalign: TextAlign.left,
              fontstyle: FontStyle.normal,
            ),
            if (caption.isNotEmpty)
              MyText(
                color: colorPrimary,
                text: caption,
                multilanguage: false,
                inter: 1,
                fontsize: Dimens.textExtraSmall,
                fontwaight: FontWeight.w600,
                maxline: 1,
                overflow: TextOverflow.ellipsis,
                textalign: TextAlign.left,
                fontstyle: FontStyle.normal,
              ),
          ],
        ),
      ),
    );
  }

  // Same call as the home song tiles (premium/subscription checks included).
  void _playSong(List<section.Datum> songs, int index) {
    final song = songs[index];
    Utils.playAudio(
      context,
      "radio",
      song.isPremium ?? 0,
      song.isBuy ?? 0,
      song.image?.toString() ?? "",
      song.name?.toString() ?? "",
      'category',
      song.songUrl?.toString() ?? "",
      song.languageName?.toString() ?? "",
      song.artistName?.toString() ?? "",
      song.id?.toString() ?? "",
      "",
      index,
      songs,
    );
  }

  // Same as the home podcast tiles: plays the podcast's first episode.
  Future<void> _playPodcast(section.Datum podcast) async {
    final provider = Provider.of<MusicDetailProvider>(context, listen: false);
    await provider.getEpisodebyPodcastList(podcast.id?.toString() ?? "", 0);
    if (!mounted || provider.loading) return;
    final episodes = provider.episodeList ?? [];
    if (provider.getEpisodeByPodcstModel.status != 200 || episodes.isEmpty) {
      return;
    }
    Utils.playAudio(
      context,
      "podcast",
      podcast.isPremium ?? 0,
      podcast.isBuy ?? 0,
      podcast.landscapeImg?.toString() ?? "",
      podcast.title?.toString() ?? "",
      '',
      episodes[0].episodeAudio?.toString() ?? "",
      "",
      "",
      episodes[0].id?.toString() ?? "",
      podcast.id?.toString() ?? "",
      0,
      episodes.toList(),
    );
  }

  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var row = 0; row < 2; row++) ...[
            const CustomWidget.roundrectborder(width: 140, height: 18),
            const SizedBox(height: 10),
            Row(
              children: [
                for (var i = 0; i < 3; i++)
                  const Expanded(
                    child: CustomWidget.roundcorner(height: 160),
                  ),
              ],
            ),
            const SizedBox(height: 20),
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
        }
        return const SizedBox.shrink();
      },
    );
  }
}
