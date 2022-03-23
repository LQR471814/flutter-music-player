import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:music_player/common/async.dart';
import 'package:music_player/common/components.dart';
import 'package:music_player/common/utils.dart';
import 'package:music_player/icons.dart';
import 'package:music_player/library.dart';
import 'package:music_player/common/style.dart';
import 'package:window_size/window_size.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows) {
    setWindowTitle('Music Player');
  }
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
  runApp(Home());
}

class Home extends StatelessWidget {
  final playlist = Playlist(player: AudioPlayer());

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
        tooltipTheme: const TooltipThemeData(
          showDuration: Duration.zero,
        ),
      ),
      home: Scaffold(
        body: Column(
          children: [
            Player(
              playlist: playlist,
            ),
            Expanded(
              child: LibraryRenderer(
                playlist: playlist,
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
  final Playlist playlist;
  const Player({required this.playlist, Key? key}) : super(key: key);

  @override
  State<Player> createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  final List<StreamSubscription> subscriptions = [];
  Duration _position = const Duration();
  bool _playing = false;
  bool _previouslyEnabled = false;

  @override
  void initState() {
    subscriptions.add(
      widget.playlist.onUpdate.listen((event) => setState(() {
            if (!widget.playlist.player.playing &&
                widget.playlist.current == null) {
              _playing = false;
              _position = const Duration();
            }
          })),
    );
    subscriptions.add(
      widget.playlist.player.positionStream.listen((event) {
        _playing = widget.playlist.player.playing;
        if (widget.playlist.player.duration != null) {
          setState(() {
            _position = event;
          });
        }
      }),
    );
    super.initState();
  }

  @override
  void dispose() {
    for (final s in subscriptions) {
      s.cancel();
    }
    super.dispose();
  }

  bool get controlsEnabled => widget.playlist.current != null;

  bool sliderEnabled() =>
      widget.playlist.player.duration != null && controlsEnabled;

  @override
  Widget build(BuildContext context) {
    final current = widget.playlist.current;
    return Padding(
      padding: const EdgeInsets.all(15),
      child: LayoutBuilder(builder: (context, constraints) {
        return Row(
          children: [
            ...(current != null
                ? [
                    ConstrainedBox(
                      constraints:
                          BoxConstraints(maxWidth: constraints.maxWidth / 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 80,
                            child: AlbumCover(
                              album: current.belongsTo,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  current.title,
                                  style: Theme.of(context).textTheme.headline5,
                                ),
                                Text(
                                  current.artists.isEmpty
                                      ? "Unknown Artist"
                                      : current.artists.join(', '),
                                  style: Theme.of(context).textTheme.headline6,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                        ],
                      ),
                    ),
                  ]
                : []),
            Expanded(
              child: Column(
                children: [
                  Slider(
                    onChangeStart: (double value) {
                      if (sliderEnabled()) {
                        _previouslyEnabled = widget.playlist.player.playing;
                        if (_previouslyEnabled) {
                          widget.playlist.player.pause();
                        }
                      }
                    },
                    onChangeEnd: (double value) {
                      if (sliderEnabled()) {
                        widget.playlist.player
                            .seek(widget.playlist.player.duration! * value);
                        if (_previouslyEnabled) {
                          widget.playlist.player.play();
                        }
                      }
                    },
                    onChanged: (double value) {
                      if (sliderEnabled()) {
                        setState(() {
                          _position = widget.playlist.player.duration! * value;
                        });
                      }
                    },
                    value: (widget.playlist.player.duration != null
                            ? _position.inMilliseconds /
                                widget.playlist.player.duration!.inMilliseconds
                            : 0)
                        .clamp(0, 1)
                        .toDouble(),
                    max: 1,
                  ),
                  Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 25),
                        child: Text(
                          timestamp(_position),
                          style: Theme.of(context).textTheme.headline5,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AssetButton(
                            active: widget.playlist.hasPrevious(),
                            onTap: () => widget.playlist.previous(),
                            asset: IconAsset.skipBackward,
                            tooltip: "Previous",
                            size: 48,
                          ),
                          AssetButton(
                            active: controlsEnabled,
                            onTap: () => setState(() {
                              if (widget.playlist.player.playing) {
                                widget.playlist.pause();
                                return;
                              }
                              widget.playlist.player.play();
                            }),
                            asset: !_playing ? IconAsset.play : IconAsset.pause,
                            tooltip: !_playing ? "Play" : "Pause",
                            size: 48,
                          ),
                          AssetButton(
                            active: widget.playlist.hasNext(),
                            onTap: () => widget.playlist.next(),
                            asset: IconAsset.skipForward,
                            tooltip: "Next",
                            size: 48,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

class PlaylistRenderer extends StatefulWidget {
  final Playlist playlist;

  const PlaylistRenderer({
    required this.playlist,
    Key? key,
  }) : super(key: key);

  @override
  State<PlaylistRenderer> createState() => _PlaylistRendererState();
}

class _PlaylistRendererState extends State<PlaylistRenderer> {
  final List<StreamSubscription> subscriptions = [];

  @override
  void initState() {
    subscriptions.add(
      widget.playlist.onUpdate.listen((event) => setState(() {})),
    );
    super.initState();
  }

  @override
  void dispose() {
    for (final s in subscriptions) {
      s.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.playlist.tracks.isEmpty
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
                onTap: () => widget.playlist.clear(),
              ),
              AssetButton(
                size: 30,
                asset: IconAsset.shuffle,
                tooltip: 'Shuffle',
                onTap: () {
                  widget.playlist.shuffle();
                },
              ),
              AssetButton(
                size: 30,
                asset: widget.playlist.loop
                    ? IconAsset.loopEnabled
                    : IconAsset.loopDisabled,
                tooltip: !widget.playlist.loop
                    ? 'Enable looping'
                    : 'Disable looping',
                onTap: () => widget.playlist.loop = !widget.playlist.loop,
              ),
            ], const SizedBox(width: 10)),
            children: [
              for (final track in widget.playlist.tracks)
                CardTrack(
                  selected: widget.playlist.current == track,
                  leading: AlbumCover(album: track.belongsTo),
                  title: track.title,
                  artists: track.artists,
                  onTap: () {
                    widget.playlist.play(widget.playlist.tracks.indexOf(track));
                  },
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
                  vertical: constraints.maxHeight / 16,
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
  final Playlist playlist;
  final Function(Track track) onPlay;

  const LibraryRenderer({
    required this.playlist,
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
              //* Artist list
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
              //* Album list
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
            _selectedAlbum != null //* Album selected view
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
                                  widget.playlist.tracks =
                                      _selectedAlbum!.tracks;
                                  widget.playlist.play();
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
                                          widget.playlist
                                              .add(_selectedAlbum!.tracks);
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
                                    onTap: () => setState(() {
                                      widget.playlist.add([track]);
                                      widget.playlist.play(
                                        widget.playlist.tracks.length - 1,
                                      );
                                      _selectedAlbum = null;
                                    }),
                                  ))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  )
                : PlaylistRenderer(
                    //* Playlist view
                    playlist: widget.playlist,
                  ),
          ],
        );
      },
    );
  }
}
