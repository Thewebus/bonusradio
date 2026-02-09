import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:myBonus/pages/home.dart';
import 'package:myBonus/pages/intro.dart';
import 'package:myBonus/provider/generalprovider.dart';
import 'package:myBonus/utils/adhelper.dart';
import 'package:myBonus/utils/constant.dart';
import 'package:myBonus/utils/sharedpref.dart';
import 'package:myBonus/utils/utils.dart';
import 'package:myBonus/widget/myimage.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => SplashState();
}

class SplashState extends State<Splash> {
  SharedPref sharedpre = SharedPref();
  late GeneralProvider generalProvider;

  @override
  void initState() {
    generalProvider = Provider.of<GeneralProvider>(context, listen: false);
    getApi();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    Utils.getCurrencySymbol();
    super.initState();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);

    super.dispose();
  }

  Future<void> getApi() async {
    await generalProvider.getGeneralsetting(context);
    Future.delayed(Duration.zero).then((value) {
      if (!mounted) return;
      setState(() {
        isFirstCheck();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    return Scaffold(
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: MyImage(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          imagePath: "splash.png",
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Future<void> isFirstCheck() async {
    /* Get Ads Init */
    Utils.getCurrencySymbol();
    AdHelper.getAds(context);
    await generalProvider.getIntroPages();

    String? seen = await sharedpre.read("seen") ?? "";
    printLog("seen :=================> $seen");
    Constant.userID = await sharedpre.read('userid');
    printLog("userID =======> ${Constant.userID}");

    if (seen == "1") {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) {
            return const Home();
          },
        ),
      );
    } else {
      if (!generalProvider.loading &&
          generalProvider.introScreenModel.status == 200 &&
          (generalProvider.introScreenModel.result != null ||
              ((generalProvider.introScreenModel.result?.length ?? 0) > 0))) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) {
              return Intro(
                introList: generalProvider.introScreenModel.result ?? [],
              );
            },
          ),
        );
      } else {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) {
              return const Home();
            },
          ),
        );
      }
    }
  }
}
