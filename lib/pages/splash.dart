import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:myBonus/pages/home.dart';
import 'package:myBonus/provider/generalprovider.dart';
import 'package:myBonus/provider/homeprovider.dart';
import 'package:myBonus/provider/profileprovider.dart';
import 'package:myBonus/music/musicdetails.dart';
import 'package:myBonus/music/nowplaying.dart';
import 'package:myBonus/utils/constant.dart';
import 'package:myBonus/utils/network.dart';
import 'package:myBonus/utils/sharedpref.dart';
import 'package:myBonus/utils/utils.dart';
import 'package:myBonus/webservice/apiservices.dart';
import 'package:myBonus/widget/myimage.dart';

// Entry screen: the animated myBonus logo on its cream background (pops in,
// then pulses over a small equalizer) while everything the app shows first
// loads in parallel: settings, profile, banners, sections, pages, social
// links, and — for the Radios screen it lands on — the radio's live info and
// stream qualities, every station/banner picture and the zone pub ads with
// their posters. Nothing is left loading once it's gone, unless the network
// is slower than [_maxWait]: Home then opens anyway and finishes on screen.
// Offline at launch, it waits for the network (NetworkBanner shows the
// "no internet" pill with Retry).
class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => SplashState();
}

class SplashState extends State<Splash> with TickerProviderStateMixin {
  // Slow networks: past this, Home opens and finishes loading on screen.
  static const Duration _maxWait = Duration(seconds: 8);
  // Long enough for the logo's entrance to finish on fast connections.
  static const Duration _minShow = Duration(milliseconds: 1600);
  // Background of splash_logo.png — also the native launch screen color.
  static const Color _background = Color(0xFFFFFED6);
  static const Color _accent = Color(0xFFF5C400);

  late final AnimationController _intro = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..forward();
  late final AnimationController _loop = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat();

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    Utils.getCurrencySymbol();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _intro.dispose();
    _loop.dispose();
    NetworkService.isOnline.removeListener(_retryWhenOnline);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }

  Future<void> _start() async {
    if (!await NetworkService.check()) {
      NetworkService.isOnline.addListener(_retryWhenOnline);
      return;
    }
    await _preloadAndOpenHome();
  }

  void _retryWhenOnline() {
    if (!NetworkService.isOnline.value) return;
    NetworkService.isOnline.removeListener(_retryWhenOnline);
    _preloadAndOpenHome();
  }

  Future<void> _preloadAndOpenHome() async {
    final generalProvider =
        Provider.of<GeneralProvider>(context, listen: false);
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    Constant.userID = await SharedPref().read('userid');
    if (!mounted) return;

    final Future<void> work = Future.wait([
      generalProvider.loadAppSettings(),
      if (Constant.userID != null) profileProvider.getProfile(context),
      homeProvider.getBanner(0).then((_) => _warmUp(homeProvider)),
      homeProvider.getSeactionList(1),
      generalProvider.getPages(),
      generalProvider.getSocialLink(),
      _preloadPubAds(),
    ]);
    final Future<void> minShow = Future.delayed(_minShow);
    bool done = false;
    try {
      await work.then((_) => done = true).timeout(_maxWait);
    } catch (e) {
      printLog('Splash preload: $e');
    }
    await minShow;
    homeProvider.preloaded = done;
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => const Home(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  // The app opens on the Radios screen: nothing there may still be loading
  // once the Splash is gone — the radio's live info (song, cover, listeners,
  // stream qualities), every station/banner picture, and the zone pub ads
  // with their posters, all downloaded and decoded beforehand.
  Future<void> _warmUp(HomeProvider homeProvider) async {
    final banners = homeProvider.bannerModel.result ?? [];
    final radio = banners.where((b) => b.type == 1).firstOrNull;
    await Future.wait([
      if (radio?.songUrl != null)
        NowPlayingService.prefetch(radio!.songUrl!, context),
      for (final b in banners)
        if ((b.image ?? '').isNotEmpty) _precache(b.image!),
      // Now-playing card fallback (station picture, drawn with Image.network).
      if ((radio?.image ?? '').isNotEmpty)
        _precache(radio!.image!, network: true),
    ]);
  }

  Future<void> _preloadPubAds() async {
    try {
      final model = await ApiService().adsPremiumList();
      if (model.status != 200) return;
      final list = (model.result ?? [])
          .where((ad) => (ad.imageUrl ?? '').isNotEmpty)
          .toList();
      await Future.wait([for (final ad in list) _precache(ad.imageUrl!)]);
      preloadedPubAds = list;
    } catch (e) {
      printLog('Splash pub ads: $e');
    }
  }

  // CachedNetworkImage (MyNetworkImage) by default, or a plain NetworkImage.
  Future<void> _precache(String url, {bool network = false}) async {
    if (!mounted) return;
    await precacheImage(
            network ? NetworkImage(url) : CachedNetworkImageProvider(url),
            context)
        .catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final double logoSize =
        math.min(MediaQuery.of(context).size.width * 0.72, 340);
    return Scaffold(
      backgroundColor: _background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Entrance: fade + springy zoom; then a soft beat.
            FadeTransition(
              opacity: CurvedAnimation(parent: _intro, curve: Curves.easeOut),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.6, end: 1).animate(
                    CurvedAnimation(parent: _intro, curve: Curves.easeOutBack)),
                child: AnimatedBuilder(
                  animation: _loop,
                  builder: (context, child) => Transform.scale(
                    scale: 1 + 0.025 * math.sin(_loop.value * 2 * math.pi),
                    child: child,
                  ),
                  child: MyImage(
                    width: logoSize,
                    height: logoSize,
                    imagePath: "splash_logo.png",
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            FadeTransition(
              opacity: CurvedAnimation(
                  parent: _intro, curve: const Interval(0.5, 1)),
              child: _buildEqualizer(),
            ),
          ],
        ),
      ),
    );
  }

  // Five bars bouncing out of phase, in the logo's black and yellow.
  Widget _buildEqualizer() {
    return AnimatedBuilder(
      animation: _loop,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(5, (i) {
          final double t =
              (math.sin((_loop.value + i * 0.18) * 2 * math.pi) + 1) / 2;
          return Container(
            width: 5,
            height: 8 + 20 * t,
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            decoration: BoxDecoration(
              color: i == 2 ? _accent : Colors.black,
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }
}
