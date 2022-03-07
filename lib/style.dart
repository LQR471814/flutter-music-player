import 'package:flutter/material.dart';

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

class Divided extends StatelessWidget {
  final List<Widget> children;
  final Axis axis;
  final double size;
  final Color color;

  const Divided({
    required this.children,
    required this.axis,
    this.size = 3,
    this.color = Colors.black54,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Widget> renderedChildren = [];
    for (int i = 0; i < children.length; i++) {
      if (i == 0) {
        renderedChildren.add(Expanded(child: children[i]));
        continue;
      }
      renderedChildren.add(Container(
        width: axis == Axis.horizontal ? size : null,
        height: axis == Axis.vertical ? size : null,
        color: color,
      ));
      renderedChildren.add(Expanded(child: children[i]));
    }

    return Flex(
      direction: axis,
      children: renderedChildren,
    );
  }
}
