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

List<Color> homeCategoryPalette(BuildContext context) => _isNight(context)
    ? const [
        Color(0xFF7A3F38),
        Color(0xFF8A6A2E),
        Color(0xFF5C4A73),
        Color(0xFF375873),
        Color(0xFF3C6B4F),
      ]
    : const [
        Color(0xFFF3B9B0),
        Color(0xFFF6D8A8),
        Color(0xFFD9C5EE),
        Color(0xFFB9D6F3),
        Color(0xFFB9E4C9),
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
