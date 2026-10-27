import 'package:flutter/material.dart';
import 'package:myBonus/pages/settings.dart';
import 'package:myBonus/utils/datausage.dart';
import 'package:myBonus/utils/network.dart';

// Root navigator (MaterialApp in main.dart): the banner sits above it, so it
// can't use its own context to open a page.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

// Mounted once above every screen (MaterialApp.builder in main.dart):
// - a persistent "no internet" pill with a Retry action while offline;
// - otherwise the discreet mobile-data reminder; tapping it opens Settings
//   (Qualité audio).
class NetworkBanner extends StatelessWidget {
  const NetworkBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      top: MediaQuery.of(context).padding.top + 8,
      child: ValueListenableBuilder<bool>(
        valueListenable: NetworkService.isOnline,
        builder: (context, online, _) {
          return ValueListenableBuilder<String?>(
            valueListenable: MobileDataWatcher.warning,
            builder: (context, dataWarning, _) {
              Widget? pill;
              if (!online) {
                pill = _Pill(
                  key: const ValueKey('offline'),
                  icon: Icons.wifi_off_rounded,
                  color: const Color(0xFFB3261E),
                  text: "Pas de connexion internet",
                  action: "Réessayer",
                  onTap: NetworkService.check,
                );
              } else if (dataWarning != null) {
                pill = _Pill(
                  key: const ValueKey('data'),
                  icon: Icons.signal_cellular_alt,
                  color: const Color(0xE6202020),
                  text: dataWarning,
                  action: "Réglages",
                  onTap: () {
                    MobileDataWatcher.dismiss();
                    appNavigatorKey.currentState?.push(
                        MaterialPageRoute(builder: (_) => const Settings()));
                  },
                );
              }
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SizeTransition(sizeFactor: animation, child: child),
                ),
                child: pill ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final String? action;
  final VoidCallback onTap;

  const _Pill({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
    required this.onTap,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 10),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (action != null)
                Text(
                  action!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
