import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:myBonus/widget/myimage.dart';

// ignore: must_be_immutable
class MyNetworkImage extends StatelessWidget {
  String imageUrl;
  double? imgHeight, imgWidth;
  dynamic fit;
  Color? color;

  MyNetworkImage(
      {super.key,
      required this.imageUrl,
      required this.fit,
      this.color,
      this.imgHeight,
      this.imgWidth});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: imgHeight,
      width: imgWidth,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit,
        imageBuilder: (context, imageProvider) => Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: imageProvider,
              fit: fit,
            ),
          ),
        ),
        // While loading: an animated shimmer (theme-aware) rather than a
        // placeholder picture; the logo image is kept for broken/missing
        // images only (errorWidget below).
        placeholder: (context, url) {
          final bool isNight =
              Theme.of(context).brightness == Brightness.dark;
          return Shimmer.fromColors(
            baseColor: isNight
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.07),
            highlightColor: isNight
                ? Colors.white.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.6),
            period: const Duration(milliseconds: 1100),
            child: Container(
              width: imgWidth,
              height: imgHeight,
              color: Colors.white,
            ),
          );
        },
        errorWidget: (context, url, error) {
          return MyImage(
            width: imgWidth ?? 0.0,
            height: imgHeight ?? 0.0,
            imagePath: "no_image_land.png",
            fit: BoxFit.cover,
          );
        },
      ),
    );
  }
}
