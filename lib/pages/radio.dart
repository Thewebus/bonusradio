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
    // Force player to expand once when entering Radio screen. No
    // continuous re-forcing listener here: it used to fight the
    // collapse-on-tab-change animation (playerExpandProgress is shared
    // with the persistent overlay in home.dart), causing the full player
    // to intermittently stay stuck open after switching tabs.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      playerExpandProgress.value = MediaQuery.of(context).size.height;
    });
  }

  @override
  Widget build(BuildContext context) {
    return const MusicDetails(ishomepage: false);
  }
}
