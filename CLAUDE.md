# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Flutter app for "myBonus" / "Bonus Radio" (Côte d'Ivoire), a radio/podcast/video-on-demand platform with in-app purchases. Package name `com.bonusmultimedia.mybonus`. The app is a pure API client — all content, payments validation, and admin management live in a **separate sibling repo**, the Laravel backend `bonusradioadmin` (not in this checkout). `lib/utils/constant.dart`'s `baseurl` points at `https://admin.mybonusmultimedia.com/public/api/`; if an API response is missing a field or behaves unexpectedly, the fix is almost always in that other repo, not here.

## Commands

```bash
flutter pub get                 # install dependencies (do this first; two path deps live under packages/chewie and packages/vimeo)
flutter analyze                 # static analysis — the actual quality gate for this repo, run before considering any change done
flutter run                     # run on a connected device/emulator
flutter build apk --release     # release Android build, output at build/app/outputs/flutter-apk/app-release.apk
```

There is no meaningful automated test suite: `test/widget_test.dart` is still the unmodified Flutter counter-app template (asserts text `'0'`/`'1'` against a counter UI the app no longer has) and fails/is irrelevant if run. Don't treat `flutter test` as a verification step — correctness is checked via `flutter analyze` plus manual/on-device verification (`adb install` + exercise the feature), not a test suite.

## Architecture

### State management
One `ChangeNotifier` provider per feature area in `lib/provider/`, all registered in the single `MultiProvider` in `main.dart`. Pages grab what they need via `Provider.of<X>(context, listen: false)` in `initState` for one-shot calls (fetch on load, pagination), and wrap only the specific subtree that needs to rebuild in `Consumer<X>`. **Gotcha**: a widget that reads a provider's state directly (not inside that provider's own `Consumer`) will not rebuild when that provider calls `notifyListeners()` if the subtree's actual rebuild trigger is a *different* provider's `Consumer` — always wrap the narrowest subtree that needs the data in its own `Consumer<ThatProvider>`.

### Networking & models
`lib/webservice/apiservices.dart` is a single `ApiService` class with one method per backend endpoint (`dio`-based, logs requests via `pretty_dio_logger` in debug). Each endpoint has a matching hand-written model in `lib/model/` following a `fromJson`/`toJson` convention (no codegen). When two endpoints return byte-identical JSON shapes (because they're backed by the same backend table/response helper), the same model is deliberately reused instead of duplicated — e.g. `LiveEventModel.Result` parses live events, on-demand videos, and video-series episodes alike (videos are live-event rows with `is_vod=1`; episodes add `video_series_id`/`episode_number`, both null for the other two). Where two model files define their own same-named `Result` class and both are needed in one file, import one with a prefix (`import '...videocategorymodel.dart' as videocategory;`) rather than renaming the class.

### Day/night theming: ABIDJAN vs LIVE NEON
The app has two parallel, hand-built visual systems rather than one Material theme with swapped colors: **ABIDJAN** (day) and **LIVE NEON** (night), picked via `Theme.of(context).brightness` (driven by `ThemeProvider`, user-selectable Auto/Jour/Nuit in Settings). Pages that have been redesigned branch at the root of `build()`: a `_buildAbidjanXxx()` method and a `_buildLiveNeonXxx()` method, both calling the *same* shared business-logic methods/closures (API calls, navigation, playback) — only markup differs between the two, business logic is never duplicated per theme. Shared visual tokens live in `lib/utils/color.dart` as functions taking `BuildContext` and branching on brightness (e.g. `homeAccueilBg(context)`), not static `Color` consts. Paired widgets live side by side in `lib/widget/` as `abidjan_*.dart` / `liveneon_*.dart` (headers, pill filters, bokeh cards, stat pills). Not every page has been through this redesign yet — check whether a page already has `_buildAbidjanXxx`/`_buildLiveNeonXxx` methods before assuming the split exists.

### Text & fonts
All text goes through the `MyText` widget, not raw `Text`. Its `multilanguage` flag controls whether `text` is looked up in the active locale dictionary or rendered literally (e.g. for proper nouns/data from the API). The `inter` param (1–4) selects a font family (Poppins/Inter/.../Playfair Display for ABIDJAN headlines) — the same switch is duplicated in `lib/widget/mytext.dart` and `lib/utils/utils.dart`'s `googleFontStyle`; keep both in sync if you add a font.

### i18n
`flutter_locales`, with JSON dictionaries per language in `assets/locales/*.json` (14 languages). Default language is forced to `fr` on first launch (see `_setDefaultLanguageIfNeeded` in `main.dart`). A `DateFormat` in a given locale needs `initializeDateFormatting(code, null)` called first — already done for all supported codes in `main()`, but relevant if you add a new locale-aware date format.

### Playback & payments
Audio/video playback is coordinated through two globals rather than a provider: `musicManager` (declared in `lib/music/musicdetails.dart`) drives audio playback, and `currentlyPlaying` (a `ValueNotifier<AudioPlayer?>`, declared in `lib/pages/home.dart`) drives the persistent mini-player — most pages mount `MusicDetails(ishomepage: true)` at the bottom of a `Stack` via `ValueListenableBuilder` on `currentlyPlaying`. The pay-to-unlock-or-play decision (login required only to pay, never to play already-free/unlocked content) is centralized in `Utils.handleVideoContentTap` in `lib/utils/utils.dart`, reused by live events, videos, and video-series episodes rather than reimplemented per screen. `lib/subscription/allpayment.dart` is the single checkout screen for every payable content type (subscriptions, live events, videos), parameterized by `payType`/`itemId`/`contentType`, fronting Stripe/PayPal/Razorpay/in-app-purchase.

### Local path packages
`chewie` and `vimeo_video_player` are vendored under `packages/` and referenced via `path:` dependencies in `pubspec.yaml`, not pulled from pub.dev — check there first if a player-related bug looks like it's inside a dependency.
