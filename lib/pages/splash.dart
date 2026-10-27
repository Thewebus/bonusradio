import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:myBonus/pages/home.dart';
import 'package:myBonus/provider/generalprovider.dart';
import 'package:myBonus/provider/homeprovider.dart';
import 'package:myBonus/provider/profileprovider.dart';
import 'package:myBonus/utils/audioquality.dart';
import 'package:myBonus/utils/constant.dart';
import 'package:myBonus/utils/network.dart';
import 'package:myBonus/utils/sharedpref.dart';
import 'package:myBonus/utils/utils.dart';
import 'package:myBonus/widget/myimage.dart';

// Entry screen: shows the splash artwork while everything Home needs on its
// first frame loads in parallel (settings, profile, banners, sections, pages,
// social links, first banner images, radio stream qualities), so Home opens
// filled instead of on shimmers. Capped at [_maxWait]; past that Home opens
// anyway and loads what's left itself. Offline at launch, it waits for the
// network (NetworkBanner shows the "no internet" pill with Retry).
class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => SplashState();
}

class SplashState extends State<Splash> {
  static const Duration _maxWait = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    Utils.getCurrencySymbol();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
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
    ]);
    bool done = false;
    try {
      await work.then((_) => done = true).timeout(_maxWait);
    } catch (e) {
      printLog('Splash preload: $e');
    }
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

  // First banner images (decoded, so the carousel shows them at once) and
  // the radio's available bitrates (Settings > Qualité audio).
  Future<void> _warmUp(HomeProvider homeProvider) async {
    final banners = homeProvider.bannerModel.result ?? [];
    final radio = banners.where((b) => b.type == 1).firstOrNull;
    await Future.wait([
      if (radio?.songUrl != null) AudioQuality.prefetch(radio!.songUrl!),
      for (final b in banners.take(3))
        if ((b.image ?? '').isNotEmpty && mounted)
          precacheImage(CachedNetworkImageProvider(b.image!), context)
              .catchError((_) {}),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MyImage(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        imagePath: "splash.png",
        fit: BoxFit.cover,
      ),
    );
  }
}
