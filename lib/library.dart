import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:music_player/common/utils.dart';
import 'package:path/path.dart';

class Playlist {
  final List<Track> tracks;
  final bool loop;
  final int current;

  const Playlist({
    required this.tracks,
    this.current = -1,
    this.loop = false,
  });

  Playlist clear() {
    if (current < 0) {
      return Playlist(tracks: [], loop: loop);
    }
    return Playlist(
      tracks: [tracks[current]],
      loop: loop,
      current: 0,
    );
  }

  Playlist withTracks(List<Track> newTracks) => Playlist(
        tracks: newTracks,
        loop: loop,
        current: current,
      );

  Playlist queue(List<Track> newTracks) => Playlist(
        tracks: tracks..addAll(newTracks),
        loop: loop,
        current: current,
      );

  Playlist at(int track) =>
      Playlist(tracks: tracks, loop: loop, current: track);

  Playlist looped(bool newLoop) =>
      Playlist(tracks: tracks, loop: newLoop, current: current);

  Playlist shuffle() {
    final List<Track> newTracks = [];
    final _random = Random();
    while (tracks.isNotEmpty) {
      final index = _random.nextInt(tracks.length);
      newTracks.add(tracks[index]);
      tracks.removeAt(index);
    }
    return Playlist(tracks: newTracks, loop: loop, current: current);
  }
}

class Track {
  final Album belongsTo;

  final Metadata metadata;
  final String path;

  final String title;
  final List<String> artists;

  const Track({
    required this.belongsTo,
    required this.metadata,
    required this.path,
    required this.title,
    this.artists = const [],
  });

  static Future<Track?> fromEntry(FileSystemEntity file,
      [Album? belongsTo]) async {
    if (file is! File) {
      return null;
    }

    final filename = getAudioFilename(file);
    if (filename == null) {
      return null;
    }

    final metadata = await MetadataRetriever.fromFile(file);
    final title = strip(metadata.trackName ?? '').isEmpty
        ? filename
        : metadata.trackName!;

    final List<String> artists =
        stripList(metadata.trackArtistNames ?? []).isNotEmpty
            ? metadata.trackArtistNames!
            : [];

    if (belongsTo != null) {
      return Track(
        belongsTo: belongsTo,
        path: file.path,
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
      path: file.path,
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
  final Directory root;
  final List<Album> albums = [];

  Library(this.root) {
    root.watch().listen((event) => _load());
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
    final items = await root.list().toList();
    for (final entity in items) {
      if (entity is File) {
        final track = await Track.fromEntry(entity);
        if (track == null) {
          continue;
        }
        albums.add(track.belongsTo);
      } else if (entity is Directory) {
        final album = Album(title: '', tracks: []);

        for (final file in await entity.list().toList()) {
          final track = await Track.fromEntry(file, album);
          if (track != null) {
            album.tracks.add(track);
          }
        }

        if (album.tracks.isEmpty) {
          continue;
        }

        Uint8List? albumArt;
        String title = basename(entity.path);
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

        final cover = File(join(entity.path, 'cover.png'));
        if (await cover.exists()) {
          album.cover = await cover.readAsBytes();
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
