import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_player/common/async.dart';
import 'package:music_player/common/components.dart';
import 'package:music_player/common/utils.dart';
import 'package:music_player/icons.dart';
import 'package:music_player/library.dart';
import 'package:music_player/common/style.dart';
import 'package:window_size/window_size.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setWindowTitle('Music Player');
  runApp(Home());
}

class Home extends StatelessWidget {
  final AudioPlayer _player = AudioPlayer();

  Home({Key? key}) : super(key: key);

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
          headline3: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.bold,
          ),
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
            Player(player: _player),
            Expanded(
              child: LibraryRenderer(
                player: _player,
                onPlay: (track) {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Player extends StatefulWidget {
  final AudioPlayer player;
  const Player({required this.player, Key? key}) : super(key: key);

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

class PlaylistRenderer extends StatelessWidget {
  final Playlist playlist;
  final void Function(Playlist playlist) onChange;

  const PlaylistRenderer({
    required this.playlist,
    required this.onChange,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return playlist.tracks.isEmpty
        ? Padding(
            padding: const EdgeInsets.only(bottom: 80)
                .add(const EdgeInsets.symmetric(horizontal: 60)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AssetIcon(
                  asset: IconAsset.playlist,
                  color: Colors.white70,
                  width: 80,
                  height: 80,
                ),
                const SizedBox(height: 20),
                Text(
                  "The playlist is currently empty",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headline4,
                ),
              ],
            ),
          )
        : TitledListView(
            title: 'Playlist',
            subBar: joinWith<Widget>([
              AssetButton(
                size: 30,
                asset: IconAsset.delete,
                tooltip: 'Clear',
                onTap: () => onChange(playlist.clear()),
              ),
              AssetButton(
                size: 30,
                asset: IconAsset.shuffle,
                tooltip: 'Shuffle',
                onTap: () => onChange(playlist.shuffle()),
              ),
              AssetButton(
                size: 30,
                asset: playlist.loop
                    ? IconAsset.loopEnabled
                    : IconAsset.loopDisabled,
                tooltip: !playlist.loop ? 'Enable looping' : 'Disable looping',
                onTap: () => onChange(playlist.looped(!playlist.loop)),
              ),
            ], const SizedBox(width: 10)),
            children: [
              for (int i = 0; i < playlist.tracks.length; i++)
                CardTrack(
                  selected: i == playlist.current,
                  leading: AlbumCover(album: playlist.tracks[i].belongsTo),
                  title: playlist.tracks[i].title,
                  artists: playlist.tracks[i].artists,
                )
            ],
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
              child: Image.memory(album.cover!),
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

class CardTrack extends StatelessWidget {
  final String title;
  final void Function()? onTap;
  final List<String>? artists;
  final bool selected;
  final Widget? leading;
  final List<PopupAction>? menuActions;

  const CardTrack({
    required this.title,
    this.onTap,
    this.artists,
    this.selected = false,
    this.leading,
    this.menuActions,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        selected: selected,
        contentPadding: const EdgeInsets.all(10),
        onTap: onTap,
        leading: leading,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color:
                      selected ? Theme.of(context).colorScheme.primary : null,
                  fontWeight: selected ? FontWeight.bold : null,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                artists != null
                    ? artists!.isEmpty
                        ? 'Unknown Artist'
                        : artists!.join(', ')
                    : '',
                style: TextStyle(
                  color:
                      selected ? Theme.of(context).colorScheme.primary : null,
                  fontWeight: selected ? FontWeight.bold : null,
                ),
              ),
            ),
            ...(menuActions != null
                ? [
                    PopupMenuActions(
                      actions: menuActions!,
                      tooltip: 'Track options',
                    ),
                  ]
                : [])
          ],
        ),
      ),
    );
  }
}

class LibraryRenderer extends StatefulWidget {
  final AudioPlayer player;
  final Function(Track track) onPlay;

  const LibraryRenderer({
    required this.player,
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
  Playlist _playlist = const Playlist(tracks: []);

  @override
  void initState() {
    _library = Loader(() => Library.load(
          Directory('C:\\Users\\bramb\\Music'),
        ));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return EnsureLoaded<Library>(
      loader: _library,
      builder: (context, library) {
        return Divided(
          axis: Axis.horizontal,
          children: [
            TitledListView(
              title: 'Artists',
              children: [
                CardTrack(
                  title: 'All',
                  selected: _selectedArtist == null,
                  onTap: () => setState(() => _selectedArtist = null),
                ),
                ...library.artists.map((artist) => CardTrack(
                      title: artist,
                      selected: _selectedArtist == artist,
                      onTap: () => setState(() => _selectedArtist = artist),
                    ))
              ],
            ),
            TitledListView(
              title: 'Albums',
              children: (_selectedArtist != null
                      ? library.filterByArtist(library.albums, _selectedArtist!)
                      : library.albums)
                  .map((album) => CardTrack(
                        title: album.title,
                        artists: album.artists,
                        leading: AlbumCover(album: album),
                        selected: _selectedAlbum == album,
                        onTap: () => setState(() => _selectedAlbum =
                            _selectedAlbum == album ? null : album),
                      ))
                  .toList(),
            ),
            _selectedAlbum != null
                ? Column(
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
                                tooltip: 'Play',
                                asset: IconAsset.play,
                                onTap: () => setState(() {
                                  _playlist = _playlist
                                      .withTracks(_selectedAlbum!.tracks);
                                  _selectedAlbum = null;
                                }),
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
                                            textAlign: TextAlign.center,
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
                                    tooltip: 'Playlist options',
                                    actions: [
                                      PopupAction(
                                        label: 'Add to playlist',
                                        iconAsset: IconAsset.playlistAdd,
                                        onSelected: () => setState(() {
                                          _playlist = _playlist
                                              .queue(_selectedAlbum!.tracks);
                                          _selectedAlbum = null;
                                        }),
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
                              .map((track) => CardTrack(
                                    title: track.title,
                                    artists: track.artists,
                                    selected: _selectedTrack == track,
                                    onTap: () => setState(() {
                                      widget.onPlay(track);
                                      _selectedTrack = track;
                                    }),
                                  ))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  )
                : PlaylistRenderer(
                    playlist: _playlist,
                    onChange: (p) => setState(() => _playlist = p),
                  ),
          ],
        );
      },
    );
  }
}
