import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:myBonus/pages/commonpage.dart';
import 'package:myBonus/pages/login.dart';
import 'package:myBonus/provider/generalprovider.dart';
import 'package:myBonus/provider/themeprovider.dart';
import 'package:myBonus/utils/color.dart';
import 'package:myBonus/utils/constant.dart';
import 'package:myBonus/utils/dimens.dart';
import 'package:myBonus/utils/sharedpref.dart';
import 'package:myBonus/utils/utils.dart';
import 'package:myBonus/widget/abidjan_header.dart';
import 'package:myBonus/widget/myimage.dart';
import 'package:myBonus/widget/mynetworkimg.dart';
import 'package:myBonus/widget/mytext.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  SharedPref sharedpre = SharedPref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  double ratingValue = 0.0;

  late GeneralProvider generalProvider;

  // ABIDJAN (day theme) "LECTURE" card — visual toggles, cheap to persist.
  bool _wifiOnly = false;
  bool _liveAlerts = true;

  @override
  void initState() {
    super.initState();
    generalProvider = Provider.of<GeneralProvider>(context, listen: false);
    _loadPlaybackPrefs();
  }

  Future<void> _loadPlaybackPrefs() async {
    final wifiOnly = await sharedpre.readBool("wifi_only") ?? false;
    final liveAlerts = await sharedpre.readBool("live_alerts") ?? true;
    if (!mounted) return;
    setState(() {
      _wifiOnly = wifiOnly;
      _liveAlerts = liveAlerts;
    });
  }

  Future<void> _selectThemeMode(
      ThemeProvider themeprovider, AppThemeMode mode) async {
    themeprovider.setMode(mode);
    await sharedpre.remove("theme_mode");
    await sharedpre.save("theme_mode", mode.name);
  }

  @override
  Widget build(BuildContext context) {
    final bool isNight = Theme.of(context).brightness == Brightness.dark;
    return isNight ? _buildNightScaffold() : _buildAbidjanScaffold();
  }

  // Night mode — unchanged from before the ABIDJAN redesign.
  Widget _buildNightScaffold() {
    return Scaffold(
      backgroundColor: homeAccueilBg(context),
      appBar: AppBar(
        backgroundColor: homeSearchBarBg(context),
        elevation: 0,
        title: MyText(
          color: white,
          text: "settings",
          multilanguage: true,
          textalign: TextAlign.start,
          fontsize: Dimens.textBig,
          fontwaight: FontWeight.w600,
          maxline: 1,
          overflow: TextOverflow.ellipsis,
          fontstyle: FontStyle.normal,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Column(
          children: [
            /* Theme Mode Selector: Auto / Day / Night */
            Consumer<ThemeProvider>(builder: (context, themeprovider, child) {
              Future<void> select(AppThemeMode mode) =>
                  _selectThemeMode(themeprovider, mode);

              Widget modeButton(
                  IconData icon, AppThemeMode mode, String tooltip) {
                final bool isActive = themeprovider.mode == mode;
                return Expanded(
                  child: Tooltip(
                    message: tooltip,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => select(mode),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color:
                              isActive ? homeSearchBarBg(context) : transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive ? homeSearchBarBg(context) : gray,
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: isActive
                              ? white
                              : Theme.of(context).colorScheme.surface,
                        ),
                      ),
                    ),
                  ),
                );
              }

              return Container(
                padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.dark_mode_rounded,
                          size: 25,
                          color: homeSearchBarBg(context),
                        ),
                        SizedBox(
                            width: MediaQuery.of(context).size.width * 0.05),
                        MyText(
                          color: Theme.of(context).colorScheme.surface,
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        modeButton(
                            Icons.brightness_auto, AppThemeMode.auto, "Auto"),
                        modeButton(Icons.wb_sunny, AppThemeMode.day, "Jour"),
                        modeButton(
                            Icons.nightlight_round, AppThemeMode.night, "Nuit"),
                      ],
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 15),
            divider(),

            /* Change Language */
            _buildSettingItem(
              "ic_language.png",
              "changelanguage",
              () {
                _languageChangeDialog();
              },
              materialIcon: Icons.translate,
            ),
            divider(),

            /* Rate App */
            _buildSettingItem(
              "ic_rateapp.png",
              "rateapp",
              () {
                _showRatingDialog();
              },
              materialIcon: Icons.star_rate_rounded,
            ),
            divider(),

            /* Share App */
            _buildSettingItem(
              "ic_share.png",
              "shareapp",
              () async {
                await Utils.shareApp(Platform.isIOS
                    ? Constant.iosAppShareUrlDesc
                    : Constant.androidAppShareUrlDesc);
              },
              materialIcon: Icons.share_rounded,
            ),
            divider(),

            /* Pages (About, Terms, Privacy) */
            _buildPages(),

            /* Social Links */
            _buildSocialLink(),

            /* Logout */
            const SizedBox(height: 10),
            InkWell(
              focusColor: transparent,
              splashColor: transparent,
              hoverColor: transparent,
              highlightColor: transparent,
              onTap: () {
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
                  _showLogoutDialog();
                }
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 14),
                height: MediaQuery.of(context).size.height * 0.065,
                width: MediaQuery.of(context).size.width * 0.50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: homeSearchBarBg(context),
                    borderRadius: BorderRadius.circular(50)),
                child: MyText(
                  color: white,
                  multilanguage: true,
                  text: Constant.userID != null ? "logout" : "login",
                  fontwaight: FontWeight.w600,
                  fontsize: Dimens.textBig,
                  inter: 1,
                  fontstyle: FontStyle.normal,
                  maxline: 1,
                  overflow: TextOverflow.ellipsis,
                  textalign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ABIDJAN (day theme): flat cream header, black-fill theme selector,
  // "LECTURE" (visual-only playback toggles) + "APPLICATION" cards. Every
  // tap target below delegates to the exact same handlers as night mode
  // (_selectThemeMode, _languageChangeDialog, _showRatingDialog, Utils.share
  // App, CommonPage navigation, _showLogoutDialog) — only the chrome differs.
  Widget _buildAbidjanScaffold() {
    return Scaffold(
      backgroundColor: homeAccueilBg(context),
      body: SafeArea(
        child: Column(
          children: [
            const AbidjanHeader(title: "settings", showBack: true),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAbidjanThemeSelector(),
                    const SizedBox(height: 22),
                    _buildAbidjanSectionLabel("LECTURE"),
                    const SizedBox(height: 8),
                    _buildAbidjanCard(children: [
                      _buildAbidjanToggleRow(
                        icon: Icons.wifi,
                        label: "Wi-Fi uniquement",
                        value: _wifiOnly,
                        onChanged: (v) async {
                          setState(() => _wifiOnly = v);
                          await sharedpre.saveBool("wifi_only", v);
                        },
                      ),
                      _abidjanDivider(),
                      _buildAbidjanToggleRow(
                        icon: Icons.notifications_active_outlined,
                        label: "Alertes en direct",
                        value: _liveAlerts,
                        onChanged: (v) async {
                          setState(() => _liveAlerts = v);
                          await sharedpre.saveBool("live_alerts", v);
                        },
                      ),
                      _abidjanDivider(),
                      _buildAbidjanStaticRow(
                        icon: Icons.graphic_eq,
                        label: "Qualité audio",
                        trailing: "Automatique",
                      ),
                    ]),
                    const SizedBox(height: 22),
                    _buildAbidjanSectionLabel("APPLICATION"),
                    const SizedBox(height: 8),
                    _buildAbidjanCard(children: [
                      _buildSettingItem(
                        "ic_language.png",
                        "changelanguage",
                        () => _languageChangeDialog(),
                        materialIcon: Icons.translate,
                        light: true,
                      ),
                      _abidjanDivider(),
                      _buildSettingItem(
                        "ic_rateapp.png",
                        "rateapp",
                        () => _showRatingDialog(),
                        materialIcon: Icons.star_rate_rounded,
                        light: true,
                      ),
                      _abidjanDivider(),
                      _buildSettingItem(
                        "ic_share.png",
                        "shareapp",
                        () async {
                          await Utils.shareApp(Platform.isIOS
                              ? Constant.iosAppShareUrlDesc
                              : Constant.androidAppShareUrlDesc);
                        },
                        materialIcon: Icons.share_rounded,
                        light: true,
                      ),
                      _buildPages(light: true),
                      _buildSocialLink(light: true),
                    ]),
                    const SizedBox(height: 28),
                    Center(
                      child: Column(
                        children: [
                          const Text(
                            "BONUS MULTIMEDIA",
                            style: TextStyle(
                              color: gray,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Version ${Constant.appVersion}",
                            style: const TextStyle(
                              color: gray,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildAbidjanLogoutButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbidjanSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: gray,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildAbidjanCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(children: children),
    );
  }

  Widget _abidjanDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: lightgray,
    );
  }

  Widget _buildAbidjanIconChip(Widget icon) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: abidjanIconChipBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: icon,
    );
  }

  Widget _buildAbidjanToggleRow({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _buildAbidjanIconChip(Icon(icon, size: 18, color: black)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: black,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: white,
            activeTrackColor: black,
          ),
        ],
      ),
    );
  }

  Widget _buildAbidjanStaticRow({
    required IconData icon,
    required String label,
    required String trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _buildAbidjanIconChip(Icon(icon, size: 18, color: black)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: black,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            trailing,
            style: const TextStyle(
              color: gray,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbidjanThemeSelector() {
    return Consumer<ThemeProvider>(builder: (context, themeprovider, child) {
      Widget modeButton(IconData icon, AppThemeMode mode, String label) {
        final bool isActive = themeprovider.mode == mode;
        return Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _selectThemeMode(themeprovider, mode),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isActive ? black : white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: isActive ? white : black, size: 20),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: isActive ? white : black,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return Row(
        children: [
          modeButton(Icons.brightness_auto, AppThemeMode.auto, "Auto"),
          modeButton(Icons.wb_sunny, AppThemeMode.day, "Jour"),
          modeButton(Icons.nightlight_round, AppThemeMode.night, "Nuit"),
        ],
      );
    });
  }

  Widget _buildAbidjanLogoutButton() {
    return InkWell(
      focusColor: transparent,
      splashColor: transparent,
      hoverColor: transparent,
      highlightColor: transparent,
      onTap: () {
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
          _showLogoutDialog();
        }
      },
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: colorPrimary),
        ),
        child: MyText(
          color: colorPrimary,
          multilanguage: true,
          text: Constant.userID != null ? "logout" : "login",
          fontwaight: FontWeight.w700,
          fontsize: Dimens.textTitle,
          inter: 1,
          fontstyle: FontStyle.normal,
          maxline: 1,
          overflow: TextOverflow.ellipsis,
          textalign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    String icon,
    String name,
    Function() onTap, {
    bool isNetworkIcon = false,
    IconData? materialIcon,
    bool light = false,
  }) {
    if (light) {
      return InkWell(
        focusColor: transparent,
        splashColor: transparent,
        hoverColor: transparent,
        highlightColor: transparent,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              _buildAbidjanIconChip(materialIcon != null
                  ? Icon(materialIcon, size: 18, color: black)
                  : isNetworkIcon
                      ? MyNetworkImage(
                          imgWidth: 20,
                          imgHeight: 20,
                          fit: BoxFit.cover,
                          imageUrl: icon,
                        )
                      : MyImage(
                          width: 20,
                          height: 20,
                          imagePath: icon,
                          color: black,
                        )),
              const SizedBox(width: 14),
              Expanded(
                child: MyText(
                  color: black,
                  text: name,
                  textalign: TextAlign.start,
                  multilanguage: !isNetworkIcon,
                  fontsize: Dimens.textMedium,
                  inter: 1,
                  maxline: 1,
                  fontwaight: FontWeight.w600,
                  overflow: TextOverflow.ellipsis,
                  fontstyle: FontStyle.normal,
                ),
              ),
              const Icon(Icons.chevron_right, color: gray, size: 20),
            ],
          ),
        ),
      );
    }
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
              child: materialIcon != null
                  ? Icon(materialIcon,
                      size: 28, color: homeSearchBarBg(context))
                  : isNetworkIcon
                      ? MyNetworkImage(
                          imgWidth: 30,
                          imgHeight: 30,
                          fit: BoxFit.cover,
                          imageUrl: icon,
                        )
                      : MyImage(
                          width: 30,
                          height: 30,
                          imagePath: icon,
                          color: homeSearchBarBg(context),
                        ),
            ),
            SizedBox(width: MediaQuery.of(context).size.width * 0.05),
            MyText(
              color: Theme.of(context).colorScheme.surface,
              text: name,
              textalign: TextAlign.center,
              // Network-icon items come from the backend (About, social
              // links...) and are already display-ready text, not
              // translation keys — treating them as keys via
              // multilanguage:true made LocaleText show "$name" whenever
              // that exact string wasn't also a key in the locale files.
              multilanguage: !isNetworkIcon,
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

  Widget divider() {
    return Container(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.15),
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.fromLTRB(15, 0, 15, 0),
      height: 1,
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
                                const SizedBox(height: 20),
                                _buildLanguage(
                                  langName: "Afrikaans",
                                  onClick: () {
                                    state(() {});
                                    LocaleNotifier.of(context)?.change('af');
                                    Navigator.pop(context);
                                  },
                                ),
                                const SizedBox(height: 20),
                                _buildLanguage(
                                  langName: "Arabic",
                                  onClick: () {
                                    state(() {});
                                    LocaleNotifier.of(context)?.change('ar');
                                    Navigator.pop(context);
                                  },
                                ),
                                const SizedBox(height: 20),
                                _buildLanguage(
                                  langName: "German",
                                  onClick: () {
                                    state(() {});
                                    LocaleNotifier.of(context)?.change('de');
                                    Navigator.pop(context);
                                  },
                                ),
                                const SizedBox(height: 20),
                                _buildLanguage(
                                  langName: "Spanish",
                                  onClick: () {
                                    state(() {});
                                    LocaleNotifier.of(context)?.change('es');
                                    Navigator.pop(context);
                                  },
                                ),
                                const SizedBox(height: 20),
                                _buildLanguage(
                                  langName: "French",
                                  onClick: () {
                                    state(() {});
                                    LocaleNotifier.of(context)?.change('fr');
                                    Navigator.pop(context);
                                  },
                                ),
                                const SizedBox(height: 20),
                                _buildLanguage(
                                  langName: "Gujarati",
                                  onClick: () {
                                    state(() {});
                                    LocaleNotifier.of(context)?.change('gu');
                                    Navigator.pop(context);
                                  },
                                ),
                                const SizedBox(height: 20),
                                _buildLanguage(
                                  langName: "Hindi",
                                  onClick: () {
                                    state(() {});
                                    LocaleNotifier.of(context)?.change('hi');
                                    Navigator.pop(context);
                                  },
                                ),
                                const SizedBox(height: 20),
                                _buildLanguage(
                                  langName: "Indonesian",
                                  onClick: () {
                                    state(() {});
                                    LocaleNotifier.of(context)?.change('id');
                                    Navigator.pop(context);
                                  },
                                ),
                                const SizedBox(height: 20),
                                _buildLanguage(
                                  langName: "Dutch",
                                  onClick: () {
                                    state(() {});
                                    LocaleNotifier.of(context)?.change('nl');
                                    Navigator.pop(context);
                                  },
                                ),
                                const SizedBox(height: 20),
                                _buildLanguage(
                                  langName: "Portuguese (Brazil)",
                                  onClick: () {
                                    state(() {});
                                    LocaleNotifier.of(context)?.change('pt');
                                    Navigator.pop(context);
                                  },
                                ),
                                const SizedBox(height: 20),
                                _buildLanguage(
                                  langName: "Albanian",
                                  onClick: () {
                                    state(() {});
                                    LocaleNotifier.of(context)?.change('sq');
                                    Navigator.pop(context);
                                  },
                                ),
                                const SizedBox(height: 20),
                                _buildLanguage(
                                  langName: "Turkish",
                                  onClick: () {
                                    state(() {});
                                    LocaleNotifier.of(context)?.change('tr');
                                    Navigator.pop(context);
                                  },
                                ),
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

  void _showRatingDialog() {
    ratingValue = 0.0;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          elevation: 5,
          insetPadding: const EdgeInsets.all(30),
          insetAnimationCurve: Curves.easeInExpo,
          insetAnimationDuration: const Duration(seconds: 1),
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.35,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
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
                    half: const Icon(Icons.star_half, color: colorPrimary),
                    empty: const Icon(Icons.star_border, color: lightgray),
                  ),
                  onRatingUpdate: (double value) {
                    ratingValue = value;
                  },
                ),
                MyText(
                    color: Theme.of(context).colorScheme.surface,
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
                    text: "tapastartorateitontheappstore",
                    textalign: TextAlign.center,
                    multilanguage: true,
                    fontsize: Dimens.textMedium,
                    inter: 1,
                    maxline: 2,
                    fontwaight: FontWeight.w500,
                    overflow: TextOverflow.ellipsis,
                    fontstyle: FontStyle.normal),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      focusColor: transparent,
                      splashColor: transparent,
                      hoverColor: transparent,
                      highlightColor: transparent,
                      onTap: () async {
                        if (ratingValue == 0.0) {
                          Utils.showToast("Please Enter Your Rating");
                        } else {
                          await Utils.redirectToStore();
                          if (!mounted) return;
                          Navigator.pop(context);
                        }
                      },
                      child: Container(
                        width: 120,
                        height: 45,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [colorAccent, colorPrimary],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight),
                          borderRadius: BorderRadius.circular(50),
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
                            overflow: TextOverflow.ellipsis,
                            fontstyle: FontStyle.normal),
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
                          border: Border.all(color: gray, width: 1),
                          borderRadius: BorderRadius.circular(50),
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
                            overflow: TextOverflow.ellipsis,
                            fontstyle: FontStyle.normal),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLogoutDialog() {
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
          height: MediaQuery.of(context).size.height * 0.25,
          color: Theme.of(context).bottomSheetTheme.backgroundColor,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              MyText(
                color: Theme.of(context).colorScheme.surface,
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
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      if (!mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Login(),
                        ),
                        (route) => false,
                      );
                    },
                    child: Container(
                      width: 100,
                      height: MediaQuery.of(context).size.height * 0.05,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colorPrimary, colorPrimary],
                          end: Alignment.bottomLeft,
                          begin: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(50)),
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
                          overflow: TextOverflow.ellipsis,
                          fontstyle: FontStyle.normal),
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
                      height: MediaQuery.of(context).size.height * 0.05,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colorPrimary, colorPrimary],
                          end: Alignment.bottomLeft,
                          begin: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(50)),
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
                          overflow: TextOverflow.ellipsis,
                          fontstyle: FontStyle.normal),
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

  Widget _buildPages({bool light = false}) {
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
                _buildSettingItem(
                  generalProvider.pagesModel.result?[position].icon ?? '',
                  generalProvider.pagesModel.result?[position].title ?? '',
                  () {
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
                  isNetworkIcon: true,
                  materialIcon: Icons.menu_book_rounded,
                  light: light,
                ),
                light ? _abidjanDivider() : divider(),
              ],
            );
          },
        );
      } else {
        return const SizedBox.shrink();
      }
    }
  }

  Widget _buildSocialLink({bool light = false}) {
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
                _buildSettingItem(
                  generalProvider.socialLinkModel.result?[position].image ?? '',
                  generalProvider.socialLinkModel.result?[position].name ?? '',
                  () {
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
                  isNetworkIcon: true,
                  light: light,
                ),
                light ? _abidjanDivider() : divider(),
              ],
            );
          },
        );
      } else {
        return const SizedBox.shrink();
      }
    }
  }
}
