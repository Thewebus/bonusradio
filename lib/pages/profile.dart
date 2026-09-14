import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myBonus/pages/editprofile.dart';
import 'package:myBonus/pages/login.dart';
import 'package:myBonus/pages/settings.dart';
import 'package:myBonus/provider/profileprovider.dart';
import 'package:myBonus/provider/subscriptionprovider.dart';
import 'package:myBonus/subscription/subscription.dart';
import 'package:myBonus/utils/color.dart';
import 'package:myBonus/utils/constant.dart';
import 'package:myBonus/utils/sharedpref.dart';
import 'package:myBonus/utils/utils.dart';
import 'package:myBonus/widget/abidjan_header.dart';
import 'package:myBonus/widget/abidjan_stat_pill.dart';
import 'package:myBonus/widget/liveneon_header.dart';
import 'package:myBonus/widget/liveneon_stat_pill.dart';
import 'package:myBonus/widget/mynetworkimg.dart';

class Profile extends StatefulWidget {
  final VoidCallback? onBack;
  const Profile({super.key, this.onBack});

  @override
  // ignore: library_private_types_in_public_api
  ProfileState createState() => ProfileState();
}

class ProfileState extends State<Profile> {
  SharedPref sharedpre = SharedPref();
  late ProfileProvider profileProvider;
  late SubscriptionProvider subscriptionProvider;

  @override
  void initState() {
    profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    subscriptionProvider =
        Provider.of<SubscriptionProvider>(context, listen: false);
    super.initState();
    if (Constant.userID != null) {
      getApi();
      subscriptionProvider.getPackages();
    }
  }

  Future<void> getApi() async {
    await profileProvider.getProfile(context);
  }

  @override
  Widget build(BuildContext context) {
    final bool isNight = Theme.of(context).brightness == Brightness.dark;
    if (Constant.userID == null) {
      return isNight
          ? _buildLiveNeonLoggedOutScaffold()
          : _buildAbidjanLoggedOutScaffold();
    }
    return isNight ? _buildLiveNeonScaffold() : _buildAbidjanScaffold();
  }

  // Compte tab while logged out — the dock's tap handler used to push a
  // full-screen Login() route here instead, which hid the dock and the
  // settings shortcut entirely. Keeping the same header (with its settings
  // gear) and just swapping the body for a sign-in prompt lets Compte behave
  // like every other tab: dock and header stay put, only the content
  // changes. Login() itself is still where the actual phone/Google/email
  // sign-in flow lives — pushed on demand from the button below.
  Widget _buildLiveNeonLoggedOutScaffold() {
    return Scaffold(
      backgroundColor: liveNeonBg,
      body: SafeArea(
        child: Container(
          decoration: liveNeonBackgroundDecoration(),
          child: Column(
            children: [
              LiveNeonHeader(
                title: "profile",
                actions: [
                  LiveNeonCircleIconButton(
                    icon: Icons.settings,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const Settings()),
                      );
                    },
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: liveNeonIconChipBg,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_outline,
                            color: white, size: 40),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Connecte-toi pour accéder à ton compte",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Retrouve ton profil, tes favoris et ton abonnement.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: liveNeonTextSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const Login()),
                            );
                          },
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              gradient:
                                  LinearGradient(colors: liveNeonGradient),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(30)),
                            ),
                            child: const Text(
                              "Se connecter",
                              style: TextStyle(
                                color: white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAbidjanLoggedOutScaffold() {
    return Scaffold(
      backgroundColor: homeAccueilBg(context),
      body: SafeArea(
        child: Column(
          children: [
            AbidjanHeader(
              title: "profile",
              actions: settingsAppBarAction(context, light: true),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: abidjanIconChipBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_outline,
                          color: black, size: 40),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Connecte-toi pour accéder à ton compte",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: black,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Retrouve ton profil, tes favoris et ton abonnement.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: gray,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const Login()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: black,
                            borderRadius: BorderRadius.all(Radius.circular(30)),
                          ),
                          child: const Text(
                            "Se connecter",
                            style: TextStyle(
                              color: white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // LIVE NEON (night theme): same structure as ABIDJAN (flat header +
  // settings shortcut, profile card, stat row, subscription promo, list
  // card) recolored for the neon palette. Every handler (getApi, EditProfile
  // navigation, favourite/download placeholders, Réglages navigation) is
  // shared with day.
  Widget _buildLiveNeonScaffold() {
    return Scaffold(
      backgroundColor: liveNeonBg,
      body: SafeArea(
        child: Container(
          decoration: liveNeonBackgroundDecoration(),
          child: Column(
            children: [
              LiveNeonHeader(
                title: "profile",
                actions: [
                  LiveNeonCircleIconButton(
                    icon: Icons.settings,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const Settings()),
                      );
                    },
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                  child: Consumer<ProfileProvider>(
                    builder: (context, profileprovider, child) {
                      if (profileprovider.loading) {
                        return Utils.pageLoader();
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLiveNeonProfileCard(profileprovider),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: liveNeonCardBg,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: liveNeonBorder),
                            ),
                            child: const LiveNeonStatRow(stats: [
                              LiveNeonStat(value: "--", label: "Écoutes"),
                              LiveNeonStat(value: "--", label: "Favoris"),
                              LiveNeonStat(value: "--", label: "Hors ligne"),
                            ]),
                          ),
                          const SizedBox(height: 20),
                          _buildLiveNeonSubscriptionPromo(),
                          const SizedBox(height: 20),
                          _buildLiveNeonListCard(),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveNeonProfileCard(ProfileProvider profileprovider) {
    final hasProfile = profileprovider.profileModel.result != null &&
        profileprovider.profileModel.result!.isNotEmpty;
    final item = hasProfile ? profileprovider.profileModel.result![0] : null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: liveNeonCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: liveNeonBorder),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(35),
            child: MyNetworkImage(
              fit: BoxFit.cover,
              imgWidth: 70,
              imgHeight: 70,
              imageUrl: item?.image?.toString() ?? "",
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item?.fullName?.toString() ?? "",
                  style: const TextStyle(
                    color: white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item?.mobileNumber?.toString() ?? "",
                  style: const TextStyle(
                    color: liveNeonTextSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return const EditProfile();
                  },
                ),
              );
            },
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: liveNeonIconChipBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit, size: 16, color: white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveNeonSubscriptionPromo() {
    return Consumer<SubscriptionProvider>(
      builder: (context, subscriptionprovider, child) {
        final packages = subscriptionprovider.subscriptionModel.result ?? [];
        String? price;
        String? time;
        double? bestValue;
        for (final p in packages) {
          final parsed = double.tryParse(p.price?.toString() ?? "");
          if (parsed == null) continue;
          if (bestValue == null || parsed < bestValue) {
            bestValue = parsed;
            price = p.price?.toString();
            time = p.time?.toString();
          }
        }
        if (price == null) return const SizedBox.shrink();

        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const Subscription(openFrom: ''),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: liveNeonGradient),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Passez à l'offre premium",
                        style: TextStyle(
                          color: white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${Constant.currencySymbol}$price${time != null && time.isNotEmpty ? ' / $time' : ''}",
                        style: TextStyle(
                          color: white.withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: white, size: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLiveNeonListCard() {
    Widget row({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
    }) {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: liveNeonIconChipBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: liveNeonTextSecondary, size: 20),
            ],
          ),
        ),
      );
    }

    Widget divider() => Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          color: liveNeonBorder,
        );

    return Container(
      decoration: BoxDecoration(
        color: liveNeonCardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: liveNeonBorder),
      ),
      child: Column(
        children: [
          row(
            icon: Icons.favorite_border,
            label: "Mes favoris",
            // Visual-only — there is no favourites-listing screen yet.
            onTap: () => Utils.showToast("Bientôt disponible"),
          ),
          divider(),
          row(
            icon: Icons.download_outlined,
            label: "Téléchargements",
            // Visual-only — there is no offline-downloads feature yet.
            onTap: () => Utils.showToast("Bientôt disponible"),
          ),
          divider(),
          row(
            icon: Icons.settings_outlined,
            label: "Réglages",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const Settings(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ABIDJAN (day theme): flat header + settings shortcut, profile card
  // (real name/phone/avatar, no masking), placeholder stat row, a real
  // cheapest-plan subscription promo, and a list card (Réglages real nav,
  // Favoris/Téléchargements visual-only per plan decision).
  Widget _buildAbidjanScaffold() {
    return Scaffold(
      backgroundColor: homeAccueilBg(context),
      body: SafeArea(
        child: Column(
          children: [
            AbidjanHeader(
              title: "profile",
              actions: settingsAppBarAction(context, light: true),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                child: Consumer<ProfileProvider>(
                  builder: (context, profileprovider, child) {
                    if (profileprovider.loading) {
                      return Utils.pageLoader();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAbidjanProfileCard(profileprovider),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const AbidjanStatRow(stats: [
                            AbidjanStat(value: "--", label: "Écoutes"),
                            AbidjanStat(value: "--", label: "Favoris"),
                            AbidjanStat(value: "--", label: "Hors ligne"),
                          ]),
                        ),
                        const SizedBox(height: 20),
                        _buildAbidjanSubscriptionPromo(),
                        const SizedBox(height: 20),
                        _buildAbidjanListCard(),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbidjanProfileCard(ProfileProvider profileprovider) {
    final hasProfile = profileprovider.profileModel.result != null &&
        profileprovider.profileModel.result!.isNotEmpty;
    final item = hasProfile ? profileprovider.profileModel.result![0] : null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(35),
            child: MyNetworkImage(
              fit: BoxFit.cover,
              imgWidth: 70,
              imgHeight: 70,
              imageUrl: item?.image?.toString() ?? "",
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item?.fullName?.toString() ?? "",
                  style: const TextStyle(
                    color: black,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item?.mobileNumber?.toString() ?? "",
                  style: const TextStyle(
                    color: gray,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return const EditProfile();
                  },
                ),
              );
            },
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: abidjanIconChipBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit, size: 16, color: black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbidjanSubscriptionPromo() {
    return Consumer<SubscriptionProvider>(
      builder: (context, subscriptionprovider, child) {
        final packages = subscriptionprovider.subscriptionModel.result ?? [];
        String? price;
        String? time;
        double? bestValue;
        for (final p in packages) {
          final parsed = double.tryParse(p.price?.toString() ?? "");
          if (parsed == null) continue;
          if (bestValue == null || parsed < bestValue) {
            bestValue = parsed;
            price = p.price?.toString();
            time = p.time?.toString();
          }
        }
        if (price == null) return const SizedBox.shrink();

        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const Subscription(openFrom: ''),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [colorAccent, colorPrimary],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Passez à l'offre premium",
                        style: TextStyle(
                          color: white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${Constant.currencySymbol}$price${time != null && time.isNotEmpty ? ' / $time' : ''}",
                        style: TextStyle(
                          color: white.withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: white, size: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAbidjanListCard() {
    Widget row({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
    }) {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: abidjanIconChipBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: black),
              ),
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
              const Icon(Icons.chevron_right, color: gray, size: 20),
            ],
          ),
        ),
      );
    }

    Widget divider() => Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          color: lightgray,
        );

    return Container(
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          row(
            icon: Icons.favorite_border,
            label: "Mes favoris",
            // Visual-only — there is no favourites-listing screen yet.
            onTap: () => Utils.showToast("Bientôt disponible"),
          ),
          divider(),
          row(
            icon: Icons.download_outlined,
            label: "Téléchargements",
            // Visual-only — there is no offline-downloads feature yet.
            onTap: () => Utils.showToast("Bientôt disponible"),
          ),
          divider(),
          row(
            icon: Icons.settings_outlined,
            label: "Réglages",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const Settings(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

}
