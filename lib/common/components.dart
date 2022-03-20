import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:music_player/common/style.dart';
import 'package:music_player/icons.dart';

class TitledListView extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final List<Widget> subBar;

  const TitledListView({
    required this.title,
    required this.children,
    this.subBar = const [],
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const titlePadding = EdgeInsets.symmetric(horizontal: 25);
    const listPadding = EdgeInsets.all(20);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: titlePadding,
          child: Text(
            title,
            style: Theme.of(context).textTheme.headline3,
          ),
        ),
        ...(subBar.isNotEmpty
            ? [
                Padding(
                  padding: titlePadding.add(const EdgeInsets.only(top: 15)),
                  child: Row(children: subBar),
                )
              ]
            : []),
        Expanded(
          child: ListView(
            controller: ScrollController(),
            padding: listPadding,
            children: children,
          ),
        ),
      ],
    );
  }
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

class PopupAction {
  final String label;
  final String iconAsset;
  final void Function() onSelected;

  const PopupAction({
    required this.label,
    required this.iconAsset,
    required this.onSelected,
  });
}

class PopupMenuActions extends StatelessWidget {
  final List<PopupAction> actions;
  final String? tooltip;

  const PopupMenuActions({
    required this.actions,
    this.tooltip,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      enableFeedback: true,
      tooltip: tooltip,
      onSelected: (selected) {
        actions
            .where((element) => element.label == selected)
            .first
            .onSelected();
      },
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadii.medium,
      ),
      itemBuilder: (BuildContext context) => actions
          .map((action) => PopupMenuItem<String>(
                value: action.label,
                child: Row(
                  children: [
                    AssetIcon(
                      asset: action.iconAsset,
                      color: Colors.white,
                      padding: const EdgeInsets.only(
                        right: 10,
                      ),
                    ),
                    Text(action.label),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class AssetButton extends StatelessWidget {
  final String asset;
  final void Function() onTap;

  final double size;
  final bool circular;
  final bool shadow;
  final String tooltip;

  const AssetButton({
    required this.asset,
    required this.onTap,
    this.size = 24,
    this.circular = true,
    this.shadow = true,
    this.tooltip = '',
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(size)),
        ),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onTap,
            child: Shadowed(
              boxShadow: BoxShadows.regular(context),
              child: AssetIcon(
                width: size,
                height: size,
                asset: asset,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Shadowed extends StatelessWidget {
  final Widget child;

  final BoxShadow? boxShadow;

  const Shadowed({
    required this.child,
    this.boxShadow,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Transform.translate(
          offset: boxShadow?.offset ?? Offset.zero,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaY: (boxShadow?.blurRadius ?? 3),
              sigmaX: (boxShadow?.blurRadius ?? 3),
            ),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.transparent,
                  width: 0,
                ),
              ),
              child: Opacity(
                opacity: (boxShadow?.color.alpha ?? 255) / 255,
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    boxShadow?.color.withAlpha(255) ?? Colors.black,
                    BlendMode.srcATop,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
