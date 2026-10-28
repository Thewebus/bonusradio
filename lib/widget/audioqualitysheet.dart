import 'package:flutter/material.dart';
import 'package:myBonus/music/musicdetails.dart';
import 'package:myBonus/utils/audioquality.dart';
import 'package:myBonus/utils/color.dart';

const Map<String, String> audioQualityLabels = {
  AudioQuality.auto: "Automatique",
  AudioQuality.high: "Haute",
  AudioQuality.standard: "Standard",
  AudioQuality.low: "Économie",
};

// Live radio quality picker (Auto / Haute / Standard / Économie, with the
// station's real bitrates) — from Settings > Qualité audio and the Radios
// player's quality button. Saves the choice and switches the live radio
// being played to it at once.
Future<void> showAudioQualitySheet(BuildContext context) async {
  final List<int> bitrates = AudioQuality.bitrates.value;
  // Actual bitrates from the station's AzuraCast mounts, when known.
  // "192 kbps · environ 1,4 Mo par minute"
  // (kbps × 60 s ÷ 8 bits ÷ 1000 = Mo per minute).
  String rate(int b) =>
      "$b kbps · environ ${(b * 0.0075).toStringAsFixed(1).replaceAll('.', ',')} Mo par minute";
  String kbps(String value, {bool cellular = false}) {
    final int? b = AudioQuality.bitrateForMode(value, cellular: cellular);
    return b == null ? "" : " · ${rate(b)}";
  }

  final int? autoWifi =
      AudioQuality.bitrateForMode(AudioQuality.auto, cellular: false);
  final int? autoCellular =
      AudioQuality.bitrateForMode(AudioQuality.auto, cellular: true);
  final Map<String, String> hints = {
    AudioQuality.auto: autoWifi == null
        ? "Haute en Wi-Fi, standard en données mobiles"
        : "$autoWifi kbps en Wi-Fi, ${rate(autoCellular!)} en données mobiles",
    AudioQuality.high:
        "Meilleur son, consomme plus de données${kbps(AudioQuality.high)}",
    AudioQuality.standard:
        "Bon compromis son / données${kbps(AudioQuality.standard)}",
    AudioQuality.low: "Consomme moins de données${kbps(AudioQuality.low)}",
  };
  // Explicit ABIDJAN / LIVE NEON colors: the active choice gets the brand
  // red radio, bold label, tinted row and a check, in both themes.
  final bool night = Theme.of(context).brightness == Brightness.dark;
  final Color bg = night ? liveNeonCardBg : white;
  final Color fg = night ? white : black;
  final Color fgSoft = night ? liveNeonTextSecondary : gray;
  final String current = AudioQuality.mode.value;
  final String? picked = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: bg,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        child: RadioGroup<String>(
          groupValue: current,
          onChanged: (v) => Navigator.pop(sheetContext, v),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Qualité audio",
                    style: TextStyle(
                        color: fg, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              for (final entry in audioQualityLabels.entries)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  child: RadioListTile<String>(
                    value: entry.key,
                    selected: entry.key == current,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    selectedTileColor:
                        colorPrimary.withValues(alpha: night ? 0.18 : 0.08),
                    fillColor: WidgetStateProperty.resolveWith((states) =>
                        states.contains(WidgetState.selected)
                            ? colorPrimary
                            : fgSoft),
                    title: Text(
                      entry.value,
                      style: TextStyle(
                        color: entry.key == current ? colorPrimary : fg,
                        fontSize: 15,
                        fontWeight: entry.key == current
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      hints[entry.key] ?? "",
                      style: TextStyle(color: fgSoft, fontSize: 12),
                    ),
                    secondary: entry.key == current
                        ? const Icon(Icons.check_rounded, color: colorPrimary)
                        : null,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
              if (bitrates.length < 2)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: Text(
                    bitrates.isEmpty
                        ? "La radio ne propose qu'un seul débit pour l'instant."
                        : "La radio ne propose qu'un seul débit pour l'instant (${bitrates.first} kbps) : ce réglage s'appliquera dès qu'un autre sera disponible.",
                    style: TextStyle(color: fgSoft, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    ),
  );
  if (picked == null) return;
  await AudioQuality.setMode(picked);
  await AudioQuality.applyToCurrent(audioPlayer);
}
