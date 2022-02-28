import 'package:flutter/widgets.dart';

class GeneralLoader<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(BuildContext context, T value) builder;
  const GeneralLoader({
    required this.future,
    required this.builder,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.data == null) {
          return Container();
        }
        return builder(context, snapshot.data!);
      },
    );
  }
}

class Loader<T> {
  T? value;
  late final Future<T> future;

  Loader(Future<T> Function() loader) {
    future = loader();
  }
}

class EnsureLoaded<T> extends StatelessWidget {
  final Loader<T> loader;
  final Widget Function(BuildContext context, T value) builder;

  const EnsureLoaded({
    required this.loader,
    required this.builder,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (loader.value == null) {
      return GeneralLoader<T>(
        future: loader.future,
        builder: (_, v) => builder(context, v),
      );
    }
    return builder(context, loader.value!);
  }
}
