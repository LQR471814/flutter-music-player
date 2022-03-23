import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:stack_trace/stack_trace.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:music_player/common/utils.dart';
import 'package:music_player/interface.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

//? SafePlayer is an AudioPlayer that can be mutated freely
//? it is also designed so you can call mutate() inside the
//? mutate callback safely
class SafePlayer {
  final AudioPlayer player;
  int _locks = 0;

  SafePlayer(this.player);

  void mutate(void Function() callback) {
    if (_locks == 0) {
      player.pause();
      _locks++;
    }
    callback();
    _locks--;
    if (_locks == 0) {
      player.play();
    }
  }
}

class Playlist {
  final StreamController<void> _updateController =
      StreamController<void>.broadcast();
  final SafePlayer safePlayer;
  get player => safePlayer.player;

  List<Track> _tracks;
  int _current;
  bool _loop;

  Playlist({
    required AudioPlayer player,
    List<Track> tracks = const [],
    bool loop = false,
  })  : safePlayer = SafePlayer(player),
        _tracks = tracks,
        _current = -1,
        _loop = loop {
    player
        .createPositionStream(
      minPeriod: const Duration(milliseconds: 500),
      maxPeriod: const Duration(milliseconds: 500),
    )
        .listen((event) {
      if (player.duration == null || !player.playing) {
        return;
      }
      if (event >= player.duration!) {
        final hasNext = next();
        if (!hasNext && _loop) {
          safePlayer.mutate(() {
            _current = 0;
            _updateSource();
          });
          player.durationFuture?.then((value) => _updateController.add(null));
        } else if (!hasNext && !_loop) {
          _current = 0;
          player.pause();
          _updateSource();
          _updateController.add(null);
        }
      }
    });
  }

  List<Track> get tracks => _tracks;
  set tracks(t) => _tracks = List.from(t);

  Stream<void> get onUpdate => _updateController.stream;

  Track? get current =>
      _current >= 0 && _current < _tracks.length ? _tracks[_current] : null;

  bool get loop => _loop;
  set loop(l) {
    _loop = l;
    _updateController.add(null);
  }

  void _updateSource() {
    player.setAudioSource(_tracks[_current].audio);
  }

  void play([int start = 0]) {
    if (_tracks.isEmpty) {
      return;
    }
    _current = start;

    safePlayer.mutate(() {
      _updateSource();
    });

    _updateController.add(null);
  }

  void pause() => player.pause();

  bool hasPrevious() => _current - 1 >= 0 && _current < _tracks.length;

  bool previous() {
    if (hasPrevious()) {
      safePlayer.mutate(() {
        _current--;
        _updateSource();
      });
      _updateController.add(null);
      return true;
    }
    return false;
  }

  bool hasNext() => _current + 1 < _tracks.length && _current >= 0;

  bool next() {
    if (hasNext()) {
      safePlayer.mutate(() {
        _current++;
        _updateSource();
      });
      _updateController.add(null);
      return true;
    }
    return false;
  }

  void clear() {
    if (_tracks.isEmpty) {
      return;
    }
    if (!player.playing) {
      _tracks = <Track>[];
      _current = -1;
      _updateController.add(null);
      return;
    }
    _tracks = [_tracks[_current]];
    _current = 0;
    _updateController.add(null);
  }

  void add(List<Track> append) {
    _tracks = _tracks + append;
    _updateController.add(null);
  }

  void shuffle() {
    final Track? playedTrack = current != null ? _tracks[_current] : null;

    final List<Track> newTracks = [];
    final _random = Random();
    while (_tracks.isNotEmpty) {
      final index = _random.nextInt(_tracks.length);
      newTracks.add(_tracks[index]);
      _tracks.removeAt(index);
    }
    _tracks = newTracks;

    if (playedTrack != null) {
      _current = _tracks.indexOf(playedTrack);
    }

    _updateController.add(null);
  }
}

class Track {
  final Album belongsTo;
  final DataStoreAudio data;

  final Metadata metadata;
  final String title;
  final List<String> artists;

  final AudioSource audio;

  Track({
    required this.belongsTo,
    required this.data,
    required this.metadata,
    required this.title,
    this.artists = const [],
  }) : audio = ProgressiveAudioSource(
          data.uri,
          tag: MediaItem(
            id: const Uuid().v4(),
            title: title,
            artist: artists.join(', '),
            genre: metadata.genre,
            album: belongsTo.title,
            artUri: belongsTo.cover != null
                ? Uri.dataFromBytes(belongsTo.cover!)
                : null,
          ),
        );

  static Future<Track> fromEntry(
    DataStoreAudio audio, [
    Album? belongsTo,
  ]) async {
    final metadata = await audio.metadata();
    final title = strip(metadata.trackName ?? '').isEmpty
        ? audio.name
        : metadata.trackName!;

    final List<String> artists =
        stripList(metadata.trackArtistNames ?? []).isNotEmpty
            ? metadata.trackArtistNames!
            : [];

    if (belongsTo != null) {
      return Track(
        belongsTo: belongsTo,
        metadata: metadata,
        title: title,
        artists: artists,
        data: audio,
      );
    }

    final defaultAlbum = Album(
      title: title,
      artists: artists,
      tracks: [],
      cover: metadata.albumArt,
    );
    final result = Track(
      belongsTo: defaultAlbum,
      metadata: metadata,
      title: title,
      artists: artists,
      data: audio,
    );
    defaultAlbum.tracks.add(result);
    return result;
  }
}

class Album {
  String title;
  List<Track> tracks;
  List<String> artists;
  Uint8List? cover;

  Album({
    required this.title,
    required this.tracks,
    this.artists = const [],
    this.cover,
  });
}

class Library {
  final DataStore store;
  final List<Album> albums = [];

  Library(Directory root) : store = LocalStore(root) {
    store.watch().listen((event) => _load());
  }

  Set<String> get artists {
    final Set<String> artists = {};
    for (final a in albums) {
      Set<String> albumArtists = Set.from(a.artists);
      if (albumArtists.isEmpty) {
        for (Track t in a.tracks) {
          albumArtists.addAll(t.artists);
        }
      }
      artists.addAll(albumArtists);
    }
    return artists;
  }

  List<Album> filterByArtist(List<Album> albums, String name) {
    final List<Album> result = [];
    for (final a in albums) {
      if (a.artists.contains(name)) {
        result.add(a);
        continue;
      }
      for (final track in a.tracks) {
        if (track.artists.contains(name)) {
          result.add(a);
          break;
        }
      }
    }
    return result;
  }

  Future<void> _load() async {
    albums.clear();
    final items = await store.entries();
    for (final entry in items) {
      if (entry is DataStoreAudio) {
        final track = await Track.fromEntry(entry);
        albums.add(track.belongsTo);
      } else if (entry is DataStoreFolder) {
        final album = Album(title: '', tracks: []);

        for (final entry in await entry.children()) {
          if (entry is DataStoreAudio) {
            final track = await Track.fromEntry(entry, album);
            album.tracks.add(track);
          }
        }

        if (album.tracks.isEmpty) {
          continue;
        }

        Uint8List? albumArt;
        String title = entry.name;
        final List<String> artists = [];
        for (var t in album.tracks) {
          if (t.metadata.albumArt != null && albumArt == null) {
            albumArt = t.metadata.albumArt;
          }
          if (t.metadata.albumArtistName != null &&
              strip(t.metadata.albumArtistName!).isNotEmpty) {
            artists.add(t.metadata.albumArtistName!);
          }
          if (t.metadata.albumName != null &&
              t.metadata.albumName!.isNotEmpty) {
            title = t.metadata.albumName!;
            break;
          }
        }

        album.title = title;
        album.artists = artists;

        final cover = await entry.cover();
        if (cover != null) {
          album.cover = cover;
        } else if (albumArt != null) {
          album.cover = albumArt;
        }

        albums.add(album);
      }
    }
  }

  static Future<Library> load(Directory root) async {
    final library = Library(root);
    await library._load();
    return library;
  }
}

String? getAudioFilename(File file) {
  final nameParts = basename(file.path).split('.');
  if (nameParts.length > 1) {
    if (nameParts.last != 'mp3' && nameParts.last != 'wav') {
      return null;
    }
    nameParts.remove(nameParts.last);
    return nameParts.join('.');
  }
  return null;
}
