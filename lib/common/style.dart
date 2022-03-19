import 'package:flutter/material.dart';

class BoxShadows {
  static BoxShadow regular(BuildContext context) {
    return BoxShadow(
      color: Theme.of(context).shadowColor,
      spreadRadius: -1,
      blurRadius: 3,
      offset: const Offset(0, 4),
    );
  }
}

class BorderRadii {
  static const small = BorderRadius.all(
    Radius.circular(5),
  );

  static const medium = BorderRadius.all(
    Radius.circular(10),
  );

  static const large = BorderRadius.all(
    Radius.circular(15),
  );
}
