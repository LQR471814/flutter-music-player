import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

class IconAsset {
  static String album = 'icons/album-line.svg';
}

class AssetIcon extends StatelessWidget {
  final String asset;
  final double? width;
  final double? height;

  const AssetIcon({
    required this.asset,
    this.width,
    this.height,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: width,
      height: height,
    );
  }
}
