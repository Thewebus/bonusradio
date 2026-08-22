import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:myBonus/utils/color.dart';
import 'package:myBonus/utils/dimens.dart';
import 'package:myBonus/utils/sharedpref.dart';
import 'package:myBonus/utils/utils.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:myBonus/widget/myimage.dart';
import 'package:myBonus/widget/mytext.dart';

class CommonPage extends StatefulWidget {
  final String title, url;
  const CommonPage({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  CommonPageState createState() => CommonPageState();
}

class CommonPageState extends State<CommonPage> {
  var loadingPercentage = 0;
  InAppWebViewController? webViewController;
  PullToRefreshController? pullToRefreshController;
  SharedPref sharedPref = SharedPref();
  Uri? fixedUri;
  String? fixedUrl;
  @override
  void initState() {
    super.initState();
    debugPrint("url ========> ${widget.url}");
    // Fix the URL using Uri
    fixedUri = Uri.parse(widget.url).replace(
      path: Uri.parse(widget.url).path.replaceAll("//", "/"),
    );

    // Convert the fixed Uri back to a string
    fixedUrl = fixedUri.toString();
    printLog("FIX tHos url $fixedUrl");
    pullToRefreshController = (kIsWeb) ||
            ![TargetPlatform.iOS, TargetPlatform.android]
                .contains(defaultTargetPlatform)
        ? null
        : PullToRefreshController(
            onRefresh: () async {
              if (defaultTargetPlatform == TargetPlatform.android) {
                webViewController?.reload();
              } else if (defaultTargetPlatform == TargetPlatform.iOS ||
                  defaultTargetPlatform == TargetPlatform.macOS) {
                webViewController?.loadUrl(
                    urlRequest:
                        URLRequest(url: await webViewController?.getUrl()));
              }
            },
          );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: homeAccueilBg(context),
        body: setWebView(),
      );
    } else {
      return Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: homeAccueilBg(context),
        appBar: AppBar(
          backgroundColor: homeSearchBarBg(context),
          surfaceTintColor: transparent,
          elevation: 20,
          leading: InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: MyImage(width: 15, height: 15, imagePath: "back.png"),
          ),
          title: MyText(
            text: widget.title,
            maxline: 1,
            overflow: TextOverflow.ellipsis,
            fontsize: Dimens.textBig,
            color: white,
            fontwaight: FontWeight.w600,
          ),
          actions: settingsAppBarAction(context),
        ),
        body: setWebView(),
      );
    }
  }

  Widget setWebView() {
    return Stack(
      children: [
        InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(fixedUrl ?? "")),
          pullToRefreshController: pullToRefreshController,
          onWebViewCreated: (controller) async {
            webViewController = controller;
          },
          onLoadStart: (controller, url) async {
            setState(() {
              loadingPercentage = 0;
            });
          },
          shouldOverrideUrlLoading: (controller, navigationAction) async {
            return NavigationActionPolicy.ALLOW;
          },
          onLoadStop: (controller, url) async {
            setState(() {
              loadingPercentage = 100;
            });
            pullToRefreshController?.endRefreshing();
          },
          onProgressChanged: (controller, progress) {
            setState(() {
              loadingPercentage = progress;
            });
          },
          onUpdateVisitedHistory: (controller, url, isReload) {
            debugPrint("onUpdateVisitedHistory url =========> $url");
          },
          onConsoleMessage: (controller, consoleMessage) {
            debugPrint("consoleMessage =========> $consoleMessage");
          },
        ),
        if (loadingPercentage < 100)
          LinearProgressIndicator(
            color: colorPrimary,
            backgroundColor: colorAccent,
            value: loadingPercentage / 100.0,
          ),
      ],
    );
  }
}
