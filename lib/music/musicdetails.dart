import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:miniplayer/miniplayer.dart';
import 'package:provider/provider.dart';
import 'package:myBonus/pages/home.dart';
import 'package:myBonus/pages/login.dart';
import 'package:myBonus/provider/musicdetailprovider.dart';
import 'package:myBonus/subscription/subscription.dart';
import 'package:myBonus/utils/adhelper.dart';
import 'package:myBonus/utils/color.dart';
import 'package:myBonus/utils/constant.dart';
import 'package:myBonus/music/musicmanager.dart';
import 'package:myBonus/utils/dimens.dart';
import 'package:myBonus/utils/utils.dart';
import 'package:myBonus/widget/musicutils.dart';
import 'package:myBonus/widget/myimage.dart';
import 'package:myBonus/widget/mynetworkimg.dart';
import 'package:myBonus/widget/mytext.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import 'package:rxdart/rxdart.dart';
import 'package:text_scroll/text_scroll.dart';

AudioPlayer audioPlayer = AudioPlayer();
late MusicManager musicManager;

// Configuration responsive pour les images lect-*
// Les breakpoints sont exprimés en diagonale d'écran (pouces).
// Approximation utilisée: diagonalInches = sqrt(width^2 + height^2) / 160
class LectResponsiveConfig {
  // Breakpoints en pouces (modifiable ici)
  static const double smallDiagonalInches = 6.2; // < 6.2" => petit
  static const double largeDiagonalInches = 6.5; // > 6.5" => grand

  // Marges globales (modifiable ici)
  static const double horizontalMargin = 16.0;
  static const double verticalMargin = 12.0;

  // Petits écrans
  static const double smallBrandRatio = 0.35;
  static const double smallBrandMin = 160.0;
  static const double smallBrandMax = 200.0;

  static const double smallHeadRatio = 0.25;
  static const double smallHeadMin = 120.0;
  static const double smallHeadMax = 140.0;

  static const double smallNotesRatio = 0.50;
  static const double smallNotesMin = 160.0;
  static const double smallNotesMax = 300.0;

  static const double smallBrandOffsetRatio = 0.15;
  static const double smallBrandOffsetMin = 50.0;
  static const double smallBrandOffsetMax = 100.0;

  static const double smallHeadOffsetRatio = 0.10;
  static const double smallHeadOffsetMin = 60.0;
  static const double smallHeadOffsetMax = 70.0;

  static const double smallNotesOffsetRatio = 0.12;
  static const double smallNotesOffsetMin = 40.0;
  static const double smallNotesOffsetMax = 90.0;

  // Moyens écrans
  static const double mediumBrandRatio = 0.40;
  static const double mediumBrandMin = 180.0;
  static const double mediumBrandMax = 340.0;

  static const double mediumHeadRatio = 0.30;
  static const double mediumHeadMin = 160.0;
  static const double mediumHeadMax = 260.0;

  static const double mediumNotesRatio = 0.58;
  static const double mediumNotesMin = 260.0;
  static const double mediumNotesMax = 480.0;

  // Offsets ajustés pour écran moyen
  static const double mediumBrandOffsetRatio = 0.18;
  static const double mediumBrandOffsetMin = 80.0;
  static const double mediumBrandOffsetMax = 160.0;

  static const double mediumHeadOffsetRatio = 0.13;
  static const double mediumHeadOffsetMin = 60.0;
  static const double mediumHeadOffsetMax = 120.0;

  static const double mediumNotesOffsetRatio = 0.15;
  static const double mediumNotesOffsetMin = 70.0;
  static const double mediumNotesOffsetMax = 150.0;

  // Grands écrans
  static const double largeBrandRatio = 0.50;
  static const double largeBrandMin = 300.0;
  static const double largeBrandMax = 800.0;

  static const double largeHeadRatio = 0.35;
  static const double largeHeadMin = 220.0;
  static const double largeHeadMax = 420.0;

  static const double largeNotesRatio = 0.65;
  static const double largeNotesMin = 360.0;
  static const double largeNotesMax = 900.0;

  static const double largeBrandOffsetRatio = 0.20;
  static const double largeBrandOffsetMin = 90.0;
  static const double largeBrandOffsetMax = 220.0;

  static const double largeHeadOffsetRatio = 0.14;
  static const double largeHeadOffsetMin = 120.0;
  static const double largeHeadOffsetMax = 160.0;

  static const double largeNotesOffsetRatio = 0.16;
  static const double largeNotesOffsetMin = 100.0;
  static const double largeNotesOffsetMax = 220.0;

  // Hauteurs pour la zone slideshow (pub)
  static const double pubSlideshowHeightSmall = 130.0;
  static const double pubSlideshowHeightMedium = 180.0;
  static const double pubSlideshowHeightLarge = 200.0;
}

Stream<PositionData> get positionDataStream {
  return Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
          audioPlayer.positionStream,
          audioPlayer.bufferedPositionStream,
          audioPlayer.durationStream,
          (position, bufferedPosition, duration) => PositionData(
              position, bufferedPosition, duration ?? Duration.zero))
      .asBroadcastStream();
}

final ValueNotifier<double> playerExpandProgress =
    ValueNotifier(playerMinHeight);

final MiniplayerController miniPlayerController = MiniplayerController();

class MusicDetails extends StatefulWidget {
  final bool ishomepage;
  const MusicDetails({super.key, required this.ishomepage});

  @override
  State<MusicDetails> createState() => _MusicDetailsState();
}

class _MusicDetailsState extends State<MusicDetails>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late MusicDetailProvider musicDetailProvider;
  final commentController = TextEditingController();
  late AnimationController _bounceController;
  late AnimationController _notesController;

  // zoneLectPub slideshow settings (reglables)
  final String _pubAssetsDir = 'assets/images/pubs/';
  final bool _pubLoop = true;
  final Duration _pubDisplayDuration = const Duration(seconds: 12);
  final Duration _pubFadeDuration = const Duration(seconds: 1);

  List<String> _pubImages = [];
  int _pubIndex = 0;
  Timer? _pubTimer;

  // Animation types for notesLect
  static const String animationFlutter =
      'flutter'; // Scintillement (recommandé)
  static const String animationPulse = 'pulse'; // Pulse d'opacité
  static const String animationRotatePulse = 'rotate_pulse'; // Rotation + Pulse
  static const String animationFloat = 'float'; // Float (montée/descente)
  static const String animationScale = 'scale'; // Scale (agrandissement)

  // Sélection d'animation (à modifier ici)
  String notesAnimationType = animationScale; // Par défaut

  @override
  void initState() {
    musicDetailProvider =
        Provider.of<MusicDetailProvider>(context, listen: false);
    super.initState();
    ambiguate(WidgetsBinding.instance)?.addObserver(this);
    SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(statusBarColor: black));

    // Initialize bounce animation controller
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 250), // Durée réglable en ms
      vsync: this,
    );

    // Initialize notes animation controller
    _notesController = AnimationController(
      duration: const Duration(milliseconds: 600), // Durée réglable en ms
      vsync: this,
    );

    _initPubImages();
  }

  @override
  void dispose() {
    ambiguate(WidgetsBinding.instance)?.removeObserver(this);
    _bounceController.dispose();
    _notesController.dispose();
    _pubTimer?.cancel();
    super.dispose();
  }

  Future<void> _initPubImages() async {
    try {
      printLog('=== START _initPubImages ===');

      // List of pub image filenames (hardcoded or discovered)
      // This is more reliable than AssetManifest.json in debug mode
      List<String> pubImageNames = [];

      // Method 1: Try AssetManifest first (works in release)
      try {
        final manifestJson = await rootBundle.loadString('AssetManifest.json');
        final Map<String, dynamic> manifestMap = json.decode(manifestJson);
        printLog(
            '📦 AssetManifest loaded, total keys: ${manifestMap.keys.length}');

        pubImageNames = manifestMap.keys
            .where((key) => key.startsWith(_pubAssetsDir))
            .toList()
          ..sort();

        printLog('✅ From AssetManifest: ${pubImageNames.length} images found');
      } catch (e) {
        printLog('⚠️ AssetManifest failed: $e - Trying direct file loading');

        // Method 2: Try direct asset loading if AssetManifest fails
        // Create the list manually based on known patterns
        // This is a fallback for debug mode
        List<String> possibleImages = [
          'assets/images/pubs/pubs-didib-okalamar-1.jpg',
          'assets/images/pubs/pubs-djamo-1.jpg',
          'assets/images/pubs/pubs-garagistes-chateau-de-france-1.jpg',
          'assets/images/pubs/pubs-meiway-chateau-bernard-1.jpg',
          'assets/images/pubs/pubs-nsia-1.jpg',
          'assets/images/pubs/pubs-sgci-1.jpg',
          'assets/images/pubs/pubs-wave-1.jpg',
        ];

        // Verify each image exists
        for (String imagePath in possibleImages) {
          try {
            await rootBundle.load(imagePath);
            pubImageNames.add(imagePath);
            printLog('✓ Found: $imagePath');
          } catch (e) {
            printLog('✗ Not found: $imagePath');
          }
        }
      }

      printLog('🔍 Searching in: $_pubAssetsDir');
      printLog('✅ Images found: ${pubImageNames.length}');
      for (int i = 0; i < pubImageNames.length; i++) {
        printLog('   [$i] ${pubImageNames[i]}');
      }

      if (pubImageNames.isEmpty) {
        printLog('⚠️ NO IMAGES FOUND - will show "Espace Pub" placeholder');
      }

      if (!mounted) return;
      setState(() {
        _pubImages = pubImageNames;
        _pubIndex = 0;
        printLog('✓ State updated: _pubImages.length=${pubImageNames.length}');
      });
      if (pubImageNames.isNotEmpty) {
        _startPubRotation();
      }
    } catch (error, stacktrace) {
      printLog('❌ FATAL ERROR in _initPubImages: $error');
      printLog('Stack: $stacktrace');
      if (!mounted) return;
      setState(() {
        _pubImages = [];
        _pubIndex = 0;
      });
    }
  }

  void _startPubRotation() {
    _pubTimer?.cancel();
    if (_pubImages.length <= 1) return;

    _pubTimer = Timer.periodic(_pubDisplayDuration, (_) {
      if (!mounted) return;
      setState(() {
        if (_pubIndex < _pubImages.length - 1) {
          _pubIndex += 1;
        } else if (_pubLoop) {
          _pubIndex = 0;
        }
      });

      if (!_pubLoop && _pubIndex >= _pubImages.length - 1) {
        _pubTimer?.cancel();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      printLog(
          "didChangeAppLifecycleState state ====================> $state.");
    }
  }

  Future<void> _checkPremiumPlayPause() async {
    if ((audioPlayer.sequenceState.currentSource?.tag as MediaItem?)
                ?.extras?['is_premium'] ==
            1 &&
        (audioPlayer.sequenceState.currentSource?.tag as MediaItem?)
                ?.extras?['is_buy'] ==
            0) {
      AdHelper.showFullscreenAd(context, Constant.interstialAdType, () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return const Subscription(openFrom: '');
            },
          ),
        );
      });
    } else {
      printLog("Play/Pause click");
      if (audioPlayer.playing) {
        audioPlayer.pause();
        printLog("Pause");
      } else {
        audioPlayer.play();
        printLog("Play");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool lockExpanded = !widget.ishomepage;
    final double fullHeight = MediaQuery.of(context).size.height;
    if (lockExpanded) {
      const elementOpacity = 1.0;
      const progressIndicatorHeight = 2.0;
      return Scaffold(
        body: buildMusicPanel(
            fullHeight, elementOpacity, progressIndicatorHeight),
      );
    }

    return Miniplayer(
      valueNotifier: playerExpandProgress,
      minHeight: playerMinHeight,
      duration: const Duration(seconds: 1),
      maxHeight: fullHeight,
      controller: miniPlayerController,
      elevation: 4,
      // backgroundColor: colorPrimary,
      onDismissed: () async {
        printLog("onDismissed");
        currentlyPlaying.value = null;
        await audioPlayer.pause();
        await audioPlayer.stop();
        if (mounted) {
          setState(() {});
        }
        await audioPlayer.dispose();
        audioPlayer = AudioPlayer();
        musicManager.clearMusicPlayer();
        musicDetailProvider.clearProvider();
      },
      curve: Curves.easeInOutCubicEmphasized,
      builder: (height, percentage) {
        final bool miniplayer = percentage < miniplayerPercentageDeclaration;

        if (!miniplayer) {
          // Full screen mode - keep UI fully visible
          const elementOpacity = 1.0;
          const progressIndicatorHeight = 2.0;

          return Scaffold(
            body: buildMusicPanel(
                height, elementOpacity, progressIndicatorHeight),
          );
        }

        //Miniplayer in BuildMethod
        final percentageMiniplayer = percentageFromValueInRange(
            min: playerMinHeight,
            max: MediaQuery.of(context).size.height,
            value: height);

        final elementOpacity = 1 - 1 * percentageMiniplayer;
        final progressIndicatorHeight = 2 - 2 * percentageMiniplayer;

        // Scaffold
        return Scaffold(
          body:
              buildMusicPanel(height, elementOpacity, progressIndicatorHeight),
        );
      },
    );
  }

  // MiniPlayer AppBar
  Widget buildPodcastAppBar() {
    return Stack(
      children: [
        Column(
          children: [
            Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.05,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25)),
              ),
              child: Column(
                children: [
                  // AppBar removed to save space - back button hidden
                ],
              ),
            ),
            Container(
              height: MediaQuery.of(context).size.height * 0.02,
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
            )
          ],
        ),
        Positioned.fill(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: StreamBuilder<SequenceState?>(
              stream: audioPlayer.sequenceStateStream,
              builder: (context, snapshot) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(0),
                  child: MyNetworkImage(
                    imgWidth: MediaQuery.of(context).size.width,
                    imgHeight: MediaQuery.of(context).size.height * 0.32,
                    imageUrl: ((audioPlayer.sequenceState.currentSource?.tag
                                as MediaItem?)
                            ?.artUri)
                        .toString(),
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // FullPage MiniPlayer Screen Open Using This Method
  Widget buildPodcastMusicPage() {
    return StreamBuilder<SequenceState?>(
      stream: audioPlayer.sequenceStateStream,
      builder: (context, snapshot) {
        // if ((audioPlayer.sequenceState.currentSource?.tag as MediaItem?)
        //             ?.extras?['is_premium'] ==
        //         1 &&
        //     (audioPlayer.sequenceState.currentSource?.tag as MediaItem?)
        //             ?.extras?['is_buy'] ==
        //         0) {
        //   audioPlayer.pause();
        // } else {
        //   audioPlayer.play();
        // }
        return Container(
          alignment: Alignment.center,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                StreamBuilder<SequenceState?>(
                  stream: audioPlayer.sequenceStateStream,
                  builder: (context, snapshot) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextScroll(
                          intervalSpaces: 10,
                          mode: TextScrollMode.endless,
                          ((audioPlayer.sequenceState.currentSource?.tag
                                      as MediaItem?)
                                  ?.title)
                              .toString(),
                          selectable: true,
                          delayBefore: const Duration(milliseconds: 500),
                          fadedBorder: true,
                          style: Utils.googleFontStyle(
                              1, 18, FontStyle.normal, black, FontWeight.w600),
                          fadeBorderVisibility: FadeBorderVisibility.auto,
                          fadeBorderSide: FadeBorderSide.both,
                          velocity:
                              const Velocity(pixelsPerSecond: Offset(50, 0)),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 15),
                StreamBuilder<SequenceState?>(
                    stream: audioPlayer.sequenceStateStream,
                    builder: (context, snapshot) {
                      return ((audioPlayer.sequenceState.currentSource?.tag
                                          as MediaItem?)
                                      ?.displaySubtitle)
                                  .toString() ==
                              "podcast"
                          ? SizedBox(
                              width: MediaQuery.of(context).size.width,
                              // color: colorAccent,
                              child: SingleChildScrollView(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 0, 20, 0),
                                physics: const BouncingScrollPhysics(),
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        musicDetailProvider.getCommentList(
                                            "2",
                                            ((audioPlayer
                                                        .sequenceState
                                                        .currentSource
                                                        ?.tag as MediaItem?)
                                                    ?.artist)
                                                .toString(),
                                            ((audioPlayer
                                                        .sequenceState
                                                        .currentSource
                                                        ?.tag as MediaItem?)
                                                    ?.id)
                                                .toString(),
                                            "1");
                                        commentBottomSheet(
                                          index: 0,
                                          podcastId: ((audioPlayer
                                                      .sequenceState
                                                      .currentSource
                                                      ?.tag as MediaItem?)
                                                  ?.artist)
                                              .toString(),
                                          episodeId: ((audioPlayer
                                                      .sequenceState
                                                      .currentSource
                                                      ?.tag as MediaItem?)
                                                  ?.id)
                                              .toString(),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.fromLTRB(
                                            15, 8, 15, 8),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          color: colorPrimary.withValues(
                                              alpha: 0.25),
                                        ),
                                        child: Row(
                                          children: [
                                            MyImage(
                                              width: 18,
                                              height: 18,
                                              imagePath: "ic_comment.png",
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surface,
                                            ),
                                            const SizedBox(width: 8),
                                            MyText(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .surface,
                                                text: Utils.kmbGenerator(
                                                    int.parse(((audioPlayer
                                                                .sequenceState
                                                                .currentSource
                                                                ?.tag as MediaItem?)
                                                            ?.extras?['total_comment'])
                                                        .toString())),
                                                multilanguage: false,
                                                textalign: TextAlign.center,
                                                fontsize: Dimens.textTitle,
                                                maxline: 1,
                                                fontwaight: FontWeight.w500,
                                                overflow: TextOverflow.ellipsis,
                                                fontstyle: FontStyle.normal),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    InkWell(
                                      onTap: () {
                                        Utils.shareApp(Platform.isIOS
                                            ? "Hey! I'm Listening ${(audioPlayer.sequenceState.currentSource?.tag as MediaItem?)?.title}. Check it out now on ${Constant.appName}! \nhttps://apps.apple.com/us/app/${Constant.appName.toLowerCase()}/${Constant.appPackageName} \n"
                                            : "Hey! I'm Listening ${(audioPlayer.sequenceState.currentSource?.tag as MediaItem?)?.title}. Check it out now on ${Constant.appName}! \nhttps://play.google.com/store/apps/details?id=${Constant.appPackageName} \n");
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.fromLTRB(
                                            15, 8, 15, 8),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          color: colorPrimary.withValues(
                                              alpha: 0.25),
                                        ),
                                        child: Row(
                                          children: [
                                            MyImage(
                                              width: 18,
                                              height: 18,
                                              imagePath: "ic_sharemusic.png",
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surface,
                                            ),
                                            const SizedBox(width: 8),
                                            MyText(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .surface,
                                                text: "share",
                                                multilanguage: true,
                                                textalign: TextAlign.center,
                                                fontsize: Dimens.textTitle,
                                                maxline: 6,
                                                fontwaight: FontWeight.w600,
                                                overflow: TextOverflow.ellipsis,
                                                fontstyle: FontStyle.normal),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox.shrink();
                    }),
                Container(
                  margin: const EdgeInsets.fromLTRB(15, 20, 15, 15),
                  child: StreamBuilder<PositionData>(
                    stream: positionDataStream,
                    builder: (context, snapshot) {
                      final positionData = snapshot.data;
                      return ProgressBar(
                        progress: positionData?.position ?? Duration.zero,
                        buffered:
                            positionData?.bufferedPosition ?? Duration.zero,
                        total: positionData?.duration ?? Duration.zero,
                        progressBarColor: colorPrimary,
                        baseBarColor: lightgray,
                        bufferedBarColor: gray,
                        thumbColor: colorPrimary,
                        barHeight: 4.0,
                        thumbRadius: 6.0,
                        timeLabelPadding: 5.0,
                        timeLabelType: TimeLabelType.totalTime,
                        timeLabelTextStyle: GoogleFonts.inter(
                          fontSize: 12,
                          fontStyle: FontStyle.normal,
                          color: gray,
                          fontWeight: FontWeight.w700,
                        ),
                        onSeek: (duration) {
                          audioPlayer.seek(duration);
                        },
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Privious Audio Play
                    StreamBuilder<SequenceState?>(
                      stream: audioPlayer.sequenceStateStream,
                      builder: (context, snapshot) => InkWell(
                        onTap: audioPlayer.hasPrevious
                            ? audioPlayer.seekToPrevious
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Opacity(
                            opacity: audioPlayer.hasPrevious ? 1.0 : 0.5,
                            child: MyImage(
                              width: 25,
                              height: 25,
                              imagePath: "ic_previous.png",
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    // 10 Second Privious
                    StreamBuilder<PositionData>(
                      stream: positionDataStream,
                      builder: (context, snapshot) {
                        final positionData = snapshot.data;
                        return InkWell(
                          onTap: () {
                            if ((audioPlayer.sequenceState.currentSource?.tag
                                            as MediaItem?)
                                        ?.extras?['is_premium'] ==
                                    1 &&
                                (audioPlayer.sequenceState.currentSource?.tag
                                            as MediaItem?)
                                        ?.extras?['is_buy'] ==
                                    0) {
                              AdHelper.showFullscreenAd(
                                  context, Constant.interstialAdType, () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) {
                                      return const Subscription(openFrom: '');
                                    },
                                  ),
                                );
                              });
                            } else {
                              tenSecNextOrPrevious(
                                  positionData?.position.inSeconds.toString() ??
                                      "",
                                  false);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: MyImage(
                                width: 30,
                                height: 30,
                                color: Theme.of(context).colorScheme.surface,
                                imagePath: "ic_backward.png"),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 15),
                    // Pause and Play Control
                    StreamBuilder<PlayerState>(
                      stream: audioPlayer.playerStateStream,
                      builder: (context, snapshot) {
                        final playerState = snapshot.data;
                        final processingState = playerState?.processingState;
                        final playing = playerState?.playing;
                        if (processingState == ProcessingState.loading ||
                            processingState == ProcessingState.buffering) {
                          return Container(
                            margin: const EdgeInsets.all(8.0),
                            width: 50.0,
                            height: 50.0,
                            child: const CircularProgressIndicator(
                              color: colorAccent,
                            ),
                          );
                        } else if (playing != true) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  colorPrimary,
                                  colorPrimary,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.play_arrow_rounded,
                                color: white,
                              ),
                              color: white,
                              iconSize: 50.0,
                              onPressed: () {
                                _checkPremiumPlayPause();
                              },
                            ),
                          );
                        } else if (processingState !=
                            ProcessingState.completed) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  colorPrimary,
                                  colorPrimary,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.pause_rounded,
                                color: white,
                              ),
                              iconSize: 50.0,
                              color: white,
                              onPressed: () {
                                _checkPremiumPlayPause();
                              },
                            ),
                          );
                        } else {
                          return IconButton(
                            icon: const Icon(
                              Icons.replay_rounded,
                              color: colorPrimary,
                            ),
                            iconSize: 60.0,
                            onPressed: () => audioPlayer.seek(Duration.zero,
                                index: audioPlayer.effectiveIndices.first),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 15),
                    // 10 Second Next
                    StreamBuilder<PositionData>(
                      stream: positionDataStream,
                      builder: (context, snapshot) {
                        final positionData = snapshot.data;
                        return InkWell(
                          onTap: () {
                            if ((audioPlayer.sequenceState.currentSource?.tag
                                            as MediaItem?)
                                        ?.extras?['is_premium'] ==
                                    1 &&
                                (audioPlayer.sequenceState.currentSource?.tag
                                            as MediaItem?)
                                        ?.extras?['is_buy'] ==
                                    0) {
                              AdHelper.showFullscreenAd(
                                  context, Constant.interstialAdType, () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) {
                                      return const Subscription(openFrom: '');
                                    },
                                  ),
                                );
                              });
                            } else {
                              tenSecNextOrPrevious(
                                  positionData?.position.inSeconds.toString() ??
                                      "",
                                  true);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: MyImage(
                              width: 30,
                              height: 30,
                              color: Theme.of(context).colorScheme.surface,
                              imagePath: "ic_forward.png",
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 15),
                    // Next Audio Play
                    StreamBuilder<SequenceState?>(
                      stream: audioPlayer.sequenceStateStream,
                      builder: (context, snapshot) {
                        return InkWell(
                          onTap: audioPlayer.hasNext
                              ? audioPlayer.seekToNext
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Opacity(
                              opacity: audioPlayer.hasNext ? 1.0 : 0.5,
                              child: MyImage(
                                width: 25,
                                height: 25,
                                imagePath: "ic_next.png",
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: MediaQuery.of(context).size.width,
                  padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Volumn Costome Set
                      IconButton(
                        iconSize: 30.0,
                        icon: const Icon(Icons.volume_up),
                        color: Theme.of(context).colorScheme.surface,
                        onPressed: () {
                          showSliderDialog(
                            context: context,
                            title: "Adjust volume",
                            divisions: 10,
                            min: 0.0,
                            max: 2.0,
                            value: audioPlayer.volume,
                            stream: audioPlayer.volumeStream,
                            onChanged: audioPlayer.setVolume,
                          );
                        },
                      ),
                      // Audio Speed Costomized
                      StreamBuilder<double>(
                        stream: audioPlayer.speedStream,
                        builder: (context, snapshot) => IconButton(
                          icon: Text(
                            overflow: TextOverflow.ellipsis,
                            "${snapshot.data?.toStringAsFixed(1)}x",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.surface,
                                fontSize: 14),
                          ),
                          onPressed: () {
                            showSliderDialog(
                              context: context,
                              title: "Adjust speed",
                              divisions: 10,
                              min: 0.5,
                              max: 2.0,
                              value: audioPlayer.speed,
                              stream: audioPlayer.speedStream,
                              onChanged: audioPlayer.setSpeed,
                            );
                          },
                        ),
                      ),
                      // Loop Node Button
                      StreamBuilder<LoopMode>(
                        stream: audioPlayer.loopModeStream,
                        builder: (context, snapshot) {
                          final loopMode = snapshot.data ?? LoopMode.off;
                          final icons = [
                            Icon(Icons.repeat,
                                color: Theme.of(context).colorScheme.surface,
                                size: 30.0),
                            const Icon(Icons.repeat,
                                color: colorPrimary, size: 30.0),
                            const Icon(Icons.repeat_one,
                                color: colorPrimary, size: 30.0),
                          ];
                          const cycleModes = [
                            LoopMode.off,
                            LoopMode.all,
                            LoopMode.one,
                          ];
                          final index = cycleModes.indexOf(loopMode);
                          return IconButton(
                            icon: icons[index],
                            onPressed: () {
                              audioPlayer.setLoopMode(cycleModes[
                                  (cycleModes.indexOf(loopMode) + 1) %
                                      cycleModes.length]);
                            },
                          );
                        },
                      ),
                      // Suffle Button
                      StreamBuilder<bool>(
                        stream: audioPlayer.shuffleModeEnabledStream,
                        builder: (context, snapshot) {
                          final shuffleModeEnabled = snapshot.data ?? false;
                          return IconButton(
                            iconSize: 30.0,
                            icon: shuffleModeEnabled
                                ? const Icon(Icons.shuffle, color: colorPrimary)
                                : Icon(Icons.shuffle,
                                    color:
                                        Theme.of(context).colorScheme.surface),
                            onPressed: () async {
                              final enable = !shuffleModeEnabled;
                              if (enable) {
                                await audioPlayer.shuffle();
                              }
                              await audioPlayer.setShuffleModeEnabled(enable);
                            },
                          );
                        },
                      ),
                      // Favorite
                      // _buildLikeUnlike(),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                /* Episode List */
                if ((musicDetailProvider.episodeList?.length ?? 0) > 0 &&
                    ((audioPlayer.sequenceState.currentSource?.tag
                                    as MediaItem?)
                                ?.displaySubtitle)
                            .toString() ==
                        "podcast")
                  Container(
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                      ),
                      color: colorPrimary.withValues(alpha: 0.25),
                    ),
                    child: Consumer<MusicDetailProvider>(
                      builder: (context, seactionprovider, child) {
                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: InkWell(
                                    onTap: () async {
                                      seactionprovider
                                          .changeMusicTab("episode");
                                    },
                                    child: SizedBox(
                                      height: 50,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          MyText(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surface,
                                              text: "episode",
                                              multilanguage: true,
                                              textalign: TextAlign.center,
                                              fontsize: Dimens.textTitle,
                                              maxline: 1,
                                              fontwaight: FontWeight.w600,
                                              overflow: TextOverflow.ellipsis,
                                              fontstyle: FontStyle.normal),
                                          const SizedBox(height: 14),
                                          Container(
                                            width: MediaQuery.of(context)
                                                .size
                                                .width,
                                            height: 1.5,
                                            color: seactionprovider.istype ==
                                                    "episode"
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .surface
                                                : transparent,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: InkWell(
                                    onTap: () async {
                                      seactionprovider
                                          .changeMusicTab("details");
                                    },
                                    child: SizedBox(
                                      height: 50,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          MyText(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surface,
                                              text: "detail",
                                              multilanguage: true,
                                              textalign: TextAlign.center,
                                              fontsize: Dimens.textTitle,
                                              maxline: 1,
                                              fontwaight: FontWeight.w600,
                                              overflow: TextOverflow.ellipsis,
                                              fontstyle: FontStyle.normal),
                                          const SizedBox(height: 14),
                                          Container(
                                            width: MediaQuery.of(context)
                                                .size
                                                .width,
                                            height: 1.5,
                                            color: seactionprovider.istype ==
                                                    "details"
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .surface
                                                : transparent,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            seactionprovider.istype == "episode"
                                ? podcastEpisodeList()
                                : podcastEpisodeDetail(),
                          ],
                        );
                      },
                    ),
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget podcastEpisodeList() {
    return Consumer<MusicDetailProvider>(
        builder: (context, musicdetailprovider, child) {
      if (musicdetailprovider.loading && !musicdetailprovider.loadMore) {
        return Utils.pageLoader();
      } else {
        if (musicdetailprovider.getEpisodeByPodcstModel.status == 200 &&
            musicdetailprovider.episodeList != null) {
          if ((musicdetailprovider.episodeList?.length ?? 0) > 0) {
            return StreamBuilder<SequenceState?>(
              stream: audioPlayer.sequenceStateStream,
              builder: (context, snapshot) {
                return Column(
                  children: [
                    MediaQuery.removePadding(
                      removeTop: true,
                      context: context,
                      child: ResponsiveGridList(
                        minItemWidth: 120,
                        minItemsPerRow: 1,
                        maxItemsPerRow: 1,
                        horizontalGridSpacing: 10,
                        verticalGridSpacing: 10,
                        listViewBuilderOptions: ListViewBuilderOptions(
                          scrollDirection: Axis.vertical,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                        ),
                        children: List.generate(
                          musicdetailprovider.episodeList?.length ?? 0,
                          (index) {
                            return InkWell(
                              onTap: () {
                                Utils.playAudio(
                                    context,
                                    "podcast",
                                    0,
                                    0,
                                    musicdetailprovider
                                            .episodeList?[0].landscapeImg
                                            .toString() ??
                                        "",
                                    musicdetailprovider.episodeList?[0].name
                                            .toString() ??
                                        "",
                                    '',
                                    musicdetailprovider
                                            .episodeList?[0].episodeAudio
                                            .toString() ??
                                        "",
                                    "",
                                    musicdetailprovider
                                            .episodeList?[0].description
                                            .toString() ??
                                        "",
                                    musicdetailprovider
                                            .episodeList?[0].id
                                            .toString() ??
                                        "",
                                    (audioPlayer.sequenceState.currentSource
                                            ?.tag as MediaItem?)!
                                        .artist
                                        .toString(),
                                    index,
                                    musicdetailprovider.episodeList?.toList() ??
                                        []);
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.fromLTRB(15, 5, 15, 5),
                                decoration: BoxDecoration(
                                  // borderRadius: BorderRadius.circular(5),
                                  color: ((audioPlayer
                                                      .sequenceState
                                                      .currentSource
                                                      ?.tag as MediaItem?)
                                                  ?.id)
                                              .toString() ==
                                          musicdetailprovider
                                              .episodeList?[index].id
                                              .toString()
                                      ? colorPrimary.withValues(alpha: 0.25)
                                      : transparent,
                                ),
                                child: Row(
                                  children: [
                                    Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          child: MyNetworkImage(
                                              imgWidth: 60,
                                              imgHeight: 48,
                                              imageUrl: musicdetailprovider
                                                      .episodeList?[index]
                                                      .portraitImg
                                                      .toString() ??
                                                  "",
                                              fit: BoxFit.cover),
                                        ),
                                        Positioned.fill(
                                          left: 5,
                                          right: 5,
                                          child: Align(
                                            alignment: Alignment.bottomRight,
                                            child: ((audioPlayer
                                                                    .sequenceState
                                                                    .currentSource
                                                                    ?.tag
                                                                as MediaItem?)
                                                            ?.id)
                                                        .toString() ==
                                                    musicdetailprovider
                                                        .episodeList?[index].id
                                                        .toString()
                                                ? MyImage(
                                                    width: 25,
                                                    height: 25,
                                                    imagePath: "music.gif")
                                                : const SizedBox.shrink(),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          MyText(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surface,
                                            text: musicdetailprovider
                                                    .episodeList?[index].name
                                                    .toString() ??
                                                "",
                                            multilanguage: false,
                                            textalign: TextAlign.left,
                                            fontsize: Dimens.textSmall,
                                            inter: 1,
                                            maxline: 2,
                                            fontwaight: FontWeight.w600,
                                            overflow: TextOverflow.ellipsis,
                                            fontstyle: FontStyle.normal,
                                          ),
                                          const SizedBox(height: 2),
                                          MyText(
                                            color: colorPrimary,
                                            text: Utils.dateformat(
                                                DateTime.parse(
                                                    musicdetailprovider
                                                            .episodeList?[index]
                                                            .createdAt
                                                            .toString() ??
                                                        "")),
                                            multilanguage: false,
                                            textalign: TextAlign.left,
                                            fontsize: Dimens.textSmall,
                                            inter: 1,
                                            maxline: 6,
                                            fontwaight: FontWeight.w400,
                                            overflow: TextOverflow.ellipsis,
                                            fontstyle: FontStyle.normal,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    if (musicdetailprovider.loadMore)
                      SizedBox(
                        height: 50,
                        child: Utils.pageLoader(),
                      )
                    else
                      const SizedBox.shrink(),
                  ],
                );
              },
            );
          } else {
            return const SizedBox.shrink();
          }
        } else {
          return const SizedBox.shrink();
        }
      }
    });
  }

  Widget podcastEpisodeDetail() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 15, 10, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText(
            color: Theme.of(context).colorScheme.surface,
            text: ((audioPlayer.sequenceState.currentSource?.tag as MediaItem?)
                    ?.extras?['name'])
                .toString(),
            multilanguage: false,
            textalign: TextAlign.left,
            fontsize: Dimens.textTitle,
            inter: 1,
            maxline: 2,
            fontwaight: FontWeight.w600,
            overflow: TextOverflow.ellipsis,
            fontstyle: FontStyle.normal,
          ),
          const SizedBox(height: 10),
          MyText(
            color: Theme.of(context).colorScheme.surface,
            text: ((audioPlayer.sequenceState.currentSource?.tag as MediaItem?)
                    ?.extras?['description'])
                .toString(),
            multilanguage: false,
            textalign: TextAlign.left,
            fontsize: Dimens.textMedium,
            inter: 1,
            maxline: 100,
            fontwaight: FontWeight.w400,
            overflow: TextOverflow.ellipsis,
            fontstyle: FontStyle.normal,
          ),
        ],
      ),
    );
  }

  Widget _buildPubSlideshow({required bool showIndicators}) {
    if (_pubImages.isEmpty) {
      printLog(
          '🎬 _buildPubSlideshow: EMPTY - showing "Espace Pub" placeholder');
      final size = MediaQuery.of(context).size;
      final diagonalLogical =
          math.sqrt(size.width * size.width + size.height * size.height);
      final diagonalInches = diagonalLogical / 160.0;
      double pubHeight;
      if (diagonalInches < LectResponsiveConfig.smallDiagonalInches) {
        pubHeight = LectResponsiveConfig.pubSlideshowHeightSmall;
      } else if (diagonalInches < LectResponsiveConfig.largeDiagonalInches) {
        pubHeight = LectResponsiveConfig.pubSlideshowHeightMedium;
      } else {
        pubHeight = LectResponsiveConfig.pubSlideshowHeightLarge;
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: black.withValues(alpha: 0.16),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: double.infinity,
                height: pubHeight,
                color: black.withValues(alpha: 0.9),
                alignment: Alignment.center,
                child: const Text(
                  'Espace Pub',
                  style: TextStyle(
                    color: white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          if (showIndicators) const SizedBox(height: 10),
          if (showIndicators)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPubIndicatorDot(isActive: true),
              ],
            ),
        ],
      );
    }

    final String currentImage = _pubImages[_pubIndex];
    printLog(
        '🎬 _buildPubSlideshow: Image $_pubIndex/${_pubImages.length}: $currentImage');

    final size = MediaQuery.of(context).size;
    final diagonalLogical =
        math.sqrt(size.width * size.width + size.height * size.height);
    final diagonalInches = diagonalLogical / 160.0;
    double pubHeight;
    if (diagonalInches < LectResponsiveConfig.smallDiagonalInches) {
      pubHeight = LectResponsiveConfig.pubSlideshowHeightSmall;
    } else if (diagonalInches < LectResponsiveConfig.largeDiagonalInches) {
      pubHeight = LectResponsiveConfig.pubSlideshowHeightMedium;
    } else {
      pubHeight = LectResponsiveConfig.pubSlideshowHeightLarge;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: black.withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AnimatedSwitcher(
              duration: _pubFadeDuration,
              child: Image.asset(
                currentImage,
                key: ValueKey<String>(currentImage),
                width: double.infinity,
                height: pubHeight,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  printLog('❌ ERROR loading image $currentImage: $error');
                  return Container(
                    width: double.infinity,
                    height: pubHeight,
                    color: black.withValues(alpha: 0.9),
                    alignment: Alignment.center,
                    child: const Text(
                      'Espace Pub',
                      style: TextStyle(
                        color: white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        if (showIndicators) const SizedBox(height: 10),
        if (showIndicators && _pubImages.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pubImages.length,
              (index) => _buildPubIndicatorDot(isActive: index == _pubIndex),
            ),
          ),
      ],
    );
  }

  Widget _buildPubIndicatorDot({required bool isActive}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 10 : 8,
      height: isActive ? 10 : 8,
      decoration: BoxDecoration(
        color: isActive ? colorPrimary : gray.withValues(alpha: 0.45),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildExpandedPlayerBackground() {
    final accentSoft = const Color(0xFFFFC5BA);
    final darkEdge = const Color(0xFF120406);

    return Positioned.fill(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.0, -0.10),
                radius: 1.15,
                colors: [
                  accentSoft.withValues(alpha: 0.74),
                  const Color(0xFF5B1E24).withValues(alpha: 0.72),
                  darkEdge,
                ],
                stops: const [0.06, 0.36, 1.0],
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.topCenter,
                  colors: [
                    white.withValues(alpha: 0.00),
                    white.withValues(alpha: 1.00),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Small MiniPlayer Panel Open Using This Method
  Widget buildMusicPanel(
      dynamic dynamicPanelHeight, elementOpacity, progressIndicatorHeight) {
    return SizedBox.expand(
      child: StreamBuilder<SequenceState?>(
        stream: audioPlayer.sequenceStateStream,
        builder: (context, snapshot) {
          final mediaItem =
              audioPlayer.sequenceState.currentSource?.tag as MediaItem?;
          final bool isExpandedPlayer =
              (dynamicPanelHeight as num).toDouble() >=
                  MediaQuery.of(context).size.height *
                      miniplayerPercentageDeclaration;

          return Container(
            color: isExpandedPlayer
                ? const Color(0xFF120406)
                : Theme.of(context).secondaryHeaderColor,
            child: Stack(
              children: [
                if (isExpandedPlayer)
                  _buildExpandedPlayerBackground()
                else ...[
                  // Background image + gradient (mini player)
                  Positioned.fill(
                    child: Opacity(
                      opacity: 1.0,
                      child: Image.asset(
                        'assets/images/lect-back.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Theme.of(context)
                                .secondaryHeaderColor
                                .withValues(alpha: 0.0),
                            Theme.of(context)
                                .secondaryHeaderColor
                                .withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                // Main content
                Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // zoneLectPub - Pub zone with customizable parameters
                    Opacity(
                      opacity: elementOpacity,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: _buildPubSlideshow(
                          showIndicators: isExpandedPlayer,
                        ),
                      ),
                    ),
                    // cercleLect - Circle with image and bounce effect
                    StreamBuilder<PlayerState>(
                      stream: audioPlayer.playerStateStream,
                      builder: (context, snapshot) {
                        final playing = snapshot.data?.playing ?? false;

                        // Control animation based on playing state
                        if (playing && !_bounceController.isAnimating) {
                          _bounceController.repeat(reverse: true);
                        } else if (!playing && _bounceController.isAnimating) {
                          _bounceController.stop();
                          _bounceController.reset();
                        }

                        // Control notes animation based on playing state
                        if (playing && !_notesController.isAnimating) {
                          _notesController.repeat(reverse: true);
                        } else if (!playing && _notesController.isAnimating) {
                          _notesController.stop();
                          _notesController.reset();
                        }

                        return Flexible(
                          flex: 3,
                          child: Center(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                // Calculate responsive sizes based on available height
                                final availableHeight = constraints.maxHeight;
                                final size = MediaQuery.of(context).size;

                                // Ratios pour chaque zone (ajustables)
                                // Définition de breakpoints par diagonale d'écran (pouces):
                                // petit < LectResponsiveConfig.smallDiagonalInches
                                // moyen entre smallDiagonalInches et largeDiagonalInches
                                // grand > LectResponsiveConfig.largeDiagonalInches
                                final diagonalLogical = math.sqrt(
                                    size.width * size.width +
                                        size.height * size.height);
                                // Approximation pouces: baseline mdpi = 160 logical px/inch
                                final diagonalInches = diagonalLogical / 160.0;

                                double brandSize;
                                double headSize;
                                double notesSize;
                                double brandOffsetY;
                                double headOffsetY;
                                double notesOffsetY;

                                if (diagonalInches <
                                    LectResponsiveConfig.smallDiagonalInches) {
                                  // Petit écran (mobile)
                                  brandSize = (availableHeight *
                                          LectResponsiveConfig.smallBrandRatio)
                                      .clamp(LectResponsiveConfig.smallBrandMin,
                                          LectResponsiveConfig.smallBrandMax);
                                  headSize = (availableHeight *
                                          LectResponsiveConfig.smallHeadRatio)
                                      .clamp(LectResponsiveConfig.smallHeadMin,
                                          LectResponsiveConfig.smallHeadMax);
                                  notesSize = (availableHeight *
                                          LectResponsiveConfig.smallNotesRatio)
                                      .clamp(LectResponsiveConfig.smallNotesMin,
                                          LectResponsiveConfig.smallNotesMax);

                                  brandOffsetY = -(availableHeight *
                                          LectResponsiveConfig
                                              .smallBrandOffsetRatio)
                                      .clamp(
                                          LectResponsiveConfig
                                              .smallBrandOffsetMin,
                                          LectResponsiveConfig
                                              .smallBrandOffsetMax);
                                  headOffsetY = (availableHeight *
                                          LectResponsiveConfig
                                              .smallHeadOffsetRatio)
                                      .clamp(
                                          LectResponsiveConfig
                                              .smallHeadOffsetMin,
                                          LectResponsiveConfig
                                              .smallHeadOffsetMax);
                                  notesOffsetY = (availableHeight *
                                          LectResponsiveConfig
                                              .smallNotesOffsetRatio)
                                      .clamp(
                                          LectResponsiveConfig
                                              .smallNotesOffsetMin,
                                          LectResponsiveConfig
                                              .smallNotesOffsetMax);
                                } else if (diagonalInches <
                                    LectResponsiveConfig.largeDiagonalInches) {
                                  // Écran moyen (tablette / laptop)
                                  brandSize = (availableHeight *
                                          LectResponsiveConfig.mediumBrandRatio)
                                      .clamp(
                                          LectResponsiveConfig.mediumBrandMin,
                                          LectResponsiveConfig.mediumBrandMax);
                                  headSize = (availableHeight *
                                          LectResponsiveConfig.mediumHeadRatio)
                                      .clamp(LectResponsiveConfig.mediumHeadMin,
                                          LectResponsiveConfig.mediumHeadMax);
                                  notesSize = (availableHeight *
                                          LectResponsiveConfig.mediumNotesRatio)
                                      .clamp(
                                          LectResponsiveConfig.mediumNotesMin,
                                          LectResponsiveConfig.mediumNotesMax);

                                  brandOffsetY = -(availableHeight *
                                          LectResponsiveConfig
                                              .mediumBrandOffsetRatio)
                                      .clamp(
                                          LectResponsiveConfig
                                              .mediumBrandOffsetMin,
                                          LectResponsiveConfig
                                              .mediumBrandOffsetMax);
                                  headOffsetY = (availableHeight *
                                          LectResponsiveConfig
                                              .mediumHeadOffsetRatio)
                                      .clamp(
                                          LectResponsiveConfig
                                              .mediumHeadOffsetMin,
                                          LectResponsiveConfig
                                              .mediumHeadOffsetMax);
                                  notesOffsetY = (availableHeight *
                                          LectResponsiveConfig
                                              .mediumNotesOffsetRatio)
                                      .clamp(
                                          LectResponsiveConfig
                                              .mediumNotesOffsetMin,
                                          LectResponsiveConfig
                                              .mediumNotesOffsetMax);
                                } else {
                                  // Grand écran (desktop large)
                                  brandSize = (availableHeight *
                                          LectResponsiveConfig.largeBrandRatio)
                                      .clamp(LectResponsiveConfig.largeBrandMin,
                                          LectResponsiveConfig.largeBrandMax);
                                  headSize = (availableHeight *
                                          LectResponsiveConfig.largeHeadRatio)
                                      .clamp(LectResponsiveConfig.largeHeadMin,
                                          LectResponsiveConfig.largeHeadMax);
                                  notesSize = (availableHeight *
                                          LectResponsiveConfig.largeNotesRatio)
                                      .clamp(LectResponsiveConfig.largeNotesMin,
                                          LectResponsiveConfig.largeNotesMax);

                                  brandOffsetY = -(availableHeight *
                                          LectResponsiveConfig
                                              .largeBrandOffsetRatio)
                                      .clamp(
                                          LectResponsiveConfig
                                              .largeBrandOffsetMin,
                                          LectResponsiveConfig
                                              .largeBrandOffsetMax);
                                  headOffsetY = (availableHeight *
                                          LectResponsiveConfig
                                              .largeHeadOffsetRatio)
                                      .clamp(
                                          LectResponsiveConfig
                                              .largeHeadOffsetMin,
                                          LectResponsiveConfig
                                              .largeHeadOffsetMax);
                                  notesOffsetY = (availableHeight *
                                          LectResponsiveConfig
                                              .largeNotesOffsetRatio)
                                      .clamp(
                                          LectResponsiveConfig
                                              .largeNotesOffsetMin,
                                          LectResponsiveConfig
                                              .largeNotesOffsetMax);
                                }

                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // notesLect - Notes image with animation (fade in/out when playing)
                                    AnimatedOpacity(
                                      opacity: playing ? 1.0 : 0.0,
                                      duration:
                                          const Duration(milliseconds: 500),
                                      child: _buildAnimatedNotesLect(
                                        size: notesSize,
                                        offsetY: notesOffsetY,
                                      ),
                                    ),
                                    // Background brand image (non-animated)
                                    Transform.translate(
                                      offset: Offset(0, brandOffsetY),
                                      child: Opacity(
                                        opacity: 1.0,
                                        child: Image.asset(
                                          'assets/images/lect-brand.png',
                                          width: brandSize,
                                          height: brandSize,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                    // Animated circle on top
                                    ScaleTransition(
                                      scale:
                                          Tween<double>(begin: 0.98, end: 1.0)
                                              .animate(
                                        CurvedAnimation(
                                          parent: _bounceController,
                                          curve: Curves.easeInOut,
                                        ),
                                      ),
                                      child: Padding(
                                        padding:
                                            EdgeInsets.only(top: headOffsetY),
                                        child: Opacity(
                                          opacity: elementOpacity * 1.0,
                                          child: Container(
                                            width: headSize,
                                            height: headSize,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color.fromARGB(
                                                          255, 245, 177, 4)
                                                      .withValues(alpha: 0.2),
                                                  blurRadius: 20,
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      headSize / 2),
                                              child: Image.asset(
                                                'assets/images/lect-head.png',
                                                width: headSize,
                                                height: headSize,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    // Play/Pause button below circle
                    Opacity(
                      opacity: elementOpacity,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                            16, 8, 16, 8), // Top padding réglable (30)
                        child: Center(
                          child: StreamBuilder<PlayerState>(
                            stream: audioPlayer.playerStateStream,
                            builder: (context, snap) {
                              final playing = snap.data?.playing ?? false;
                              return Container(
                                decoration: BoxDecoration(
                                  color: colorPrimary.withValues(alpha: 1.0),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          colorPrimary.withValues(alpha: 1.0),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    playing
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: white,
                                    size: 60,
                                  ),
                                  iconSize: 80,
                                  onPressed: () {
                                    _checkPremiumPlayPause();
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    // Progress bar + Title
                    Flexible(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Progress bar désactivée
                          // Opacity(
                          //   opacity: elementOpacity,
                          //   child: StreamBuilder<PositionData>(
                          //     stream: positionDataStream,
                          //     builder: (context, snap) {
                          //       final pos = snap.data;
                          //       return Padding(
                          //         padding:
                          //             const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          //         child: ProgressBar(
                          //           progress: pos?.position ?? Duration.zero,
                          //           buffered:
                          //               pos?.bufferedPosition ?? Duration.zero,
                          //           total: pos?.duration ?? Duration.zero,
                          //           progressBarColor: colorPrimary,
                          //           baseBarColor: white.withValues(alpha: 0.1),
                          //           barCapShape: BarCapShape.round,
                          //           barHeight: 4,
                          //           thumbRadius: 6,
                          //           timeLabelLocation: TimeLabelLocation.below,
                          //         ),
                          //       );
                          //     },
                          //   ),
                          // ),
                          // Title & artist
                          Opacity(
                            opacity: elementOpacity,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              child: StreamBuilder<PlayerState>(
                                stream: audioPlayer.playerStateStream,
                                builder: (context, snapshot) {
                                  final processingState =
                                      snapshot.data?.processingState;
                                  final isLoading = processingState ==
                                          ProcessingState.loading ||
                                      processingState ==
                                          ProcessingState.buffering;

                                  return Column(
                                    children: [
                                      Text(
                                        isLoading
                                            ? 'Chargement...'
                                            : (mediaItem?.title ?? ''),
                                        style: const TextStyle(
                                          color: white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isLoading
                                            ? 'Merci de patienter...'
                                            : (mediaItem?.displayDescription ??
                                                ''),
                                        style: TextStyle(
                                          color: white.withValues(alpha: 0.7),
                                          fontSize: 12,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 10 Second Next And Previous Functionality
  // bool isnext = true > next Audio Seek
  // bool isnext = false > previous Audio Seek
  void tenSecNextOrPrevious(String audioposition, bool isnext) {
    dynamic firstHalf = Duration(seconds: int.parse(audioposition));
    const secondHalf = Duration(seconds: 10);
    Duration movePosition;
    if (isnext == true) {
      movePosition = firstHalf + secondHalf;
    } else {
      movePosition = firstHalf - secondHalf;
    }

    musicManager.seek(movePosition);
  }

  /* ================================================ Like / UnLike END */

  void commentBottomSheet(
      {required int index, required podcastId, required episodeId}) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            buildComment(index, podcastId, episodeId),
          ],
        );
      },
    ).whenComplete(() {
      commentController.clear();
      musicDetailProvider.clearComment();
    });
  }

/* Build Comment List */
  Widget buildComment(dynamic index, dynamic podcastId, episodeId) {
    return AnimatedPadding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      duration: const Duration(milliseconds: 100),
      curve: Curves.decelerate,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.5,
        constraints: BoxConstraints(
          minHeight: 0,
          maxHeight: MediaQuery.of(context).size.height,
        ),
        width: MediaQuery.of(context).size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 50,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(left: 20),
                      child: MyText(
                        color: Theme.of(context).colorScheme.surface,
                        multilanguage: true,
                        text: "comment",
                        fontsize: Dimens.textMedium,
                        fontstyle: FontStyle.normal,
                        fontwaight: FontWeight.w600,
                        maxline: 1,
                        overflow: TextOverflow.ellipsis,
                        textalign: TextAlign.start,
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(5),
                      onTap: () {
                        Navigator.pop(context);
                        commentController.clear();
                        musicDetailProvider.clearComment();
                      },
                      child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.close,
                            size: 20,
                            color: Theme.of(context).colorScheme.surface,
                          )),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Column(
                  children: [
                    Consumer<MusicDetailProvider>(
                        builder: (context, commentprovider, child) {
                      if (musicDetailProvider.commentloading &&
                          !musicDetailProvider.commentloadMore) {
                        return Utils.pageLoader();
                      } else {
                        if (musicDetailProvider.commentListModel.status ==
                                200 &&
                            musicDetailProvider.commentList != null) {
                          if ((musicDetailProvider.commentList?.length ?? 0) >
                              0) {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Align(
                                  alignment: Alignment.topCenter,
                                  child: ListView.builder(
                                      scrollDirection: Axis.vertical,
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount:
                                          commentprovider.commentList?.length ??
                                              0,
                                      itemBuilder: (BuildContext ctx, index) {
                                        return Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              0, 10, 0, 10),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(1),
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            50),
                                                    border: Border.all(
                                                        width: 1,
                                                        color: white)),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(50),
                                                  child: MyNetworkImage(
                                                      imageUrl: commentprovider
                                                              .commentList?[
                                                                  index]
                                                              .image
                                                              .toString() ??
                                                          "",
                                                      fit: BoxFit.fill,
                                                      imgWidth: 30,
                                                      imgHeight: 30),
                                                ),
                                              ),
                                              const SizedBox(width: 15),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  MyText(
                                                      color: colorPrimary,
                                                      text: commentprovider
                                                                  .commentList?[
                                                                      index]
                                                                  .fullName
                                                                  .toString() ==
                                                              ""
                                                          ? "${commentprovider.commentList?[index].userName.toString()}"
                                                          : commentprovider
                                                                  .commentList?[
                                                                      index]
                                                                  .fullName
                                                                  .toString() ??
                                                              "",
                                                      fontsize:
                                                          Dimens.textMedium,
                                                      fontwaight:
                                                          FontWeight.w500,
                                                      multilanguage: false,
                                                      maxline: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      textalign:
                                                          TextAlign.center,
                                                      fontstyle:
                                                          FontStyle.normal),
                                                  const SizedBox(height: 8),
                                                  SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.70,
                                                    child: MyText(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .surface,
                                                        text: commentprovider
                                                                .commentList?[
                                                                    index]
                                                                .comment
                                                                .toString() ??
                                                            "",
                                                        fontsize:
                                                            Dimens.textSmall,
                                                        fontwaight:
                                                            FontWeight.w400,
                                                        multilanguage: false,
                                                        maxline: 3,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        textalign:
                                                            TextAlign.left,
                                                        fontstyle:
                                                            FontStyle.normal),
                                                  ),
                                                  const SizedBox(height: 7),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                ),
                                if (musicDetailProvider.commentloading)
                                  const CircularProgressIndicator(
                                    color: colorAccent,
                                  )
                                else
                                  const SizedBox.shrink(),
                              ],
                            );
                          } else {
                            return Align(
                              alignment: Alignment.center,
                              child: MyImage(
                                width: 130,
                                height:
                                    MediaQuery.of(context).size.height * 0.40,
                                fit: BoxFit.contain,
                                imagePath: "nodata.png",
                              ),
                            );
                          }
                        } else {
                          return Align(
                            alignment: Alignment.center,
                            child: MyImage(
                              width: 130,
                              height: MediaQuery.of(context).size.height * 0.35,
                              fit: BoxFit.contain,
                              imagePath: "nodata.png",
                            ),
                          );
                        }
                      }
                    }),
                  ],
                ),
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width,
              height: 50,
              constraints: BoxConstraints(
                minHeight: 0,
                maxHeight: MediaQuery.of(context).size.height,
              ),
              alignment: Alignment.center,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: commentController,
                        maxLines: 1,
                        scrollPhysics: const AlwaysScrollableScrollPhysics(),
                        textAlign: TextAlign.start,
                        cursorColor: Theme.of(context).colorScheme.surface,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: transparent,
                          border: InputBorder.none,
                          hintText: "Add Comments",
                          hintStyle: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.normal,
                            color: Theme.of(context).colorScheme.surface,
                          ),
                          contentPadding:
                              const EdgeInsets.only(left: 10, right: 10),
                        ),
                        obscureText: false,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.normal,
                          color: Theme.of(context).colorScheme.surface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 3),
                    InkWell(
                      borderRadius: BorderRadius.circular(5),
                      onTap: () async {
                        if (Constant.userID == null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                return const Login();
                              },
                            ),
                          );
                        } else if (commentController.text.isEmpty) {
                          Utils.showToast("Please Enter Your Comment");
                        } else {
                          musicDetailProvider.getaddcomment(podcastId,
                              commentController.text, "2", episodeId);

                          if (musicDetailProvider.successModel.status == 200) {
                            commentController.clear();

                            setState(() {
                              (audioPlayer.sequenceState.currentSource?.tag
                                      as MediaItem?)
                                  ?.extras?['total_comment'] = (audioPlayer
                                          .sequenceState
                                          .currentSource
                                          ?.tag as MediaItem?)
                                      ?.extras?['total_comment'] +
                                  1;
                            });
                          } else {
                            Utils.showToast(
                                musicDetailProvider.successModel.message ?? "");
                          }
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: SizedBox(
                          width: 30,
                          height: 30,
                          child: Consumer<MusicDetailProvider>(
                            builder: (context, commentprovider, child) {
                              if (commentprovider.addcommentloading) {
                                return const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: colorAccent,
                                    strokeWidth: 1,
                                  ),
                                );
                              } else {
                                return Icon(
                                  Icons.send,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.surface,
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build animated notesLect widget based on selected animation type
  Widget _buildAnimatedNotesLect(
      {required double size, required double offsetY}) {
    final notesBase = Transform.translate(
      offset: Offset(0, offsetY),
      child: Center(
        child: Opacity(
          opacity: 0.92,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ColorFiltered(
                colorFilter: ColorFilter.mode(
                  const Color(0xFFFFFFFF).withValues(alpha: 0.45),
                  BlendMode.srcATop,
                ),
                child: Image.asset(
                  'assets/images/lect-notes.png',
                  width: size * 1.08,
                  height: size * 1.08,
                  fit: BoxFit.contain,
                ),
              ),
              ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Color(0xFFFFFFFF),
                  BlendMode.srcATop,
                ),
                child: Image.asset(
                  'assets/images/lect-notes.png',
                  width: size,
                  height: size,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Apply animation based on notesAnimationType
    switch (notesAnimationType) {
      case animationFlutter:
        // Scintillement (Flutter) - Recommandé
        return FadeTransition(
          opacity: Tween<double>(begin: 0.4, end: 1.0).animate(
            CurvedAnimation(parent: _notesController, curve: Curves.easeInOut),
          ),
          child: notesBase,
        );

      case animationPulse:
        // Pulse d'opacité
        return FadeTransition(
          opacity: Tween<double>(begin: 0.6, end: 1.0).animate(
            CurvedAnimation(parent: _notesController, curve: Curves.easeInOut),
          ),
          child: notesBase,
        );

      case animationRotatePulse:
        // Rotation + Pulse
        return RotationTransition(
          turns: Tween<double>(begin: -0.02, end: 0.02).animate(
            CurvedAnimation(parent: _notesController, curve: Curves.easeInOut),
          ),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.5, end: 1.0).animate(
              CurvedAnimation(
                  parent: _notesController, curve: Curves.easeInOut),
            ),
            child: notesBase,
          ),
        );

      case animationFloat:
        // Float (montée/descente)
        return Transform.translate(
          offset: Offset(
            0,
            20 *
                (Tween<double>(begin: -1, end: 1).evaluate(
                  CurvedAnimation(
                      parent: _notesController, curve: Curves.easeInOut),
                )),
          ),
          child: notesBase,
        );

      case animationScale:
        // Scale
        return ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.05).animate(
            CurvedAnimation(parent: _notesController, curve: Curves.easeInOut),
          ),
          child: notesBase,
        );

      default:
        return notesBase;
    }
  }
}
