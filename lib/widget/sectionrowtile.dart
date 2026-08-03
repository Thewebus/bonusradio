import 'package:flutter/material.dart';
import 'package:myBonus/utils/color.dart';
import 'package:myBonus/utils/dimens.dart';
import 'package:myBonus/widget/myimage.dart';
import 'package:myBonus/widget/mynetworkimg.dart';
import 'package:myBonus/widget/mytext.dart';

// ignore: must_be_immutable
class SectionRowTile extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String subtitle;
  final bool isPremium;
  final VoidCallback onTap;
  final VoidCallback onPlayTap;
  final VoidCallback onFavouriteTap;
  final VoidCallback onShareTap;

  const SectionRowTile({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.isPremium,
    required this.onTap,
    required this.onPlayTap,
    required this.onFavouriteTap,
    required this.onShareTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      focusColor: transparent,
      splashColor: transparent,
      hoverColor: transparent,
      highlightColor: transparent,
      onTap: onTap,
      child: SizedBox(
        height: Dimens.listRowHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          child: Row(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: MyNetworkImage(
                      imgWidth: 56,
                      imgHeight: 56,
                      fit: BoxFit.cover,
                      imageUrl: imageUrl,
                    ),
                  ),
                  if (isPremium)
                    Positioned(
                      top: 3,
                      left: 3,
                      child: Container(
                        width: 18,
                        height: 18,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorPrimary,
                        ),
                        child: MyImage(
                          width: 10,
                          height: 10,
                          color: white,
                          imagePath: "ic_primium.png",
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MyText(
                      color: Theme.of(context).colorScheme.surface,
                      text: title,
                      multilanguage: false,
                      textalign: TextAlign.left,
                      fontsize: Dimens.textDesc,
                      inter: 1,
                      maxline: 1,
                      fontwaight: FontWeight.w600,
                      overflow: TextOverflow.ellipsis,
                      fontstyle: FontStyle.normal,
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      MyText(
                        color: gray,
                        text: subtitle,
                        multilanguage: false,
                        textalign: TextAlign.left,
                        fontsize: Dimens.textSmall,
                        inter: 1,
                        maxline: 1,
                        fontwaight: FontWeight.w400,
                        overflow: TextOverflow.ellipsis,
                        fontstyle: FontStyle.normal,
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert,
                    color: Theme.of(context).colorScheme.surface),
                onSelected: (value) {
                  if (value == "favourite") {
                    onFavouriteTap();
                  } else if (value == "share") {
                    onShareTap();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: "favourite",
                    child: Text("Ajouter aux favoris"),
                  ),
                  PopupMenuItem(
                    value: "share",
                    child: Text("Partager"),
                  ),
                ],
              ),
              InkWell(
                focusColor: transparent,
                splashColor: transparent,
                hoverColor: transparent,
                highlightColor: transparent,
                onTap: onPlayTap,
                child: Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorPrimary,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
