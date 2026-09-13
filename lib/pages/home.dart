import 'dart:io';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import 'package:myBonus/pages/liveevent.dart';
import 'package:myBonus/pages/nodata.dart';
import 'package:myBonus/pages/podcast.dart';
import 'package:myBonus/pages/viewall.dart';
import 'package:myBonus/pages/radiobyid.dart';
import 'package:myBonus/pages/login.dart';
import 'package:myBonus/pages/commonpage.dart';
import 'package:myBonus/music/musicdetails.dart';
import 'package:myBonus/pages/notification.dart';
import 'package:myBonus/pages/profile.dart';
import 'package:myBonus/pages/radio.dart';
import 'package:myBonus/pages/search.dart';
import 'package:myBonus/provider/addfavouriteprovider.dart';
import 'package:myBonus/provider/generalprovider.dart';
import 'package:myBonus/provider/homeprovider.dart';
import 'package:myBonus/provider/musicdetailprovider.dart';
import 'package:myBonus/provider/profileprovider.dart';
import 'package:myBonus/provider/themeprovider.dart';
import 'package:myBonus/subscription/allpayment.dart';
import 'package:myBonus/subscription/subscription.dart';
import 'package:myBonus/utils/adhelper.dart';
import 'package:myBonus/utils/color.dart';
import 'package:myBonus/utils/constant.dart';
import 'package:myBonus/utils/customwidget.dart';
import 'package:myBonus/utils/dimens.dart';
import 'package:myBonus/utils/sharedpref.dart';
import 'package:myBonus/utils/utils.dart';
import 'package:myBonus/widget/abidjan_header.dart';
import 'package:myBonus/widget/liveneon_bokeh_card.dart';
import 'package:myBonus/widget/liveneon_buttons.dart';
import 'package:myBonus/widget/liveneon_header.dart';
import 'package:myBonus/widget/abidjan_bokeh_card.dart';
import 'package:myBonus/widget/myimage.dart';
import 'package:myBonus/music/floating_player.dart';
import 'package:myBonus/widget/mynetworkimg.dart';
import 'package:myBonus/widget/mynetworkimg2.dart';
import 'package:myBonus/widget/mytext.dart';
import 'package:myBonus/widget/sectionrowtile.dart';
import 'package:myBonus/model/sectionlistmodel.dart' as section;

ValueNotifier<AudioPlayer?> currentlyPlaying = ValueNotifier(null);
const double playerMinHeight = 100;
const miniplayerPercentageDeclaration = 0.6;
List<AudioSource> playlist = [];

// Public (not library-private) so floating_player.dart can compare against
// it without a hardcoded magic number.
const int radioTabIndex = 2;

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  static const int _homeTabIndex = 0;
  static const int _filmsTabIndex = 1;
  static const int _podcastTabIndex = 3;
  // static const int _searchTabIndex = 4; // Désactivé
  static const int _profileTabIndex = 4;

  SharedPref sharedpre = SharedPref();
  late ScrollController _scrollController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String aboutus = "";
  String termscondition = "";
  String privacypolicy = "";
  final GlobalKey<ScaffoldState> drawerkey = GlobalKey<ScaffoldState>();
  double ratingValue = 0.0;
  CarouselSliderController pageController = CarouselSliderController();
  List<AudioSource> playlist = [];
  int _currentBottomNavIndex = radioTabIndex;

  /* Provider */
  late GeneralProvider generalProvider;
  late HomeProvider homeProvider;
  late ProfileProvider profileprovider;

  @override
  initState() {
    super.initState();
    generalProvider = Provider.of<GeneralProvider>(context, listen: false);
    homeProvider = Provider.of<HomeProvider>(context, listen: false);
    profileprovider = Provider.of<ProfileProvider>(context, listen: false);
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getApi();
    });
    // if (!kIsWeb) {
    //   OneSignal.Notifications.addClickListener(_handleNotificationOpened);
    // }
  }

  Future<void> getApi() async {
    // initializeOneSignal();
    homeProvider.setLoading(true);
    if (Constant.userID != null) {
      await profileprovider.getProfile(context);
    } else {
      profileprovider.clearProvider();
      Utils.updatePremium("0");
      if (!mounted) return;
      Utils.loadAds(context);
    }
    /* Radio Api */
    try {
      await _fetchData(0);
      await generalProvider.getPages();
      await generalProvider.getSocialLink();
      // Auto play first radio after data is loaded
      _autoPlayFirstRadio();
      homeProvider.setLoading(false);
    } catch (e) {
      printLog("Error Api ====>${e.toString()}");
      homeProvider.setLoading(false);
    }
  }

  // Future<void> initializeOneSignal() async {
  //   if (!kIsWeb) {
  //     SharedPref sharedPre = SharedPref();
  //     String? oneSignalAppId = await sharedPre.read("onesignal_apid");
  //     printLog("initializeOneSignal AppId ==> $oneSignalAppId");
  //     if (oneSignalAppId != null) {
  //       OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  //       // Initialize OneSignal
  //       OneSignal.initialize(oneSignalAppId);
  //       OneSignal.Notifications.requestPermission(true);
  //       OneSignal.Notifications.addPermissionObserver((state) {
  //         printLog("Has permission ==> $state");
  //       });
  //       OneSignal.User.pushSubscription.addObserver((state) {
  //         printLog(
  //             "pushSubscription state ==> ${state.current.jsonRepresentation()}");
  //       });
  //       OneSignal.Notifications.addForegroundWillDisplayListener((event) {
  //         event.preventDefault();
  //         event.notification.display();
  //       });
  //       OneSignal.Notifications.addClickListener(_handleNotificationOpened);
  //     }
  //   }
  // }

  Future<void> pushNotification() async {
    String? oneSignalAppId = await sharedpre.read(Constant.oneSignalAppIdKey);
    /*  Push Notification Method OneSignal Start */
    if (!kIsWeb) {
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      // Initialize OneSignal
      printLog("OneSignal PushNotification===> $oneSignalAppId");
      OneSignal.initialize(oneSignalAppId ?? "");
      OneSignal.Notifications.requestPermission(false);
      OneSignal.Notifications.addPermissionObserver((state) {
        printLog("Has permission ==> $state");
      });
      OneSignal.User.pushSubscription.addObserver((state) {
        printLog(
            "pushSubscription state ==> ${state.current.jsonRepresentation()}");
      });
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        /// preventDefault to not display the notification
        event.preventDefault();
        // Do async work
        /// notification.display() to display after preventing default
        event.notification.display();
      });
    }
/*  Push Notification Method OneSignal End */
  }

  // // What to do when the user opens/taps on a notification
  // void _handleNotificationOpened(OSNotificationClickEvent result) {
  //   /* id, image, name, song_url */
  //   printLog(
  //       "setNotificationOpenedHandler additionalData ===> ${result.notification.additionalData.toString()}");
  //   printLog(
  //       "setNotificationOpenedHandler id ===> ${result.notification.additionalData?['id']}");
  //   printLog(
  //       "setNotificationOpenedHandler image ===> ${result.notification.additionalData?['image']}");
  //   printLog(
  //       "setNotificationOpenedHandler name ===> ${result.notification.additionalData?['name']}");
  //   printLog(
  //       "setNotificationOpenedHandler song_url ===> ${result.notification.additionalData?['song_url']}");
  //   if (result.notification.additionalData?['id'] != null &&
  //       result.notification.additionalData?['song_url'] != null) {
  //     String? songID =
  //         result.notification.additionalData?['id'].toString() ?? "";
  //     String? songImage =
  //         result.notification.additionalData?['image'].toString() ?? "";
  //     String? songName =
  //         result.notification.additionalData?['name'].toString() ?? "";
  //     String? songUrl =
  //         result.notification.additionalData?['song_url'].toString() ?? "";
  //     printLog("songID    =====> $songID");
  //     printLog("songImage =====> $songImage");
  //     printLog("songName  =====> $songName");
  //     printLog("songUrl   =====> $songUrl");
  //     musicManager.playSingleSong(songID, songName, songUrl, songImage, "");
  //   }
  // }

  Future<void> _scrollListener() async {
    if (!_scrollController.hasClients) return;
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange &&
        (homeProvider.sectioncurrentPage ?? 0) <
            (homeProvider.sectiontotalPage ?? 0)) {
      homeProvider.setLoadMore(true);
      _fetchData(homeProvider.sectioncurrentPage ?? 0);
    }
  }

  Future<void> _fetchData(int? nextPage) async {
    printLog("isMorePage  ======> ${homeProvider.sectionisMorePage}");
    printLog("currentPage ======> ${homeProvider.sectioncurrentPage}");
    printLog("totalPage   ======> ${homeProvider.sectiontotalPage}");
    printLog("nextpage   ======> $nextPage");
    printLog("Call MyCourse");
    printLog("Pageno:== ${(nextPage ?? 0) + 1}");
    await homeProvider.getBanner(0);
    await homeProvider.getSeactionList((nextPage ?? 0) + 1);
    homeProvider.setLoadMore(false);
  }

  void _autoPlayFirstRadio() {
    try {
      final banner = homeProvider.bannerModel.result;
      if (banner != null && banner.isNotEmpty) {
        // The banner mixes radios (type 1) and other content (podcasts,
        // etc.) — its order isn't guaranteed, so find the first actual
        // radio rather than assuming it's at index 0.
        final radioIndex = banner.indexWhere((item) => item.type == 1);
        if (radioIndex != -1) {
          final firstRadio = banner[radioIndex];
          printLog("Auto playing first radio: ${firstRadio.name}");
          Utils.playAudio(
            context,
            "radio",
            firstRadio.isPremium ?? 0,
            firstRadio.isBuy ?? 0,
            firstRadio.image.toString(),
            firstRadio.name.toString(),
            'homebanner',
            firstRadio.songUrl.toString(),
            firstRadio.name.toString(),
            firstRadio.name.toString(),
            firstRadio.id.toString(),
            "",
            radioIndex,
            banner.toList(),
          );
        }
      }
    } catch (e) {
      printLog("Error auto playing first radio: $e");
    }
  }

  @override
  void dispose() {
    super.dispose();
    homeProvider.clearProvider();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: homeAccueilBg(context),
      child: SafeArea(
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            exitDilog(context);
          },
          child: Stack(
            children: [
              Scaffold(
                key: drawerkey,
                backgroundColor: homeAccueilBg(context),
                body: Container(
                  decoration: Theme.of(context).brightness == Brightness.dark
                      ? liveNeonBackgroundDecoration()
                      : BoxDecoration(color: homeAccueilBg(context)),
                  child: Column(
                    children: [
                      // Only show appBar for Home page
                      if (_currentBottomNavIndex == _homeTabIndex) appBar(),
                      Expanded(
                        child: _buildPageContent(),
                      ),
                    ],
                  ),
                ),
              ),
              // Persistent sliding full-screen player, expanded via the
              // dock's chevron (playerExpandProgress / miniPlayerController).
              // minHeight: 0 keeps it invisible until expanded, since the
              // dock already shows the compact "now playing" row. Placed
              // BEFORE the dock so the dock always stays on top and reachable
              // (the player has no back button of its own).
              ValueListenableBuilder<AudioPlayer?>(
                valueListenable: currentlyPlaying,
                builder: (context, player, child) {
                  if (player?.audioSource == null) {
                    return const SizedBox.shrink();
                  }
                  return MusicDetails(
                    ishomepage: true,
                    minHeight: 0,
                    currentTabIndex: _currentBottomNavIndex,
                  );
                },
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom + 10,
                child: _buildDockCard(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDockCard() {
    final bool isNight = Theme.of(context).brightness == Brightness.dark;
    final floatingPlayer = FloatingPlayer(
      currentTabIndex: _currentBottomNavIndex,
      onExpand: () {
        if (_currentBottomNavIndex != radioTabIndex) {
          setState(() {
            _currentBottomNavIndex = radioTabIndex;
          });
        }
      },
    );
    final navRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildBottomNavItem(Icons.home_outlined, 'Accueil', _homeTabIndex),
        _buildBottomNavItem(Icons.live_tv_outlined, 'Films', _filmsTabIndex),
        _buildBottomNavItem(Icons.radio, 'Radios', radioTabIndex),
        _buildBottomNavItem(
            Icons.podcasts_outlined, 'Podcasts', _podcastTabIndex),
        _buildBottomNavItem(Icons.person_outline,
            Locales.string(context, "profile"), _profileTabIndex),
      ],
    );

    if (isNight) {
      // LIVE NEON (night theme): same two-element structure as ABIDJAN
      // (separate mini-player bar + gap + nav card), dark/glow colors and a
      // matching radius instead of black/cream.
      const double liveNeonDockRadius = 16;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(liveNeonDockRadius),
            child: Container(color: liveNeonCardBg, child: floatingPlayer),
          ),
          const SizedBox(height: 10),
          Material(
            elevation: 5,
            shadowColor: black.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(liveNeonDockRadius),
              side: const BorderSide(color: liveNeonBorder),
            ),
            color: liveNeonCardBg,
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
              child: navRow,
            ),
          ),
        ],
      );
    }

    // ABIDJAN (day theme): the mini-player is its own separate black
    // rounded-rect bar, with a visible gap above the white nav card below
    // it — two distinct floating elements, not one card. Radius matches the
    // header's search field (16) for a consistent rounding across the
    // screen.
    const double abidjanDockRadius = 16;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(abidjanDockRadius),
          child: Container(color: black, child: floatingPlayer),
        ),
        const SizedBox(height: 10),
        Material(
          elevation: 5,
          shadowColor: black.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(abidjanDockRadius),
            side: const BorderSide(color: lightgray, width: 0.3),
          ),
          color: homeAccueilBg(context),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
            child: navRow,
          ),
        ),
      ],
    );
  }

  void _collapseFullPlayer() {
    setPlayerExpansion(0);
  }

  Widget _buildBottomNavItem(IconData icon, String label, int index) {
    final isSelected = _currentBottomNavIndex == index;
    final isNight = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          // Compte requires being logged in — otherwise the profile screen
          // has nothing to show (empty header, empty fields).
          if (index == _profileTabIndex && Constant.userID == null) {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const Login()));
            return;
          }
          // Collapse the sliding full-screen player when leaving the Radio
          // tab, so it doesn't keep covering whichever tab is now shown.
          if (index != radioTabIndex) {
            _collapseFullPlayer();
          }
          setState(() {
            _currentBottomNavIndex = index;
          });
        },
        child: isNight
            ? _buildNightNavItemContent(icon, label, isSelected)
            : _buildAbidjanNavItemContent(icon, label, isSelected),
      ),
    );
  }

  // Night mode — unchanged from before the ABIDJAN redesign.
  // LIVE NEON (night theme): same vertical icon-above-label layout as
  // ABIDJAN — the active tab gets a pink-to-blue gradient pill wrapped
  // around that stack instead of a solid color.
  Widget _buildNightNavItemContent(
      IconData icon, String label, bool isSelected) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20,
          color: isSelected ? white : liveNeonTextSecondary,
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? white : liveNeonTextSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      child: isSelected
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: liveNeonGradient),
                borderRadius: BorderRadius.circular(16),
              ),
              child: content,
            )
          : content,
    );
  }

  // ABIDJAN (day theme): icon stays above the label in both states, as in
  // the reference design — the active tab just gets a solid pill wrapped
  // around that same vertical stack, no side-by-side layout.
  Widget _buildAbidjanNavItemContent(
      IconData icon, String label, bool isSelected) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20,
          color: isSelected ? white : black.withValues(alpha: 0.45),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? white : black.withValues(alpha: 0.5),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      child: isSelected
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: dockActivePillBg(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: content,
            )
          : content,
    );
  }

  Widget _buildPageContent() {
    switch (_currentBottomNavIndex) {
      case radioTabIndex:
        return const RadioScreen();
      case _homeTabIndex:
        return _buildHomeContent();
      case _podcastTabIndex:
        return const Podcast();
      case _filmsTabIndex:
        return const LiveEvent();
      // Page Recherche désactivée
      // case _searchTabIndex:
      //   return Search(onBack: () {
      //     setState(() {
      //       _currentBottomNavIndex = _homeTabIndex;
      //     });
      //   });
      case _profileTabIndex:
        return Profile(onBack: () {
          setState(() {
            _currentBottomNavIndex = _homeTabIndex;
          });
        });
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return Consumer<HomeProvider>(builder: (context, homeprovider, child) {
      if ((homeprovider.bannerModel.result == null ||
              (homeprovider.bannerModel.result?.length ?? 0) == 0) &&
          (homeprovider.sectionList?.length ?? 0) == 0 &&
          !homeprovider.bannerLoading &&
          !homeprovider.sectionLoading) {
        return const Center(
          child: NoData(text: "", subTitle: ""),
        );
      } else {
        return RefreshIndicator(
          backgroundColor: white,
          color: colorAccent,
          displacement: 70,
          edgeOffset: 1.0,
          triggerMode: RefreshIndicatorTriggerMode.anywhere,
          strokeWidth: 3,
          onRefresh: () async {
            homeProvider.clearProvider();
            _fetchData(0);
          },
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 160),
            child: Column(
              children: [
                banner(),
                buildPage(),
                Utils.showBannerAd(context),
              ],
            ),
          ),
        );
      }
    });
  }

  /* Drawer & AppBar Start */

  Widget buildDrawer() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(30),
        bottomRight: Radius.circular(30),
      ),
      child: Drawer(
        elevation: 0,
        width: MediaQuery.of(context).size.width * 0.80,
        child: Column(
          children: [
            Expanded(
              child: SafeArea(
                child: Consumer<GeneralProvider>(
                    builder: (context, themeprovider, child) {
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        Consumer<ThemeProvider>(
                            builder: (context, themeprovider, child) {
                          return InkWell(
                            focusColor: transparent,
                            splashColor: transparent,
                            hoverColor: transparent,
                            highlightColor: transparent,
                            onTap: () {},
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
                              height: 60,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        MyImage(
                                          width: 25,
                                          height: 25,
                                          imagePath: "ic_darkmode.png",
                                          color: colorPrimary,
                                        ),
                                        SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.05),
                                        MyText(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surface,
                                          text: "darkmode",
                                          textalign: TextAlign.center,
                                          multilanguage: true,
                                          fontsize: Dimens.textTitle,
                                          inter: 1,
                                          maxline: 2,
                                          fontwaight: FontWeight.w500,
                                          overflow: TextOverflow.ellipsis,
                                          fontstyle: FontStyle.normal,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    activeThumbColor: black,
                                    activeTrackColor: gray,
                                    inactiveTrackColor: gray,
                                    value: themeprovider.mode ==
                                        AppThemeMode.night,
                                    onChanged: (value) async {
                                      final mode = value
                                          ? AppThemeMode.night
                                          : AppThemeMode.day;
                                      themeprovider.setMode(mode);
                                      await sharedpre.remove("theme_mode");
                                      await sharedpre.save(
                                          "theme_mode", mode.name);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        buildDrawerItem(
                          "ic_podcast.png",
                          "",
                          "podcast",
                          true,
                          () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                            AdHelper.showFullscreenAd(
                              context,
                              Constant.rewardAdType,
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) {
                                      return const Podcast();
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        divider(),
                        buildDrawerItem(
                          "ic_liveevent.png",
                          "",
                          "liveevents",
                          true,
                          () async {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                            AdHelper.showFullscreenAd(
                              context,
                              Constant.rewardAdType,
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) {
                                      return const LiveEvent();
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        divider(),
                        buildDrawerItem(
                          "ic_subscription.png",
                          "",
                          "subsciption",
                          true,
                          () async {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                            AdHelper.showFullscreenAd(
                              context,
                              Constant.rewardAdType,
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) {
                                      return const Subscription(openFrom: '');
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        divider(),
                        buildDrawerItem(
                            "ic_language.png", "", "changelanguage", true, () {
                          _languageChangeDialog();
                        }),
                        divider(),
                        buildDrawerItem("ic_rateapp.png", "", "rateapp", true,
                            () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                          showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) {
                                return Dialog(
                                  elevation: 5,
                                  insetPadding: const EdgeInsets.all(30),
                                  insetAnimationCurve: Curves.easeInExpo,
                                  insetAnimationDuration:
                                      const Duration(seconds: 1),
                                  backgroundColor: Colors.transparent,
                                  child: Container(
                                    width: MediaQuery.of(context).size.width,
                                    height: MediaQuery.of(context).size.height *
                                        0.35,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        RatingBar(
                                          initialRating: 0.0,
                                          direction: Axis.horizontal,
                                          allowHalfRating: true,
                                          itemSize: 45,
                                          glowColor: colorPrimary,
                                          unratedColor: gray,
                                          glow: false,
                                          itemCount: 5,
                                          ratingWidget: RatingWidget(
                                            full: const Icon(
                                              Icons.star,
                                              color: colorPrimary,
                                            ),
                                            half: const Icon(Icons.star_half,
                                                color: colorPrimary),
                                            empty: const Icon(Icons.star_border,
                                                color: lightgray),
                                          ),
                                          onRatingUpdate: (double value) {
                                            printLog("rating=> $value");
                                            ratingValue = value;
                                          },
                                        ),
                                        MyText(
                                            color: black,
                                            text: "enjoyingmyradio",
                                            textalign: TextAlign.center,
                                            fontsize: Dimens.textBig,
                                            maxline: 1,
                                            multilanguage: true,
                                            inter: 1,
                                            fontwaight: FontWeight.w700,
                                            overflow: TextOverflow.ellipsis,
                                            fontstyle: FontStyle.normal),
                                        MyText(
                                            color: lightgray,
                                            text:
                                                "tapastartorateitontheappstore",
                                            textalign: TextAlign.center,
                                            multilanguage: true,
                                            fontsize: Dimens.textMedium,
                                            inter: 1,
                                            maxline: 2,
                                            fontwaight: FontWeight.w500,
                                            overflow: TextOverflow.ellipsis,
                                            fontstyle: FontStyle.normal),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            InkWell(
                                              focusColor: transparent,
                                              splashColor: transparent,
                                              hoverColor: transparent,
                                              highlightColor: transparent,
                                              onTap: () async {
                                                if (ratingValue == 0.0) {
                                                  Utils.showToast(
                                                      "Please Enter Your Rating");
                                                } else {
                                                  // App Rating Api Call After Button Click
                                                  printLog(
                                                      "Clicked on rateApp");
                                                  await Utils.redirectToStore();
                                                }
                                              },
                                              child: Container(
                                                width: 120,
                                                height: 45,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  gradient:
                                                      const LinearGradient(
                                                          colors: [
                                                        colorAccent,
                                                        colorPrimary
                                                      ],
                                                          begin: Alignment
                                                              .centerLeft,
                                                          end: Alignment
                                                              .centerRight),
                                                  borderRadius:
                                                      BorderRadius.circular(50),
                                                ),
                                                child: MyText(
                                                    color: white,
                                                    text: "submit",
                                                    textalign: TextAlign.center,
                                                    fontsize: Dimens.textTitle,
                                                    inter: 1,
                                                    multilanguage: true,
                                                    maxline: 2,
                                                    fontwaight: FontWeight.w600,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    fontstyle:
                                                        FontStyle.normal),
                                              ),
                                            ),
                                            InkWell(
                                              focusColor: transparent,
                                              splashColor: transparent,
                                              hoverColor: transparent,
                                              highlightColor: transparent,
                                              onTap: () {
                                                Navigator.pop(context);
                                              },
                                              child: Container(
                                                width: 120,
                                                height: 45,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: gray, width: 1),
                                                  borderRadius:
                                                      BorderRadius.circular(50),
                                                ),
                                                child: MyText(
                                                    color: gray,
                                                    text: "cancel",
                                                    textalign: TextAlign.center,
                                                    fontsize: Dimens.textTitle,
                                                    multilanguage: true,
                                                    inter: 1,
                                                    maxline: 2,
                                                    fontwaight: FontWeight.w600,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    fontstyle:
                                                        FontStyle.normal),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              });
                        }),
                        divider(),
                        buildDrawerItem("ic_share.png", "", "shareapp", true,
                            () async {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                          await Utils.shareApp(Platform.isIOS
                              ? Constant.iosAppShareUrlDesc
                              : Constant.androidAppShareUrlDesc);
                        }),
                        divider(),
                        _buildPages(),
                        _buildSocialLink(),
                        const SizedBox(height: 10),
                        InkWell(
                          focusColor: transparent,
                          splashColor: transparent,
                          hoverColor: transparent,
                          highlightColor: transparent,
                          onTap: () {
                            printLog("userid=>${Constant.userID}");
                            if (Constant.userID == null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) {
                                    return const Login();
                                  },
                                ),
                              );
                            } else {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(25),
                                  ),
                                ),
                                builder: (context) {
                                  return Container(
                                    width: MediaQuery.of(context).size.width,
                                    height: MediaQuery.of(context).size.height *
                                        0.25,
                                    color: white,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        MyText(
                                          color: black,
                                          text: "areyousurewanttologout",
                                          multilanguage: true,
                                          textalign: TextAlign.center,
                                          fontsize: Dimens.textBig,
                                          inter: 1,
                                          maxline: 6,
                                          fontwaight: FontWeight.w500,
                                          overflow: TextOverflow.ellipsis,
                                          fontstyle: FontStyle.normal,
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            InkWell(
                                              focusColor: transparent,
                                              splashColor: transparent,
                                              hoverColor: transparent,
                                              highlightColor: transparent,
                                              onTap: () async {
                                                await _auth.signOut();
                                                await GoogleSignIn().signOut();

                                                await Utils.setUserId(null);
                                                getApi();
                                                if (!context.mounted) return;
                                                Navigator.pop(context);
                                                if (!mounted) return;
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) {
                                                      return const Login();
                                                    },
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                width: 100,
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.05,
                                                alignment: Alignment.center,
                                                decoration: const BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      colorPrimary,
                                                      colorPrimary,
                                                    ],
                                                    end: Alignment.bottomLeft,
                                                    begin:
                                                        Alignment.bottomRight,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(50)),
                                                ),
                                                child: MyText(
                                                    color: white,
                                                    text: "yes",
                                                    multilanguage: true,
                                                    textalign: TextAlign.center,
                                                    fontsize: Dimens.textTitle,
                                                    inter: 1,
                                                    maxline: 6,
                                                    fontwaight: FontWeight.w600,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    fontstyle:
                                                        FontStyle.normal),
                                              ),
                                            ),
                                            InkWell(
                                              focusColor: transparent,
                                              splashColor: transparent,
                                              hoverColor: transparent,
                                              highlightColor: transparent,
                                              onTap: () {
                                                Navigator.pop(context);
                                              },
                                              child: Container(
                                                width: 100,
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.05,
                                                alignment: Alignment.center,
                                                decoration: const BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      colorPrimary,
                                                      colorPrimary,
                                                    ],
                                                    end: Alignment.bottomLeft,
                                                    begin:
                                                        Alignment.bottomRight,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(50)),
                                                ),
                                                child: MyText(
                                                    color: white,
                                                    text: "no",
                                                    multilanguage: true,
                                                    textalign: TextAlign.center,
                                                    fontsize: Dimens.textTitle,
                                                    inter: 1,
                                                    maxline: 6,
                                                    fontwaight: FontWeight.w600,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    fontstyle:
                                                        FontStyle.normal),
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  );
                                },
                              );
                            }
                          },
                          child: Container(
                            margin: EdgeInsets.symmetric(vertical: 14),
                            height: MediaQuery.of(context).size.height * 0.065,
                            width: MediaQuery.of(context).size.width * 0.50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [colorAccent, colorPrimary],
                                  begin: Alignment.bottomLeft,
                                  end: Alignment.topRight,
                                ),
                                borderRadius: BorderRadius.circular(50)),
                            child: Consumer<HomeProvider>(
                              builder: (context, homeprovider, child) {
                                return MyText(
                                  color: white,
                                  multilanguage: true,
                                  text: Constant.userID != null
                                      ? "logout"
                                      : "login",
                                  fontwaight: FontWeight.w600,
                                  fontsize: Dimens.textBig,
                                  inter: 1,
                                  fontstyle: FontStyle.normal,
                                  maxline: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textalign: TextAlign.center,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        MyText(
                          color: lightgray,
                          text: "MyBonus v.${Constant.appVersion}",
                          fontwaight: FontWeight.w500,
                          fontsize: Dimens.textSmall,
                          inter: 1,
                          fontstyle: FontStyle.normal,
                          maxline: 1,
                          overflow: TextOverflow.ellipsis,
                          textalign: TextAlign.center,
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDrawerItem(String icon, String iconType, String name,
      bool isMultilang, dynamic onTap) {
    return InkWell(
      focusColor: transparent,
      splashColor: transparent,
      hoverColor: transparent,
      highlightColor: transparent,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
        height: 60,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: transparent,
              ),
              child: (iconType == "url")
                  ? MyNetworkImg2(
                      imgWidth: 30,
                      imgHeight: 30,
                      imageUrl: icon,
                      fit: BoxFit.contain,
                      // color: Theme.of(context).colorScheme.surface,
                      color: colorPrimary,
                    )
                  : MyImage(
                      width: 30,
                      height: 30,
                      imagePath: icon,
                      color: colorPrimary,
                    ),
            ),
            SizedBox(width: MediaQuery.of(context).size.width * 0.05),
            MyText(
              color: Theme.of(context).colorScheme.surface,
              text: name,
              textalign: TextAlign.center,
              multilanguage: isMultilang,
              fontsize: Dimens.textTitle,
              inter: 1,
              maxline: 2,
              fontwaight: FontWeight.w500,
              overflow: TextOverflow.ellipsis,
              fontstyle: FontStyle.normal,
            ),
          ],
        ),
      ),
    );
  }

  Widget appBar() {
    final bool isNight = Theme.of(context).brightness == Brightness.dark;
    return isNight ? _buildNightAppBar() : _buildAbidjanAppBar();
  }

  // Shared by both header themes: greeting word picked by hour bracket (all
  // localized), first name appended when available, date formatted in the
  // app's current language.
  ({String greeting, String dateLabel}) _greetingAndDate() {
    final now = DateTime.now();
    final String greetingKey = now.hour < 12
        ? "goodmorning"
        : (now.hour < 18 ? "goodafternoon" : "goodevening");
    final String greetingWord = Locales.string(context, greetingKey);
    final String? fullName =
        profileprovider.profileModel.result?[0].fullName?.toString();
    final String? firstName =
        (fullName != null && fullName.trim().isNotEmpty)
            ? fullName.trim().split(RegExp(r'\s+')).first
            : null;
    final String greeting =
        firstName != null ? "$greetingWord $firstName" : "$greetingWord !";
    final String currentLangCode = Localizations.localeOf(context).languageCode;
    final String dateLabel =
        DateFormat('EEEE d MMMM', currentLangCode).format(now).toUpperCase();
    return (greeting: greeting, dateLabel: dateLabel);
  }

  // ABIDJAN (day theme): brand mark + date/greeting + settings/bell circle
  // buttons, white search pill with a (visual-only) mic icon. Tapping the
  // search bar still opens Search() exactly as before.
  Widget _buildAbidjanAppBar() {
    final greetingInfo = _greetingAndDate();
    final String greeting = greetingInfo.greeting;
    final String dateLabel = greetingInfo.dateLabel;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 8,
                        offset: Offset(0, 2)),
                  ],
                ),
                child: MyImage(
                  width: 40,
                  height: 40,
                  imagePath: "logo_mybonus.png",
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.headphones,
                            size: 12, color: colorPrimary),
                        const SizedBox(width: 4),
                        Text(
                          Locales.string(context, "home").toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: black.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: gray,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    MyText(
                      color: black,
                      text: greeting,
                      multilanguage: false,
                      inter: 4,
                      fontsize: Dimens.textlargeBig,
                      fontwaight: FontWeight.w700,
                      maxline: 1,
                      textalign: TextAlign.left,
                      overflow: TextOverflow.ellipsis,
                      fontstyle: FontStyle.normal,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AbidjanCircleIconButton(
                icon: Icons.notifications_outlined,
                size: 40,
                onTap: () {
                  if (Constant.userID == null) {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => const Login()));
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationPage(),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Search()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 8,
                      offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: black.withValues(alpha: 0.4)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      Locales.string(context, "search"),
                      style: TextStyle(
                        fontSize: 14,
                        color: black.withValues(alpha: 0.4),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Visual-only — no voice-search backend exists yet.
                  Icon(Icons.mic_none, color: black.withValues(alpha: 0.4)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Night mode — unchanged from before the ABIDJAN redesign.
  // LIVE NEON (night theme): same header layout/logic as ABIDJAN (brand
  // mark + date/greeting + settings/bell circle buttons, search pill with a
  // visual-only mic icon) recolored for the neon palette. Settings gear is
  // kept alongside the bell for consistency with the day theme.
  Widget _buildNightAppBar() {
    final greetingInfo = _greetingAndDate();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: white,
                  shape: BoxShape.circle,
                ),
                child: MyImage(
                  width: 40,
                  height: 40,
                  imagePath: "logo_mybonus.png",
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.headphones,
                            size: 12, color: colorPrimary),
                        const SizedBox(width: 4),
                        Text(
                          Locales.string(context, "home").toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: liveNeonTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      greetingInfo.dateLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: liveNeonTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    MyText(
                      color: white,
                      text: greetingInfo.greeting,
                      multilanguage: false,
                      inter: 4,
                      fontsize: Dimens.textlargeBig,
                      fontwaight: FontWeight.w700,
                      maxline: 1,
                      textalign: TextAlign.left,
                      overflow: TextOverflow.ellipsis,
                      fontstyle: FontStyle.normal,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              LiveNeonCircleIconButton(
                icon: Icons.notifications_outlined,
                size: 40,
                onTap: () {
                  if (Constant.userID == null) {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => const Login()));
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationPage(),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Search()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: liveNeonCardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: liveNeonBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: liveNeonTextSecondary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      Locales.string(context, "search"),
                      style: const TextStyle(
                        color: liveNeonTextSecondary,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.mic_none,
                      color: liveNeonTextSecondary, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /* Drawer & AppBar End */

  Widget buildPage() {
    return Consumer<HomeProvider>(builder: (context, homeprovider, child) {
      if (homeprovider.sectionLoading && !homeprovider.loadmore) {
        return commanShimmer();
      } else {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              setSectioByType(),
              if (homeProvider.loadmore)
                SizedBox(
                  height: 50,
                  child: Utils.pageLoader(),
                )
              else
                const SizedBox.shrink(),
            ],
          ),
        );
      }
    });
  }

  Widget setSectioByType() {
    if (homeProvider.sectionListModel.status == 200 &&
        homeProvider.sectionList != null) {
      if ((homeProvider.sectionList?.length ?? 0) > 0) {
        return MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: ListView.builder(
            itemCount: homeProvider.sectionList?.length ?? 0,
            shrinkWrap: true,
            reverse: false,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (BuildContext context, int index) {
              if (homeProvider.sectionList?[index].data != null &&
                  (homeProvider.sectionList?[index].data?.length ?? 0) > 0) {
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
                                    text: homeProvider.sectionList?[index].title
                                            .toString() ??
                                        "",
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
                                    text: homeProvider
                                            .sectionList?[index].subTitle
                                            .toString() ??
                                        "",
                                    textalign: TextAlign.center,
                                    fontsize: Dimens.textSmall,
                                    maxline: 1,
                                    fontwaight: FontWeight.w400,
                                    overflow: TextOverflow.ellipsis,
                                    fontstyle: FontStyle.normal),
                              ],
                            ),
                          ),
                          homeProvider.sectionList?[index].viewAll == 1
                              ? InkWell(
                                  onTap: () {
                                    AdHelper.showFullscreenAd(
                                        context, Constant.interstialAdType, () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) {
                                            return ViewAll(
                                              sectionId: homeProvider
                                                      .sectionList?[index].id
                                                      .toString() ??
                                                  "",
                                              appbarTitle: homeProvider
                                                      .sectionList?[index].title
                                                      .toString() ??
                                                  "",
                                              isTitleMultiLang: false,
                                              screenLayout: homeProvider
                                                      .sectionList?[index]
                                                      .screenLayout
                                                      .toString() ??
                                                  "",
                                              sectionType: homeProvider
                                                      .sectionList?[index]
                                                      .type ??
                                                  0,
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
                          screenLayout: homeProvider
                                  .sectionList?[index].screenLayout
                                  .toString() ??
                              "",
                          type: homeProvider.sectionList?[index].type ?? 0,
                          sectionList: homeProvider.sectionList ?? []),
                      child: setSectionData(
                          index: index,
                          type: homeProvider.sectionList?[index].type ?? 0,
                          sectionList: homeProvider.sectionList ?? []),
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
      int? type,
      String? screenLayout,
      List<section.Result>? sectionList}) {
    if (type == 1) {
      if (screenLayout == "sqaure") {
        return Dimens.squareRadioHeight;
      } else if (screenLayout == "landscape") {
        return Dimens.landscapRadioHeight;
      } else if (screenLayout == "portrait") {
        return Dimens.portraitRadioHeight;
      } else if (screenLayout == "list") {
        return Dimens.listRowHeight *
            (sectionList?[sectionindex ?? 0].data?.length ?? 0);
      } else {
        return 0.0;
      }
    } else if (type == 2) {
      if (screenLayout == "sqaure") {
        return Dimens.squarePodcastHeight;
      } else if (screenLayout == "landscape") {
        return Dimens.landscapPodcastHeight;
      } else if (screenLayout == "portrait") {
        return Dimens.portraitPodcastHeight;
      } else if (screenLayout == "list") {
        return Dimens.listRowHeight *
            (sectionList?[sectionindex ?? 0].data?.length ?? 0);
      } else {
        return 0.0;
      }
    } else {
      if (screenLayout == "category") {
        // Both themes' category tiles show the category name and a
        // "Titres" caption below the block, so both need the extra height
        // — otherwise the caption gets clipped into (and painted over) the
        // section below it.
        return Dimens.categoryheight + 60;
      } else if (screenLayout == "language") {
        return Dimens.languageheight;
      } else if (screenLayout == "artist") {
        return Dimens.artistheight;
      } else if (screenLayout == "city") {
        return Dimens.cityheight;
      } else if (screenLayout == "live_event") {
        return Dimens.liveEventheight;
      } else {
        return 0.0;
      }
    }
  }

  Widget setSectionData(
      {required int index,
      required int type,
      required List<section.Result>? sectionList}) {
    if (type == 1) {
      if ((sectionList?[index].screenLayout.toString() ?? "") == "sqaure") {
        return squareRadio(index, sectionList);
      } else if ((sectionList?[index].screenLayout.toString() ?? "") ==
          "landscape") {
        return landscapRadio(index, sectionList);
      } else if ((sectionList?[index].screenLayout.toString() ?? "") ==
          "portrait") {
        return portraitRadio(index, sectionList);
      } else if ((sectionList?[index].screenLayout.toString() ?? "") ==
          "list") {
        return list(index, sectionList, type);
      } else {
        return const SizedBox.shrink();
      }
    } else if (type == 2) {
      if ((sectionList?[index].screenLayout.toString() ?? "") == "sqaure") {
        return squarePodcast(index, sectionList);
      } else if ((sectionList?[index].screenLayout.toString() ?? "") ==
          "landscape") {
        return landscapPodcast(index, sectionList);
      } else if ((sectionList?[index].screenLayout.toString() ?? "") ==
          "portrait") {
        return portraitPodcast(index, sectionList);
      } else if ((sectionList?[index].screenLayout.toString() ?? "") ==
          "list") {
        return list(index, sectionList, type);
      } else {
        return const SizedBox.shrink();
      }
    } else {
      if ((sectionList?[index].screenLayout.toString() ?? "") == "category") {
        return category(index, sectionList);
      } else if ((sectionList?[index].screenLayout.toString() ?? "") ==
          "language") {
        return language(index, sectionList);
      } else if ((sectionList?[index].screenLayout.toString() ?? "") ==
          "artist") {
        return artist(index, sectionList);
      } else if ((sectionList?[index].screenLayout.toString() ?? "") ==
          "city") {
        return city(index, sectionList);
      } else if ((sectionList?[index].screenLayout.toString() ?? "") ==
          "live_event") {
        return liveEvent(index, sectionList);
      } else {
        return const SizedBox.shrink();
      }
    }
  }

  /* ================= Banner Layout Start ================= */

  Widget banner() {
    return Consumer<HomeProvider>(builder: (context, homeprovider, child) {
      if (homeprovider.bannerLoading) {
        return bannerShimmer();
      } else {
        if (homeProvider.bannerModel.status == 200 &&
            homeProvider.bannerModel.result != null) {
          if ((homeProvider.bannerModel.result?.length ?? 0) > 0) {
            return SizedBox(
              width: MediaQuery.of(context).size.width,
              height: Dimens.homeBannerHeight,
              child: CarouselSlider.builder(
                itemCount: (homeprovider.bannerModel.result?.length ?? 0),
                carouselController: pageController,
                options: CarouselOptions(
                  initialPage: 0,
                  height: Dimens.homeBannerHeight,
                  enlargeCenterPage: false,
                  autoPlay: true,
                  autoPlayCurve: Curves.easeInOutQuart,
                  enableInfiniteScroll: false,
                  viewportFraction: 1.0,
                  autoPlayInterval:
                      Duration(milliseconds: Constant.bannerDuration),
                  autoPlayAnimationDuration:
                      Duration(milliseconds: Constant.animationDuration),
                  onPageChanged: (val, _) async {
                    homeProvider.setCurrentBanner(val);
                  },
                ),
                itemBuilder:
                    (BuildContext context, int index, int pageViewIndex) {
                  final bool isNight =
                      Theme.of(context).brightness == Brightness.dark;

                  void playThisRadioBanner() {
                    Utils.playAudio(
                        context,
                        "radio",
                        homeprovider.bannerModel.result?[index].isPremium ??
                            0,
                        homeprovider.bannerModel.result?[index].isBuy ?? 0,
                        homeprovider.bannerModel.result?[index].image
                                .toString() ??
                            "",
                        homeprovider.bannerModel.result?[index].name
                                .toString() ??
                            "",
                        'homebanner',
                        homeprovider.bannerModel.result?[index].songUrl
                                .toString() ??
                            "",
                        homeprovider.bannerModel.result?[index].name
                                .toString() ??
                            "",
                        homeprovider.bannerModel.result?[index].name
                                .toString() ??
                            "",
                        homeprovider.bannerModel.result?[index].id
                                .toString() ??
                            "",
                        "",
                        index,
                        homeprovider.bannerModel.result?.toList() ?? []);
                  }

                  Future<void> handleBannerTap() async {
                    if (homeprovider.bannerModel.result?[index].type == 1) {
                      /* Radio Banner */
                      playThisRadioBanner();
                    } else {
                          /* Podcast Banner */
                          final musicdetailProvider =
                              Provider.of<MusicDetailProvider>(context,
                                  listen: false);
                          await musicdetailProvider.getEpisodebyPodcastList(
                              homeprovider.bannerModel.result?[index].id
                                      .toString() ??
                                  "",
                              0);
                          if (!musicdetailProvider.loading) {
                            if (musicdetailProvider
                                        .getEpisodeByPodcstModel.status ==
                                    200 &&
                                ((musicdetailProvider.getEpisodeByPodcstModel
                                            .result?.length ??
                                        0) >
                                    0)) {
                              if (!context.mounted) return;
                              Utils.playAudio(
                                  context,
                                  "podcast",
                                  homeprovider.bannerModel.result?[index]
                                          .isPremium ??
                                      0,
                                  homeprovider
                                          .bannerModel.result?[index].isBuy ??
                                      0,
                                  homeprovider
                                          .bannerModel.result?[index].image
                                          .toString() ??
                                      "",
                                  homeprovider
                                          .bannerModel.result?[index].title
                                          .toString() ??
                                      "",
                                  '',
                                  musicdetailProvider
                                          .episodeList?[0].episodeAudio
                                          .toString() ??
                                      "",
                                  "",
                                  "",
                                  musicdetailProvider.episodeList?[0].id
                                          .toString() ??
                                      "",
                                  homeprovider.bannerModel.result?[index].id
                                          .toString() ??
                                      "",
                                  0,
                                  musicdetailProvider.episodeList?.toList() ??
                                      []);
                            }
                          }
                        }
                  }

                  return Container(
                    padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
                    child: InkWell(
                      focusColor: transparent,
                      splashColor: transparent,
                      hoverColor: transparent,
                      highlightColor: transparent,
                      onTap: handleBannerTap,
                      child: isNight
                          ? _buildLiveNeonBannerCard(
                              homeprovider, index, playThisRadioBanner)
                          : _buildAbidjanBannerCard(
                              homeprovider, index, playThisRadioBanner),
                    ),
                  );
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
    });
  }

  // ABIDJAN (day theme) banner card. Business logic (playThisRadioBanner,
  // handleBannerTap) is passed in / already wired on the outer InkWell —
  // this only builds the visual content.
  Widget _buildAbidjanBannerCard(
      HomeProvider homeprovider, int index, VoidCallback onPlayRadio) {
    final item = homeprovider.bannerModel.result?[index];
    final bool isRadio = item?.type == 1;
    final String title = isRadio
        ? (item?.name?.toString() ?? "")
        : (item?.title?.toString() ?? "");
    final String subtitle = isRadio
        ? [item?.artistName, item?.languageName, item?.cityName]
            .where((s) => s != null && s.toString().trim().isNotEmpty)
            .join(" · ")
            .toUpperCase()
        : (item?.artistName?.toString() ?? "");
    final bool isPremiumLocked = item?.isPremium == 1 && item?.isBuy == 0;

    Widget pillButton({
      required Color background,
      required Color foreground,
      required IconData icon,
      required String label,
      required VoidCallback onTap,
    }) {
      return InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: foreground, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: Dimens.homeBannerHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            isRadio
                ? const AbidjanBokehCard(index: 1)
                : MyNetworkImage(
                    fit: BoxFit.cover,
                    imgWidth: double.infinity,
                    imgHeight: double.infinity,
                    imageUrl: item?.landscapeImg?.toString() ??
                        item?.image?.toString() ??
                        "",
                  ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [transparent, Color(0x99000000)],
                ),
              ),
            ),
            if (isRadio)
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: colorPrimary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration:
                            const BoxDecoration(color: white, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        "EN DIRECT",
                        style: TextStyle(
                          color: white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration:
                      const BoxDecoration(color: colorPrimary, shape: BoxShape.circle),
                  child: const Icon(Icons.podcasts, color: white, size: 16),
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
                    text: title,
                    multilanguage: false,
                    inter: 4,
                    fontsize: Dimens.textlargeBig,
                    fontwaight: FontWeight.w700,
                    maxline: 1,
                    textalign: TextAlign.left,
                    overflow: TextOverflow.ellipsis,
                    fontstyle: FontStyle.normal,
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: white.withValues(alpha: 0.75),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (isRadio)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StreamBuilder<bool>(
                          stream: audioPlayer.playingStream,
                          builder: (context, snapshot) {
                            final isPlaying =
                                snapshot.data ?? audioPlayer.playing;
                            return pillButton(
                              background: white,
                              foreground: black,
                              icon: isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              label: isPlaying ? "En écoute" : "Écouter",
                              onTap: () {
                                if (isPlaying) {
                                  audioPlayer.pause();
                                } else {
                                  onPlayRadio();
                                }
                              },
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        pillButton(
                          background: black.withValues(alpha: 0.35),
                          foreground: white,
                          icon: Icons.videocam,
                          label: "Regarder",
                          onTap: () {
                            _collapseFullPlayer();
                            setState(() {
                              _currentBottomNavIndex = _filmsTabIndex;
                            });
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // LIVE NEON (night theme) banner card. Same shared logic as ABIDJAN's
  // version (playThisRadioBanner/handleBannerTap passed in, wired on the
  // outer InkWell) — only the palette differs: LiveNeonBokehCard instead of
  // AbidjanBokehCard, gradient buttons instead of solid-white/dark ones.
  Widget _buildLiveNeonBannerCard(
      HomeProvider homeprovider, int index, VoidCallback onPlayRadio) {
    final item = homeprovider.bannerModel.result?[index];
    final bool isRadio = item?.type == 1;
    final String title = isRadio
        ? (item?.name?.toString() ?? "")
        : (item?.title?.toString() ?? "");
    final String subtitle = isRadio
        ? [item?.artistName, item?.languageName, item?.cityName]
            .where((s) => s != null && s.toString().trim().isNotEmpty)
            .join(" · ")
            .toUpperCase()
        : (item?.artistName?.toString() ?? "");
    final bool isPremiumLocked = item?.isPremium == 1 && item?.isBuy == 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: Dimens.homeBannerHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            isRadio
                ? const LiveNeonBokehCard(index: 1)
                : MyNetworkImage(
                    fit: BoxFit.cover,
                    imgWidth: double.infinity,
                    imgHeight: double.infinity,
                    imageUrl: item?.landscapeImg?.toString() ??
                        item?.image?.toString() ??
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
            if (isRadio)
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: colorPrimary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                            color: white, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        "EN DIRECT",
                        style: TextStyle(
                          color: white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                      color: colorPrimary, shape: BoxShape.circle),
                  child: const Icon(Icons.podcasts, color: white, size: 16),
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
                    text: title,
                    multilanguage: false,
                    inter: 4,
                    fontsize: Dimens.textlargeBig,
                    fontwaight: FontWeight.w700,
                    maxline: 1,
                    textalign: TextAlign.left,
                    overflow: TextOverflow.ellipsis,
                    fontstyle: FontStyle.normal,
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: liveNeonTextSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (isRadio)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StreamBuilder<bool>(
                          stream: audioPlayer.playingStream,
                          builder: (context, snapshot) {
                            final isPlaying =
                                snapshot.data ?? audioPlayer.playing;
                            return LiveNeonGradientButton(
                              icon: isPlaying ? Icons.pause : Icons.play_arrow,
                              label: isPlaying ? "En écoute" : "Écouter",
                              onTap: () {
                                if (isPlaying) {
                                  audioPlayer.pause();
                                } else {
                                  onPlayRadio();
                                }
                              },
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        LiveNeonOutlineButton(
                          icon: Icons.videocam,
                          label: "Regarder",
                          onTap: () {
                            _collapseFullPlayer();
                            setState(() {
                              _currentBottomNavIndex = _filmsTabIndex;
                            });
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget bannerShimmer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
      child: CustomWidget.roundcorner(height: Dimens.homeBannerHeight),
    );
  }

  /* ================= Banner Layout End ================= */

  /* ================ Radio Layout's ================= */

  Widget squareRadio(int sectionindex, List<section.Result>? sectionList) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: Dimens.squareRadioHeight,
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: ListView.separated(
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
            scrollDirection: Axis.horizontal,
            itemCount: sectionList?[sectionindex].data?.length ?? 0,
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              return InkWell(
                focusColor: transparent,
                splashColor: transparent,
                hoverColor: transparent,
                highlightColor: transparent,
                onTap: () {
                  Utils.playAudio(
                      context,
                      "radio",
                      sectionList?[sectionindex].data?[index].isPremium ?? 0,
                      sectionList?[sectionindex].data?[index].isBuy ?? 0,
                      sectionList?[sectionindex]
                              .data?[index]
                              .image
                              .toString() ??
                          "",
                      sectionList?[sectionindex].data?[index].name.toString() ??
                          "",
                      'homebanner',
                      sectionList?[sectionindex]
                              .data?[index]
                              .songUrl
                              .toString() ??
                          "",
                      sectionList?[sectionindex]
                              .data?[index]
                              .languageName
                              .toString() ??
                          "",
                      sectionList?[sectionindex]
                              .data?[index]
                              .artistName
                              .toString() ??
                          "",
                      sectionList?[sectionindex].data?[index].id.toString() ??
                          "",
                      "",
                      index,
                      sectionList?[sectionindex].data ?? []);
                },
                child: Container(
                  alignment: Alignment.center,
                  width: Dimens.squareRadiowidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: MyNetworkImage(
                              imgWidth: MediaQuery.of(context).size.width,
                              imgHeight: 130,
                              imageUrl: sectionList?[sectionindex]
                                      .data?[index]
                                      .image
                                      .toString() ??
                                  "",
                              fit: BoxFit.cover,
                            ),
                          ),
                          sectionList?[sectionindex].data?[index].isPremium ==
                                      1 &&
                                  sectionList?[sectionindex]
                                          .data?[index]
                                          .isBuy ==
                                      0
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
                                          borderRadius:
                                              BorderRadius.circular(50),
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
                      MyText(
                        color: Theme.of(context).colorScheme.surface,
                        text: sectionList?[sectionindex]
                                .data?[index]
                                .name
                                .toString() ??
                            "",
                        textalign: TextAlign.center,
                        fontsize: Dimens.textMedium,
                        inter: 1,
                        maxline: 2,
                        fontwaight: FontWeight.w500,
                        overflow: TextOverflow.ellipsis,
                        fontstyle: FontStyle.normal,
                      ),
                    ],
                  ),
                ),
              );
            }),
      ),
    );
  }

  Widget landscapRadio(int sectionindex, List<section.Result>? sectionList) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: Dimens.landscapRadioHeight,
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: ListView.separated(
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
            scrollDirection: Axis.horizontal,
            itemCount: sectionList?[sectionindex].data?.length ?? 0,
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              return InkWell(
                focusColor: transparent,
                splashColor: transparent,
                hoverColor: transparent,
                highlightColor: transparent,
                onTap: () async {
                  Utils.playAudio(
                      context,
                      "radio",
                      sectionList?[sectionindex].data?[index].isPremium ?? 0,
                      sectionList?[sectionindex].data?[index].isBuy ?? 0,
                      sectionList?[sectionindex]
                              .data?[index]
                              .image
                              .toString() ??
                          "",
                      sectionList?[sectionindex].data?[index].name.toString() ??
                          "",
                      'homebanner',
                      sectionList?[sectionindex]
                              .data?[index]
                              .songUrl
                              .toString() ??
                          "",
                      sectionList?[sectionindex]
                              .data?[index]
                              .languageName
                              .toString() ??
                          "",
                      sectionList?[sectionindex]
                              .data?[index]
                              .artistName
                              .toString() ??
                          "",
                      sectionList?[sectionindex].data?[index].id.toString() ??
                          "",
                      "",
                      index,
                      sectionList?[sectionindex].data?.toList() ?? []);
                },
                child: SizedBox(
                  width: Dimens.landscapRadiowidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: MyNetworkImage(
                              imgWidth: MediaQuery.of(context).size.width,
                              imgHeight: 100,
                              imageUrl: sectionList?[sectionindex]
                                      .data?[index]
                                      .image
                                      .toString() ??
                                  "",
                              fit: BoxFit.cover,
                            ),
                          ),
                          sectionList?[sectionindex].data?[index].isPremium ==
                                      1 &&
                                  sectionList?[sectionindex]
                                          .data?[index]
                                          .isBuy ==
                                      0
                              ? Positioned.fill(
                                  top: 5,
                                  left: 5,
                                  right: 5,
                                  child: Align(
                                    alignment: Alignment.topLeft,
                                    child: Container(
                                        width: 30,
                                        height: 30,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(50),
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
                      MyText(
                        color: Theme.of(context).colorScheme.surface,
                        text: sectionList?[sectionindex]
                                .data?[index]
                                .name
                                .toString() ??
                            "",
                        textalign: TextAlign.left,
                        fontsize: Dimens.textMedium,
                        inter: 1,
                        maxline: 2,
                        fontwaight: FontWeight.w500,
                        overflow: TextOverflow.ellipsis,
                        fontstyle: FontStyle.normal,
                      ),
                    ],
                  ),
                ),
              );
            }),
      ),
    );
  }

  Widget portraitRadio(int sectionindex, List<section.Result>? sectionList) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: Dimens.portraitRadioHeight,
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: ListView.separated(
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
            scrollDirection: Axis.horizontal,
            itemCount: sectionList?[sectionindex].data?.length ?? 0,
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              return InkWell(
                focusColor: transparent,
                splashColor: transparent,
                hoverColor: transparent,
                highlightColor: transparent,
                onTap: () {
                  Utils.playAudio(
                      context,
                      "radio",
                      sectionList?[sectionindex].data?[index].isPremium ?? 0,
                      sectionList?[sectionindex].data?[index].isBuy ?? 0,
                      sectionList?[sectionindex]
                              .data?[index]
                              .image
                              .toString() ??
                          "",
                      sectionList?[sectionindex].data?[index].name.toString() ??
                          "",
                      'homebanner',
                      sectionList?[sectionindex]
                              .data?[index]
                              .songUrl
                              .toString() ??
                          "",
                      sectionList?[sectionindex]
                              .data?[index]
                              .languageName
                              .toString() ??
                          "",
                      sectionList?[sectionindex]
                              .data?[index]
                              .artistName
                              .toString() ??
                          "",
                      sectionList?[sectionindex].data?[index].id.toString() ??
                          "",
                      "",
                      index,
                      sectionList?[sectionindex].data ?? []);
                },
                child: SizedBox(
                  width: Dimens.portraitRadiowidth,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: MyNetworkImage(
                              imgWidth: MediaQuery.of(context).size.width,
                              imgHeight: 150,
                              imageUrl: sectionList?[sectionindex]
                                      .data?[index]
                                      .image
                                      .toString() ??
                                  "",
                              fit: BoxFit.cover,
                            ),
                          ),
                          sectionList?[sectionindex].data?[index].isPremium ==
                                      1 &&
                                  sectionList?[sectionindex]
                                          .data?[index]
                                          .isBuy ==
                                      0
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
                                          borderRadius:
                                              BorderRadius.circular(50),
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
                      MyText(
                        color: Theme.of(context).colorScheme.surface,
                        text: sectionList?[sectionindex]
                                .data?[index]
                                .name
                                .toString() ??
                            "",
                        textalign: TextAlign.center,
                        fontsize: Dimens.textMedium,
                        inter: 1,
                        maxline: 2,
                        fontwaight: FontWeight.w500,
                        overflow: TextOverflow.ellipsis,
                        fontstyle: FontStyle.normal,
                      ),
                    ],
                  ),
                ),
              );
            }),
      ),
    );
  }

  /* ================== Radio Layout's ================= */

  /* ================ Podcast Layout's ================ */

  Widget squarePodcast(int sectionindex, List<section.Result>? sectionList) {
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

  Widget landscapPodcast(int sectionindex, List<section.Result>? sectionList) {
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

  Widget portraitPodcast(int sectionindex, List<section.Result>? sectionList) {
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

/* ============================ Other Layout Start ======================= */

  // ABIDJAN (day theme) category tiles: a small representative icon rather
  // than the category's own image — visual-only heuristic keyed off common
  // category-name keywords, since categories are free-text from the backend
  // and there's no dedicated icon field to key off instead.
  IconData _categoryIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('popul') || n.contains('tendance') || n.contains('trend')) {
      return Icons.trending_up;
    } else if (n.contains('gospel') || n.contains('louange')) {
      return Icons.church;
    } else if (n.contains('coupé') ||
        n.contains('coupe') ||
        n.contains('decal') || n.contains('décal')) {
      return Icons.content_cut;
    } else if (n.contains('sport')) {
      return Icons.sports_soccer;
    } else if (n.contains('info') || n.contains('actualit')) {
      return Icons.newspaper;
    } else if (n.contains('humour') || n.contains('comedie') ||
        n.contains('comédie')) {
      return Icons.theater_comedy;
    } else if (n.contains('enfant') || n.contains('kids')) {
      return Icons.child_care;
    } else if (n.contains('musi') || n.contains('music')) {
      return Icons.music_note;
    } else {
      return Icons.radio;
    }
  }

  /* Category */
  Widget category(int sectionindex, List<section.Result>? sectionList) {
    return Column(
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width,
          // Both themes' cards show a name + "Titres" caption below the
          // block now, so both need the taller row (see the matching fix
          // in getRemainingDataHeight below).
          height: Dimens.categoryheight + 60,
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(9, 0, 9, 0),
              scrollDirection: Axis.horizontal,
              itemCount: sectionList?[sectionindex].data?.length ?? 0,
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final bool isNight =
                    Theme.of(context).brightness == Brightness.dark;
                final categoryName = sectionList?[sectionindex]
                        .data?[index]
                        .name
                        .toString() ??
                    "";
                void openCategory() {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return RadioById(
                          itemId: sectionList?[sectionindex]
                                  .data?[index]
                                  .id
                                  .toString() ??
                              "",
                          viewType: "category",
                          title: categoryName,
                          languagegId: "",
                        );
                      },
                    ),
                  );
                }

                // LIVE NEON (night theme): same solid-block + icon-badge
                // pattern as ABIDJAN, using the neon gradient palette
                // instead. No play-button overlay, matching the day design.
                if (isNight) {
                  final Color neonCardColor = liveNeonBokehGradients[
                          index % liveNeonBokehGradients.length]
                      .first;
                  return Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: InkWell(
                      focusColor: transparent,
                      splashColor: transparent,
                      hoverColor: transparent,
                      highlightColor: transparent,
                      onTap: openCategory,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.19,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              height:
                                  MediaQuery.of(context).size.height * 0.09,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: neonCardColor,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              padding: const EdgeInsets.all(8),
                              alignment: Alignment.topLeft,
                              child: Container(
                                width: 26,
                                height: 26,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _categoryIcon(categoryName),
                                  color: neonCardColor,
                                  size: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            MyText(
                              color: white,
                              text: categoryName,
                              textalign: TextAlign.center,
                              fontsize: Dimens.textSmall,
                              inter: 1,
                              maxline: 1,
                              fontwaight: FontWeight.w700,
                              overflow: TextOverflow.ellipsis,
                              fontstyle: FontStyle.normal,
                            ),
                            const Text(
                              "Titres",
                              style: TextStyle(
                                color: liveNeonTextSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // ABIDJAN (day theme): solid-color block with a small
                // representative icon badge, count caption below
                // (visual-only — no per-category count data exists).
                final Color cardColor = abidjanBokehGradients[
                        index % abidjanBokehGradients.length]
                    .first;
                return Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: InkWell(
                    focusColor: transparent,
                    splashColor: transparent,
                    hoverColor: transparent,
                    highlightColor: transparent,
                    onTap: openCategory,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.19,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: MediaQuery.of(context).size.height * 0.09,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            padding: const EdgeInsets.all(8),
                            alignment: Alignment.topLeft,
                            child: Container(
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _categoryIcon(categoryName),
                                color: cardColor,
                                size: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          MyText(
                            color: black,
                            text: categoryName,
                            textalign: TextAlign.center,
                            fontsize: Dimens.textSmall,
                            inter: 1,
                            maxline: 1,
                            fontwaight: FontWeight.w700,
                            overflow: TextOverflow.ellipsis,
                            fontstyle: FontStyle.normal,
                          ),
                          // Visual-only — no per-category title count exists
                          // in the API.
                          Text(
                            "Titres",
                            style: TextStyle(
                              color: gray,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /* List Row Layout - used for "Podcasts populaires" / "Derniers titres" style sections */
  Widget list(int sectionindex, List<section.Result>? sectionList, int type) {
    final data = sectionList?[sectionindex].data ?? [];
    return Column(
      children: List.generate(data.length, (index) {
        final item = data[index];
        final isPremiumLocked =
            (item.isPremium ?? 0) == 1 && (item.isBuy ?? 0) == 0;

        Future<void> playItem() async {
          if (type == 1) {
            Utils.playAudio(
                context,
                "radio",
                item.isPremium ?? 0,
                item.isBuy ?? 0,
                item.image.toString(),
                item.name.toString(),
                'homebanner',
                item.songUrl.toString(),
                item.languageName.toString(),
                item.artistName.toString(),
                item.id.toString(),
                "",
                index,
                data.toList());
          } else {
            final musicdetailProvider =
                Provider.of<MusicDetailProvider>(context, listen: false);
            await musicdetailProvider.getEpisodebyPodcastList(
                item.id.toString(), 0);
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
                    item.isPremium ?? 0,
                    item.isBuy ?? 0,
                    item.landscapeImg.toString(),
                    item.title.toString(),
                    '',
                    musicdetailProvider.episodeList?[0].episodeAudio
                            .toString() ??
                        "",
                    "",
                    musicdetailProvider.episodeList?[0].description
                            .toString() ??
                        "",
                    musicdetailProvider.episodeList?[0].id.toString() ?? "",
                    item.id.toString(),
                    0,
                    musicdetailProvider.episodeList?.toList() ?? []);
              }
            }
          }
        }

        void onFavourite() {
          if (Constant.userID == null) {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const Login()));
            return;
          }
          Provider.of<AddFavouriteProvider>(context, listen: false)
              .getAddFavourite(Constant.userID ?? "", item.id.toString());
          Utils.showToast("Ajouté aux favoris");
        }

        void onShare() {
          Utils.shareApp(
              "${type == 1 ? item.name : item.title}\n\n${Constant.androidAppShareUrlDesc}");
        }

        return SectionRowTile(
          imageUrl:
              type == 1 ? item.image.toString() : item.landscapeImg.toString(),
          title: (type == 1 ? item.name : item.title).toString(),
          subtitle: (type == 1 ? item.artistName : item.description) ?? "",
          isPremium: isPremiumLocked,
          onTap: playItem,
          onPlayTap: playItem,
          onFavouriteTap: onFavourite,
          onShareTap: onShare,
        );
      }),
    );
  }

  /* Language */
  Widget language(int sectionindex, List<section.Result>? sectionList) {
    return SizedBox(
      height: Dimens.languageheight,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
        scrollDirection: Axis.horizontal,
        child: Wrap(spacing: -1, direction: Axis.vertical, children: [
          ...List.generate(
            sectionList?[sectionindex].data?.length ?? 0,
            (index) => InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return RadioById(
                        itemId: sectionList?[sectionindex]
                                .data?[index]
                                .id
                                .toString() ??
                            "",
                        viewType: "language",
                        title: sectionList?[sectionindex]
                                .data?[index]
                                .name
                                .toString() ??
                            "",
                        languagegId: sectionList?[sectionindex]
                                .data?[index]
                                .id
                                .toString() ??
                            "",
                      );
                    },
                  ),
                );
              },
              child: Stack(
                children: [
                  Container(
                    width: 140,
                    height: 40,
                    margin: const EdgeInsets.all(5),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: MyNetworkImage(
                          imgWidth: MediaQuery.of(context).size.width,
                          imgHeight: MediaQuery.of(context).size.height,
                          imageUrl: sectionList?[sectionindex]
                                  .data?[index]
                                  .image
                                  .toString() ??
                              "",
                          fit: BoxFit.cover),
                    ),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.center,
                      child: MyText(
                          color: white,
                          text: (sectionList?[sectionindex].data?[index].name ==
                                      "" ||
                                  sectionList?[sectionindex]
                                          .data?[index]
                                          .name
                                          .toString() ==
                                      "false")
                              ? "-"
                              : sectionList?[sectionindex]
                                      .data?[index]
                                      .name
                                      .toString() ??
                                  "",
                          fontsize: Dimens.textSmall,
                          overflow: TextOverflow.ellipsis,
                          maxline: 1,
                          fontwaight: FontWeight.w600,
                          textalign: TextAlign.center,
                          fontstyle: FontStyle.normal),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  /* City */
  Widget city(int sectionindex, List<section.Result>? sectionList) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: Dimens.cityheight,
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: ListView.separated(
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
          scrollDirection: Axis.horizontal,
          itemCount: sectionList?[sectionindex].data?.length ?? 0,
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            return InkWell(
              focusColor: transparent,
              splashColor: transparent,
              hoverColor: transparent,
              highlightColor: transparent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return RadioById(
                        itemId: sectionList?[sectionindex]
                                .data?[index]
                                .id
                                .toString() ??
                            "",
                        viewType: "category",
                        title: sectionList?[sectionindex]
                                .data?[index]
                                .name
                                .toString() ??
                            "",
                        languagegId: "",
                      );
                    },
                  ),
                );
              },
              child: Container(
                width: 95,
                height: MediaQuery.of(context).size.height,
                decoration: BoxDecoration(
                    color: Theme.of(context).secondaryHeaderColor,
                    borderRadius: BorderRadius.circular(15)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      child: MyNetworkImage(
                        imgWidth: MediaQuery.of(context).size.width,
                        imgHeight: 85,
                        imageUrl: sectionList?[sectionindex]
                                .data?[index]
                                .image
                                .toString() ??
                            "",
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.fromLTRB(7, 0, 7, 0),
                      child: MyText(
                          color: Theme.of(context).colorScheme.surface,
                          text: sectionList?[sectionindex]
                                  .data?[index]
                                  .name
                                  .toString() ??
                              "",
                          textalign: TextAlign.center,
                          fontsize: Dimens.textSmall,
                          inter: 1,
                          maxline: 1,
                          fontwaight: FontWeight.w500,
                          overflow: TextOverflow.ellipsis,
                          fontstyle: FontStyle.normal),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /* Artist */
  Widget artist(int sectionindex, List<section.Result>? sectionList) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: Dimens.artistheight,
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: sectionList?[sectionindex].data?.length,
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            return InkWell(
              focusColor: transparent,
              splashColor: transparent,
              hoverColor: transparent,
              highlightColor: transparent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return RadioById(
                        itemId: sectionList?[sectionindex]
                                .data?[index]
                                .id
                                .toString() ??
                            "",
                        viewType: "artist",
                        title: sectionList?[sectionindex]
                                .data?[index]
                                .name
                                .toString() ??
                            "",
                        languagegId: "",
                      );
                    },
                  ),
                );
              },
              radius: 60.0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(60),
                      child: MyNetworkImage(
                        imgWidth: 90,
                        imageUrl: sectionList?[sectionindex]
                                .data?[index]
                                .image
                                .toString() ??
                            "",
                        imgHeight: 90,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 0.005),
                    Container(
                      alignment: Alignment.center,
                      width: MediaQuery.of(context).size.width * 0.25,
                      child: MyText(
                          color: Theme.of(context).colorScheme.surface,
                          inter: 1,
                          text: sectionList?[sectionindex]
                                  .data?[index]
                                  .name
                                  .toString() ??
                              "",
                          fontsize: Dimens.textMedium,
                          fontwaight: FontWeight.w500,
                          maxline: 1,
                          overflow: TextOverflow.ellipsis,
                          textalign: TextAlign.center,
                          fontstyle: FontStyle.normal),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /* Live Event  */
  Widget liveEvent(int sectionindex, List<section.Result>? sectionList) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: Dimens.liveEventheight,
      alignment: Alignment.centerLeft,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
        itemCount: sectionList?[sectionindex].data?.length ?? 0,
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          return InkWell(
            focusColor: transparent,
            splashColor: transparent,
            hoverColor: transparent,
            highlightColor: transparent,
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
              } else {
                if (sectionList?[sectionindex].data?[index].isPaid == 1 &&
                    sectionList?[sectionindex].data?[index].isJoin == 0) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return AllPayment(
                          payType: 'liveevent',
                          itemId: sectionList?[sectionindex]
                                  .data?[index]
                                  .id
                                  .toString() ??
                              '',
                          price: sectionList?[sectionindex]
                                  .data?[index]
                                  .price
                                  .toString() ??
                              '',
                          itemTitle: sectionList?[sectionindex]
                                  .data?[index]
                                  .title
                                  .toString() ??
                              '',
                          typeId: '',
                          contentType: sectionList?[sectionindex]
                                  .data?[index]
                                  .type
                                  .toString() ??
                              '',
                          productPackage: '',
                          currency: '',
                        );
                      },
                    ),
                  );
                } else {
                  if (sectionList?[sectionindex].data?[index].type == 1) {
                    /* Audio */
                    musicManager.playSingleSong(
                        sectionList?[sectionindex].data?[index].id.toString() ??
                            "",
                        sectionList?[sectionindex]
                                .data?[index]
                                .title
                                .toString() ??
                            "",
                        sectionList?[sectionindex]
                                .data?[index]
                                .songUrl
                                .toString() ??
                            "",
                        sectionList?[sectionindex]
                                .data?[index]
                                .landscapeImg
                                .toString() ??
                            "",
                        "");
                  } else {
                    /* Video */
                    Utils.openPlayer(
                        context: context,
                        videoId: sectionList?[sectionindex]
                                .data?[index]
                                .id
                                .toString() ??
                            "",
                        videoUrl: sectionList?[sectionindex]
                                .data?[index]
                                .link
                                .toString() ??
                            "",
                        vUploadType: "external",
                        videoThumb: sectionList?[sectionindex]
                                .data?[index]
                                .landscapeImg
                                .toString() ??
                            "",
                        stoptime: "",
                        iscontinueWatching: false);
                  }
                }
              }
            },
            child: Container(
              width: Dimens.liveEventWidth,
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: MyNetworkImage(
                            imgHeight: 140,
                            imageUrl: sectionList?[sectionindex]
                                    .data?[index]
                                    .landscapeImg
                                    .toString() ??
                                "",
                            fit: BoxFit.cover),
                      ),
                      // "EN DIRECT" badge — disabled per request.
                      // Positioned.fill(
                      //   top: 5,
                      //   left: 5,
                      //   right: 5,
                      //   child: Align(
                      //     alignment: Alignment.topLeft,
                      //     child: Container(
                      //       width: 70,
                      //       height: 25,
                      //       alignment: Alignment.center,
                      //       decoration: BoxDecoration(
                      //         borderRadius: BorderRadius.circular(50),
                      //         color: colorPrimary,
                      //       ),
                      //       child: MyText(
                      //           color: white,
                      //           multilanguage: true,
                      //           text: "live",
                      //           textalign: TextAlign.left,
                      //           fontsize: Dimens.textSmall,
                      //           maxline: 2,
                      //           fontwaight: FontWeight.w600,
                      //           overflow: TextOverflow.ellipsis,
                      //           fontstyle: FontStyle.normal),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          MyText(
                              color: Theme.of(context).colorScheme.surface,
                              multilanguage: false,
                              text: sectionList?[sectionindex]
                                      .data?[index]
                                      .title
                                      .toString() ??
                                  "",
                              textalign: TextAlign.left,
                              fontsize: Dimens.textSmall,
                              maxline: 2,
                              fontwaight: FontWeight.w600,
                              overflow: TextOverflow.ellipsis,
                              fontstyle: FontStyle.normal),
                          const SizedBox(height: 5),
                          if (sectionList?[sectionindex]
                                      .data?[index]
                                      .isPaid
                                      .toString() ==
                                  "1" &&
                              sectionList?[sectionindex]
                                      .data?[index]
                                      .isJoin
                                      .toString() ==
                                  "0")
                            MyText(
                              color: colorPrimary,
                              inter: 1,
                              text:
                                  "${Constant.currencySymbol}${sectionList?[sectionindex].data?[index].price.toString() ?? ""}",
                              fontsize: Dimens.textTitle,
                              fontwaight: FontWeight.w700,
                              maxline: 2,
                              overflow: TextOverflow.ellipsis,
                              textalign: TextAlign.left,
                              fontstyle: FontStyle.normal,
                            )
                          else if (sectionList?[sectionindex]
                                      .data?[index]
                                      .isPaid
                                      .toString() ==
                                  "1" &&
                              sectionList?[sectionindex]
                                      .data?[index]
                                      .isJoin
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
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

/* =================== Other Layout End ======================= */

  Widget divider() {
    return Container(
      color: lightgray,
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.fromLTRB(15, 0, 15, 0),
      height: 1,
    );
  }

  Future exitDilog(BuildContext buildContext) {
    return showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          elevation: 16,
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.28,
            decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                MyImage(
                  width: 140,
                  height: 140,
                  isAppIcon: true,
                  imagePath: "appicon.png",
                  fit: BoxFit.fill,
                ),
                const SizedBox(height: 15),
                MyText(
                  color: Theme.of(context).colorScheme.surface,
                  text: "Souhaitez-vous quitter ?",
                  maxline: 1,
                  multilanguage: false,
                  fontwaight: FontWeight.w500,
                  fontsize: Dimens.textTitle,
                  overflow: TextOverflow.ellipsis,
                  textalign: TextAlign.center,
                  fontstyle: FontStyle.normal,
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    InkWell(
                      focusColor: transparent,
                      splashColor: transparent,
                      hoverColor: transparent,
                      highlightColor: transparent,
                      onTap: () {
                        exit(0);
                      },
                      child: Container(
                        width: 100,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                homeSearchBarBg(context),
                                homeSearchBarBg(context),
                              ],
                              end: Alignment.bottomLeft,
                              begin: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(50)),
                        child: MyText(
                          color: white,
                          text: "Quitter",
                          multilanguage: false,
                          maxline: 1,
                          fontwaight: FontWeight.w500,
                          fontsize: Dimens.textMedium,
                          overflow: TextOverflow.ellipsis,
                          textalign: TextAlign.center,
                          fontstyle: FontStyle.normal,
                        ),
                      ),
                    ),
                    InkWell(
                      focusColor: transparent,
                      splashColor: transparent,
                      hoverColor: transparent,
                      highlightColor: transparent,
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 100,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                homeSearchBarBg(context),
                                homeSearchBarBg(context),
                              ],
                              end: Alignment.bottomLeft,
                              begin: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(50)),
                        child: MyText(
                          color: white,
                          text: "Rester",
                          multilanguage: false,
                          maxline: 1,
                          fontwaight: FontWeight.w500,
                          fontsize: Dimens.textMedium,
                          overflow: TextOverflow.ellipsis,
                          textalign: TextAlign.center,
                          fontstyle: FontStyle.normal,
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 5),
              ],
            ),
          ),
        );
      },
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

  void _languageChangeDialog() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      clipBehavior: Clip.antiAliasWithSaveLayer,
      backgroundColor: transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, state) {
            return DraggableScrollableSheet(
              initialChildSize: 0.55,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                return ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    color: Theme.of(context).bottomSheetTheme.backgroundColor,
                    padding: const EdgeInsets.all(23),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MyText(
                          color: Theme.of(context).colorScheme.surface,
                          text: "selectlanguage",
                          multilanguage: true,
                          textalign: TextAlign.start,
                          fontsize: Dimens.textTitle,
                          fontwaight: FontWeight.bold,
                          maxline: 1,
                          overflow: TextOverflow.ellipsis,
                          fontstyle: FontStyle.normal,
                        ),

                        /* English */
                        Expanded(
                          child: SingleChildScrollView(
                            controller: scrollController,
                            child: Column(
                              children: [
                                const SizedBox(height: 20),
                                _buildLanguage(
                                  langName: "English",
                                  onClick: () {
                                    state(() {});
                                    LocaleNotifier.of(context)?.change('en');
                                    Navigator.pop(context);
                                  },
                                ),

                                /* Afrikaans */
                                const SizedBox(height: 20),
                                _buildLanguage(
                                  langName: "Afrikaans",
                                  onClick: () {
                                    state(() {});
                                    LocaleNotifier.of(context)?.change('af');
                                    Navigator.pop(context);
                                  },
                                ),

                                /* Arabic */
                                const SizedBox(height: 20),
                                _buildLanguage(
                                  langName: "Arabic",
                                  onClick: () {
                                    state(() {});
                                    LocaleNotifier.of(context)?.change('ar');
                                    Navigator.pop(context);
                                  },
                                ),

                                /* German */
                                const SizedBox(height: 20),
                                _buildLanguage(
                                  langName: "German",
                                  onClick: () {
                                    state(() {});
                                    LocaleNotifier.of(context)?.change('de');
                                    Navigator.pop(context);
                                  },
                                ),

                                /* Spanish */
                                const SizedBox(height: 20),
                                _buildLanguage(
                                  langName: "Spanish",
                                  onClick: () {
                                    state(() {});
                                    LocaleNotifier.of(context)?.change('es');
                                    Navigator.pop(context);
                                  },
                                ),

                                /* French */
                                const SizedBox(height: 20),
                                _buildLanguage(
                                  langName: "French",
                                  onClick: () {
                                    state(() {});
                                    LocaleNotifier.of(context)?.change('fr');
                                    Navigator.pop(context);
                                  },
                                ),

                                /* Gujarati */
                                const SizedBox(height: 20),
                                _buildLanguage(
                                  langName: "Gujarati",
                                  onClick: () {
                                    state(() {});
                                    LocaleNotifier.of(context)?.change('gu');
                                    Navigator.pop(context);
                                  },
                                ),

                                /* Hindi */
                                const SizedBox(height: 20),
                                _buildLanguage(
                                  langName: "Hindi",
                                  onClick: () {
                                    state(() {});
                                    LocaleNotifier.of(context)?.change('hi');
                                    Navigator.pop(context);
                                  },
                                ),

                                /* Indonesian */
                                const SizedBox(height: 20),
                                _buildLanguage(
                                  langName: "Indonesian",
                                  onClick: () {
                                    state(() {});
                                    LocaleNotifier.of(context)?.change('id');
                                    Navigator.pop(context);
                                  },
                                ),

                                /* Dutch */
                                const SizedBox(height: 20),
                                _buildLanguage(
                                  langName: "Dutch",
                                  onClick: () {
                                    state(() {});
                                    LocaleNotifier.of(context)?.change('nl');
                                    Navigator.pop(context);
                                  },
                                ),

                                /* Portuguese (Brazil) */
                                const SizedBox(height: 20),
                                _buildLanguage(
                                  langName: "Portuguese (Brazil)",
                                  onClick: () {
                                    state(() {});
                                    LocaleNotifier.of(context)?.change('pt');
                                    Navigator.pop(context);
                                  },
                                ),

                                /* Albanian */
                                const SizedBox(height: 20),
                                _buildLanguage(
                                  langName: "Albanian",
                                  onClick: () {
                                    state(() {});
                                    LocaleNotifier.of(context)?.change('sq');
                                    Navigator.pop(context);
                                  },
                                ),

                                /* Turkish */
                                const SizedBox(height: 20),
                                _buildLanguage(
                                  langName: "Turkish",
                                  onClick: () {
                                    state(() {});
                                    LocaleNotifier.of(context)?.change('tr');
                                    Navigator.pop(context);
                                  },
                                ),

                                /* Vietnamese */
                                const SizedBox(height: 20),
                                _buildLanguage(
                                  langName: "Vietnamese",
                                  onClick: () {
                                    state(() {});
                                    LocaleNotifier.of(context)?.change('vi');
                                    Navigator.pop(context);
                                  },
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLanguage({
    required String langName,
    required Function() onClick,
  }) {
    return InkWell(
      onTap: onClick,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width,
        ),
        height: 48,
        padding: const EdgeInsets.only(left: 10, right: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.surface,
            width: .5,
          ),
          // color: colorPrimaryDark,
          borderRadius: BorderRadius.circular(5),
        ),
        child: MyText(
          color: Theme.of(context).colorScheme.surface,
          text: langName,
          textalign: TextAlign.center,
          fontsize: Dimens.textTitle,
          multilanguage: false,
          maxline: 1,
          overflow: TextOverflow.ellipsis,
          fontwaight: FontWeight.w500,
          fontstyle: FontStyle.normal,
        ),
      ),
    );
  }

  Widget _buildPages() {
    if (generalProvider.loading) {
      return const SizedBox.shrink();
    } else {
      if (generalProvider.pagesModel.status == 200 &&
          generalProvider.pagesModel.result != null) {
        return AlignedGridView.count(
          shrinkWrap: true,
          crossAxisCount: 1,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          itemCount: (generalProvider.pagesModel.result?.length ?? 0),
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (BuildContext context, int position) {
            return Column(
              children: [
                buildDrawerItem(
                  generalProvider.pagesModel.result?[position].icon ?? '',
                  "url",
                  generalProvider.pagesModel.result?[position].title ?? '',
                  false,
                  () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CommonPage(
                          title: generalProvider
                                  .pagesModel.result?[position].title ??
                              '',
                          url: generalProvider
                                  .pagesModel.result?[position].url ??
                              '',
                        ),
                      ),
                    );
                  },
                ),
                divider(),
              ],
            );
          },
        );
      } else {
        return const SizedBox.shrink();
      }
    }
  }

  Widget _buildSocialLink() {
    if (generalProvider.loading) {
      return const SizedBox.shrink();
    } else {
      if (generalProvider.socialLinkModel.status == 200 &&
          generalProvider.socialLinkModel.result != null) {
        return AlignedGridView.count(
          shrinkWrap: true,
          crossAxisCount: 1,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          itemCount: (generalProvider.socialLinkModel.result?.length ?? 0),
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (BuildContext context, int position) {
            return Column(
              children: [
                buildDrawerItem(
                  generalProvider.socialLinkModel.result?[position].image ?? '',
                  "url",
                  generalProvider.socialLinkModel.result?[position].name ?? '',
                  false,
                  () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CommonPage(
                          title: generalProvider
                                  .socialLinkModel.result?[position].name ??
                              '',
                          url: generalProvider
                                  .socialLinkModel.result?[position].url ??
                              '',
                        ),
                      ),
                    );
                  },
                ),
                divider(),
              ],
            );
          },
        );
      } else {
        return const SizedBox.shrink();
      }
    }
  }

  Widget commanShimmer() {
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
          height: 120,
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: ListView.separated(
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
              scrollDirection: Axis.horizontal,
              itemCount: 10,
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                return Container(
                  width: 95,
                  height: MediaQuery.of(context).size.height,
                  decoration: BoxDecoration(
                      color: Theme.of(context).secondaryHeaderColor,
                      borderRadius: BorderRadius.circular(15)),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      CustomWidget.roundcorner(height: 85),
                      SizedBox(height: 5),
                      CustomWidget.roundcorner(
                        height: 5,
                        width: 50,
                      ),
                    ],
                  ),
                );
              },
            ),
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
}
