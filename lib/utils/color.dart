import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/* Main Color Start */
const colorPrimary = Color(0xFFFF452D);
const colorPrimaryDark = Color(0xFFFF452D);
const colorAccent = Color(0xFF71828A);
/* Main Color End */

const appBgColor = Color(0xffF5F5F5);
const subscriptionBG = Color.fromARGB(255, 12, 3, 2);
const white = Color(0xffffffff);
const black = Color(0xff000000);
const gray = Color(0xff878787);
const lightgray = Color(0xffD3D3D3);
const transparent = Colors.transparent;

/* Accueil Redesign Colors — day/night variants for the 7 screens that
   don't rely on Theme.of(context) (Accueil, dock, mini/full player,
   Podcast, Films, Profil). */
bool _isNight(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color homeAccueilBg(BuildContext context) => _isNight(context)
    ? const Color(0xFF121212)
    : const Color(0xFFF7F1E6);

Color homeSearchBarBg(BuildContext context) => _isNight(context)
    ? const Color(0xFF8A241A)
    : const Color(0xFF5C1712);

Color homeLiveBadge(BuildContext context) => const Color(0xFFE3352B);

/* Night-mode page background: red-to-black gradient instead of a flat
   near-black fill, matching the reference design. Day mode stays the flat
   cream fill. */
BoxDecoration homeAccueilBackgroundDecoration(BuildContext context) =>
    _isNight(context)
        ? const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF3D0F0C),
                Color(0xFF1F0806),
                Color(0xFF000000),
              ],
              stops: [0.0, 0.45, 1.0],
            ),
          )
        : BoxDecoration(color: homeAccueilBg(context));

/* ===================== ABIDJAN (day theme) tokens =========================
   Additive only — every function above keeps both its branches untouched.
   dockActivePillBg is the one shared/always-mounted widget (dock) that
   needs a brightness branch; its night arm simply delegates to the
   existing homeSearchBarBg so night's dock pill is provably unchanged. */

Color dockActivePillBg(BuildContext context) =>
    _isNight(context) ? homeSearchBarBg(context) : colorPrimary;

/* Everything below is day-only: only ever referenced from a render branch
   already gated on "not night" by the caller, so it deliberately does not
   take a BuildContext / branch on brightness itself. */
const abidjanPillBorder = Color(0xFFE0D8C8);
const abidjanIconChipBg = Color(0xFFF1E9DA);

const List<List<Color>> abidjanBokehGradients = [
  [Color(0xFFFF6B4A), Color(0xFFB8241A)],
  [Color(0xFF3FA34D), Color(0xFF1B5E2A)],
  [Color(0xFF7B5CFA), Color(0xFF3A1F8A)],
  [Color(0xFF3B82C4), Color(0xFF1B3F6B)],
];

/* =================== LIVE NEON (night theme) tokens ========================
   Additive only, mirroring the ABIDJAN section above: existing night
   tokens (homeAccueilBg, homeSearchBarBg, ...) keep
   serving the not-yet-migrated screens' _buildNightXxx() methods untouched.
   Each screen migrated to LIVE NEON reads these new tokens instead, via its
   own _buildLiveNeonXxx() method — never referenced from a day branch. */
const Color liveNeonBg = Color(0xFF0D0817);
const Color liveNeonCardBg = Color(0xFF171225);
const Color liveNeonBorder = Color(0xFF2E2444);
const Color liveNeonIconChipBg = Color(0xFF241A38);
const Color liveNeonTextSecondary = Color(0xFFB9AFCB);

const List<Color> liveNeonGradient = [
  Color(0xFFEC4899),
  Color(0xFF8B5CF6),
  Color(0xFF3B82F6),
];

BoxDecoration liveNeonBackgroundDecoration() => const BoxDecoration(
      gradient: RadialGradient(
        center: Alignment(-0.7, -0.9),
        radius: 1.4,
        colors: [
          Color(0xFF3A1868),
          Color(0xFF1B0E30),
          liveNeonBg,
        ],
        stops: [0.0, 0.5, 1.0],
      ),
    );

const List<List<Color>> liveNeonBokehGradients = [
  [Color(0xFF3B82F6), Color(0xFF10254F)],
  [Color(0xFF10B981), Color(0xFF0B3B2C)],
  [Color(0xFFEC4899), Color(0xFF4A0F35)],
  [Color(0xFF8B5CF6), Color(0xFF2E1454)],
];

// Same palette already used by floating_player.dart's waveform, reused here
// so every LIVE NEON waveform/accent looks consistent.
const List<Color> liveNeonWaveColors = [
  Color(0xFF00F5FF),
  Color(0xFFFF006E),
  Color(0xFFFFBE0B),
  Color(0xFF8338EC),
  Color(0xFF00D9FF),
];

/* ============================= Light Theme =============================== */

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  /* Main Color Start */
  primaryColor: colorPrimary,
  secondaryHeaderColor: colorPrimary.withValues(alpha: 0.08),
  hintColor: colorAccent,
  scaffoldBackgroundColor: appBgColor,
  /* Main Color End */
  /* Text Color Start */
  colorScheme: const ColorScheme.light(
    surface: black,
    primary: white,
    onPrimary: white,
    secondary: white,
    onSecondary: white,
  ),
  /* Text Color End */
  appBarTheme: const AppBarTheme(
      backgroundColor: white,
      systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: white,
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark)),
  cardColor: white,
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: white,
  ),
  drawerTheme: const DrawerThemeData(
    backgroundColor: white,
  ),
);

/* ============================= Dark Theme =============================== */

const darkSurfaceBg = Color(0xFF121212);
const darkCardBg = Color(0xFF1C1C1C);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  /* Main Color Start */
  primaryColor: colorPrimary,
  hintColor: colorAccent,
  secondaryHeaderColor: colorPrimary.withValues(alpha: 0.16),
  scaffoldBackgroundColor: darkSurfaceBg,
  /* Main Color End */
  /* Text Color Start */

  colorScheme: const ColorScheme.dark(
    surface: white,
    primary: white,
    onPrimary: white,
    secondary: white,
    onSecondary: white,
  ),
  /* Text Color End */
  appBarTheme: const AppBarTheme(
    backgroundColor: darkSurfaceBg,
    systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: darkSurfaceBg,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light),
  ),
  cardColor: darkCardBg,
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: darkCardBg,
  ),
  drawerTheme: const DrawerThemeData(
    backgroundColor: darkCardBg,
  ),
);
