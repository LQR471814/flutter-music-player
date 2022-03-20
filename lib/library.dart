import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_player/common/utils.dart';
import 'package:music_player/interface.dart';
import 'package:path/path.dart';

class Playlist {
  final AudioPlayer player;
  List<Track> _tracks;
  int _playing;
  bool _loop;

  Playlist({
    required this.player,
    List<Track> tracks = const [],
    bool loop = false,
  })  : _tracks = tracks,
        _playing = -1,
        _loop = loop;

  bool get loop => _loop;
  set loop(l) => _loop = l;

  int get playing => _playing;
  set playing(i) => _playing = i;

  List<Track> get tracks => _tracks;
  set tracks(t) {
    _tracks = t;
  }

  void clear() {
    if (playing < 0 || playing >= tracks.length) {
      tracks = <Track>[];
      return;
    }
    tracks = [tracks[playing]];
    playing = 0;
  }

  void queue(List<Track> append) => tracks = _tracks + append;

  void shuffle() {
    final List<Track> newTracks = [];
    final _random = Random();
    while (_tracks.isNotEmpty) {
      final index = _random.nextInt(_tracks.length);
      newTracks.add(tracks[index]);
      _tracks.removeAt(index);
    }
    tracks = newTracks;
  }
}

class Track {
  final Album belongsTo;

  final Metadata metadata;

  final String title;
  final List<String> artists;

  const Track({
    required this.belongsTo,
    required this.metadata,
    required this.title,
    this.artists = const [],
  });

  static Future<Track> fromEntry(DataStoreAudio audio,
      [Album? belongsTo]) async {
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
