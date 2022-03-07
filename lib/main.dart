import 'dart:io';

import 'package:flutter/material.dart';
import 'package:music_player/async.dart';
import 'package:music_player/icons.dart';
import 'package:music_player/library.dart';
import 'package:music_player/style.dart';
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
      theme: ThemeData(
        brightness: Brightness.dark,
        shadowColor: const Color.fromARGB(40, 20, 20, 20),
        // primaryColorLight: const Color.fromARGB(200, 200, 200, 255),
        // primaryColorDark: const Color.fromARGB(199, 169, 255, 157),
        fontFamily: 'Calibri',
        cardTheme: const CardTheme(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadii.large,
          ),
        ),
      ),
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
  late final Loader<Library> _library;
  String? _selectedArtist;
  Album? _selectedAlbum;

  @override
  void initState() {
    _library = Loader(() => Library.load(
          Directory('C:\\Users\\bramb\\Music'),
        ));
    super.initState();
  }

  Widget _buildTitle({
    required String title,
    required bool selected,
    List<String>? artists,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: selected ? FontWeight.bold : null,
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Text(
            artists != null
                ? artists.isEmpty
                    ? 'Unknown Artist'
                    : artists.join(', ')
                : '',
            style: TextStyle(
              fontWeight: selected ? FontWeight.bold : null,
            ),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return EnsureLoaded<Library>(
      loader: _library,
      builder: (context, library) {
        for (final album in library.albums) {
          print('${album.artists.isNotEmpty ? album.artists : 'Unknown'} '
              '${album.artists.length} - ${album.title}');
        }
        return Divided(
          axis: Axis.vertical,
          children: [
            Divided(
              axis: Axis.horizontal,
              children: [
                ListView(
                  controller: ScrollController(),
                  padding: const EdgeInsets.all(20),
                  children: [
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        selected: _selectedArtist == null,
                        contentPadding: const EdgeInsets.all(10),
                        onTap: () => setState(() => _selectedArtist = null),
                        title: _buildTitle(
                          title: 'All',
                          selected: _selectedArtist == null,
                        ),
                      ),
                    ),
                    ...library.artists.map((artist) => Card(
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            selected: _selectedArtist == artist,
                            contentPadding: const EdgeInsets.all(10),
                            onTap: () =>
                                setState(() => _selectedArtist = artist),
                            title: _buildTitle(
                              title: artist,
                              selected: _selectedArtist == artist,
                            ),
                          ),
                        ))
                  ],
                ),
                ListView(
                  controller: ScrollController(),
                  padding: const EdgeInsets.all(20),
                  children: (_selectedArtist != null
                          ? library.filterByArtist(
                              library.albums, _selectedArtist!)
                          : library.albums)
                      .map((album) => Card(
                            clipBehavior: Clip.antiAlias,
                            child: ListTile(
                              selected: _selectedAlbum == album,
                              contentPadding: const EdgeInsets.all(10),
                              onTap: () => setState(
                                () => _selectedAlbum =
                                    _selectedAlbum == album ? null : album,
                              ),
                              leading: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadii.medium,
                                  boxShadow: album.cover != null
                                      ? [
                                          BoxShadow(
                                            color:
                                                Theme.of(context).shadowColor,
                                            spreadRadius: -1,
                                            blurRadius: 3,
                                            offset: const Offset(0, 4),
                                          )
                                        ]
                                      : [],
                                ),
                                child: album.cover != null
                                    ? ClipRRect(
                                        child: Image.file(album.cover!),
                                        borderRadius: BorderRadii.medium,
                                      )
                                    : Container(
                                        width: 48,
                                        height: 48,
                                        alignment: Alignment.center,
                                        child: AssetIcon(
                                          width: 42,
                                          height: 42,
                                          asset: IconAsset.album,
                                        ),
                                      ),
                              ),
                              title: _buildTitle(
                                title: album.title,
                                artists: album.artists,
                                selected: _selectedAlbum == album,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
            ...(_selectedAlbum != null
                ? [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ListView(
                            controller: ScrollController(),
                            padding: const EdgeInsets.all(20),
                            children: _selectedAlbum!.tracks
                                .map((track) => Card(
                                      clipBehavior: Clip.antiAlias,
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.all(10),
                                        title: _buildTitle(
                                          title: track.title,
                                          artists: track.artists,
                                          selected: false,
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                    )
                  ]
                : []),
          ],
        );
      },
    );
  }
}
