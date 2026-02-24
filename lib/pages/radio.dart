import 'package:flutter/material.dart';
import 'package:myBonus/music/musicdetails.dart';

class RadioScreen extends StatefulWidget {
  const RadioScreen({super.key});

  @override
  State<RadioScreen> createState() => _RadioScreenState();
}

class _RadioScreenState extends State<RadioScreen> {
  @override
  void initState() {
    super.initState();
    // Force player to expand when entering Radio screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      playerExpandProgress.value = MediaQuery.of(context).size.height;
    });

    // Keep player expanded while on Radio screen
    playerExpandProgress.addListener(_onPlayerHeightChanged);
  }

  void _onPlayerHeightChanged() {
    // If player is being minimized, keep it expanded
    if (playerExpandProgress.value < MediaQuery.of(context).size.height * 0.8) {
      playerExpandProgress.value = MediaQuery.of(context).size.height;
    }
  }

  @override
  void dispose() {
    playerExpandProgress.removeListener(_onPlayerHeightChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const MusicDetails(ishomepage: false);
  }
}
