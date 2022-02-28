import 'dart:io';

import 'package:flutter/material.dart';
import 'package:music_player/async.dart';
import 'package:music_player/icons.dart';
import 'package:music_player/library.dart';
import 'package:window_size/window_size.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setWindowTitle('Music Player');
  runApp(const Home());
}

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Player',
      theme: ThemeData(),
      home: const Scaffold(
        body: LibraryRenderer(),
      ),
    );
  }
}

class LibraryRenderer extends StatefulWidget {
  const LibraryRenderer({Key? key}) : super(key: key);

  @override
  _LibraryRendererState createState() => _LibraryRendererState();
}

class _LibraryRendererState extends State<LibraryRenderer> {
  late final Loader<Library> library;

  @override
  void initState() {
    library = Loader(() => Library.load(
          Directory('C:\\Users\\bramb\\Music'),
        ));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return EnsureLoaded<Library>(
      loader: library,
      builder: (context, library) {
        for (final album in library.albums) {
          print('${album.author ?? 'Unknown'} - ${album.title}');
        }
        const double rowHeight = 50;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DataTable(
                dataRowHeight: rowHeight,
                columns: const [
                  DataColumn(label: Text('Cover')),
                  DataColumn(label: Text('Title')),
                  DataColumn(label: Text('Author')),
                ],
                rows: library.albums
                    .map((album) => DataRow(
                          cells: [
                            DataCell(
                              album.cover != null
                                  ? SizedBox(
                                      child: Image.file(album.cover!),
                                      width: rowHeight,
                                    )
                                  : Container(
                                      width: rowHeight,
                                      alignment: Alignment.center,
                                      child: AssetIcon(
                                        asset: IconAsset.album,
                                        height: rowHeight * 2 / 3,
                                      ),
                                    ),
                            ),
                            DataCell(Text(album.title)),
                            DataCell(Text(album.author ?? 'Unknown Artist'))
                          ],
                        ))
                    .toList(),
              ),
            ),
            Container(
              color: Colors.black,
              width: 2,
            ),
            Expanded(
              child: DataTable(
                dataRowHeight: rowHeight,
                columns: const [
                  DataColumn(label: Text('Cover')),
                  DataColumn(label: Text('Title')),
                  DataColumn(label: Text('Author')),
                ],
                rows: library.albums
                    .map((album) => DataRow(
                          cells: [
                            DataCell(
                              album.cover != null
                                  ? SizedBox(
                                      child: Image.file(album.cover!),
                                      width: rowHeight,
                                    )
                                  : Container(
                                      width: rowHeight,
                                      alignment: Alignment.center,
                                      child: AssetIcon(
                                        asset: IconAsset.album,
                                        height: rowHeight * 2 / 3,
                                      ),
                                    ),
                            ),
                            DataCell(Text(album.title)),
                            DataCell(Text(album.author ?? 'Unknown Artist'))
                          ],
                        ))
                    .toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}
