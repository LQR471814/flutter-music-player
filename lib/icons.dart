import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class IconAsset {
  static String album = 'icons/album-line.svg';
  static String play = 'icons/play-circle-line.svg';
  static String pause = 'icons/pause-circle-line.svg';
  static String skipForward = 'icons/skip-forward-line.svg';
  static String skipBackward = 'icons/skip-back-line.svg';
}

class AssetIcon extends StatelessWidget {
  final String asset;
  final double? width;
  final double? height;
  final Color? color;

  const AssetIcon({
    required this.asset,
    this.width,
    this.height,
    this.color,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      color: color ?? Theme.of(context).primaryColor,
      width: width,
      height: height,
    );
  }
}

class AssetButton extends StatelessWidget {
  final void Function() onTap;
  final String asset;

  final double? width;
  final double? height;
  final Color? color;

  const AssetButton({
    required this.asset,
    required this.onTap,
    this.width,
    this.height,
    this.color,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AssetIcon(
          asset: asset,
          width: width,
          height: height,
          color: color,
        ),
      ),
    );
  }
}
