import 'dart:io';

import 'package:flutter/material.dart';
import 'package:music_player/common/async.dart';
import 'package:music_player/common/components.dart';
import 'package:music_player/icons.dart';
import 'package:music_player/library.dart';
import 'package:music_player/common/style.dart';
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
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color.fromARGB(255, 217, 74, 61),
              brightness: Brightness.dark,
            ),
        fontFamily: 'Calibri',
        cardTheme: const CardTheme(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadii.large,
          ),
        ),
        textTheme: const TextTheme(
          headline4: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
          headline5: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
          headline6: TextStyle(
            fontSize: 18,
          ),
        ),
      ),
      home: Scaffold(
        body: Column(
          children: [
            const Player(),
            Expanded(
              child: LibraryRenderer(
                onPlay: (track) => print(track),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlaylistRenderer extends StatelessWidget {
  final Playlist playlist;

  const PlaylistRenderer({
    required this.playlist,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class Player extends StatefulWidget {
  const Player({Key? key}) : super(key: key);

  @override
  State<Player> createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  double _position = 0;
  bool _playing = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          Slider(
            onChanged: (double value) => setState(() => _position = value),
            divisions: null,
            value: _position,
            max: 1,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AssetButton(
                onTap: () {},
                asset: IconAsset.skipBackward,
                size: 48,
              ),
              AssetButton(
                onTap: () => setState(() => _playing = !_playing),
                asset: !_playing ? IconAsset.play : IconAsset.pause,
                size: 48,
              ),
              AssetButton(
                onTap: () {},
                asset: IconAsset.skipForward,
                size: 48,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AlbumCover extends StatelessWidget {
  final Album album;
  final BorderRadius? borderRadius;

  const AlbumCover({
    required this.album,
    this.borderRadius,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadii.medium,
        boxShadow: album.cover != null ? [BoxShadows.regular(context)] : [],
      ),
      child: album.cover != null
          ? ClipRRect(
              child: Image.file(album.cover!),
              borderRadius: borderRadius ?? BorderRadii.medium,
            )
          : LayoutBuilder(
              builder: (context, constraints) => AssetIcon(
                asset: IconAsset.album,
                width: constraints.maxHeight,
                height: constraints.maxHeight,
                padding: EdgeInsets.symmetric(
                  vertical: constraints.maxHeight / 8,
                ),
              ),
            ),
    );
  }
}

class LibraryRenderer extends StatefulWidget {
  final Function(Track track) onPlay;

  const LibraryRenderer({
    required this.onPlay,
    Key? key,
  }) : super(key: key);

  @override
  _LibraryRendererState createState() => _LibraryRendererState();
}

class _LibraryRendererState extends State<LibraryRenderer> {
  late final Loader<Library> _library;
  String? _selectedArtist;
  Album? _selectedAlbum;
  Track? _selectedTrack;

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
              color: selected ? Theme.of(context).colorScheme.primary : null,
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
              color: selected ? Theme.of(context).colorScheme.primary : null,
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
        return Divided(
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
                        onTap: () => setState(() => _selectedArtist = artist),
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
                      ? library.filterByArtist(library.albums, _selectedArtist!)
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
                          leading: AlbumCover(album: album),
                          title: _buildTitle(
                            title: album.title,
                            artists: album.artists,
                            selected: _selectedAlbum == album,
                          ),
                        ),
                      ))
                  .toList(),
            ),
            ...(_selectedAlbum != null
                ? [
                    Column(
                      children: [
                        Expanded(
                          flex: 2,
                          child: AlbumCover(
                            album: _selectedAlbum!,
                            borderRadius: BorderRadii.large,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15.0,
                                ),
                                child: AssetButton(
                                  size: 50,
                                  asset: IconAsset.play,
                                  onTap: () {},
                                ),
                              ),
                              Flexible(
                                child: Column(
                                  children: [
                                    Text(
                                      _selectedAlbum!.title,
                                      textAlign: TextAlign.center,
                                      style:
                                          Theme.of(context).textTheme.headline5,
                                    ),
                                    ...(_selectedAlbum!.artists.isNotEmpty
                                        ? [
                                            Text(
                                              _selectedAlbum!.artists.join(','),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headline6,
                                            )
                                          ]
                                        : []),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                ),
                                child: Row(
                                  children: [
                                    PopupMenuActions(
                                      tooltip: "Playlist actions",
                                      actions: [
                                        PopupAction(
                                          label: 'Add to playlist',
                                          iconAsset: IconAsset.playlistAdd,
                                          onSelected: () {},
                                        ),
                                        PopupAction(
                                          label: 'Edit metadata',
                                          iconAsset: IconAsset.edit,
                                          onSelected: () {},
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: ListView(
                            controller: ScrollController(),
                            padding: const EdgeInsets.all(20),
                            children: _selectedAlbum!.tracks
                                .map((track) => Card(
                                      clipBehavior: Clip.antiAlias,
                                      child: ListTile(
                                        onTap: () => setState(() {
                                          widget.onPlay(track);
                                          _selectedTrack = track;
                                        }),
                                        contentPadding:
                                            const EdgeInsets.all(10),
                                        title: _buildTitle(
                                          title: track.title,
                                          artists: track.artists,
                                          selected: _selectedTrack == track,
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 10),
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
