import 'dart:io';
import 'dart:math';

import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:music_player/common/utils.dart';
import 'package:path/path.dart';

class Playlist {
  final List<Track> tracks;
  final bool loop;
  final int current;

  const Playlist({
    required this.tracks,
    this.current = 0,
    this.loop = false,
  });

  Playlist queue(List<Track> tracks) => Playlist(
        tracks: tracks..addAll(tracks),
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
    return Playlist(tracks: tracks, loop: loop, current: current);
  }
}

class Track {
  final Metadata metadata;
  final String path;

  final String title;
  final List<String> artists;

  const Track({
    required this.metadata,
    required this.path,
    required this.title,
    this.artists = const [],
  });

  static Future<Track?> fromEntry(FileSystemEntity file) async {
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

    return Track(
      path: file.path,
      metadata: metadata,
      title: title,
      artists: stripList(metadata.trackArtistNames ?? []).isNotEmpty
          ? metadata.trackArtistNames!
          : [],
    );
  }
}

class Album {
  final String title;
  final List<Track> tracks;
  final List<String> artists;
  final File? cover;

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

        final title = track.metadata.albumName ?? '';
        final artists = track.metadata.albumArtistName ?? '';

        final name = title.isNotEmpty ? title : getAudioFilename(entity);
        if (name == null) {
          continue;
        }

        albums.add(Album(
          title: name,
          artists: artists.isNotEmpty ? [artists] : [],
          tracks: [track],
        ));
      } else if (entity is Directory) {
        final cover = File(join(entity.path, 'cover.png'));

        final List<Track> tracks = [];
        for (final file in await entity.list().toList()) {
          final track = await Track.fromEntry(file);
          if (track != null) {
            tracks.add(track);
          }
        }

        if (tracks.isEmpty) {
          continue;
        }

        var title = '';
        final List<String> artists = [];
        for (var t in tracks) {
          if (t.metadata.albumArtistName != null &&
              strip(t.metadata.albumArtistName!).isNotEmpty) {
            artists.add(t.metadata.albumArtistName!);
          }
          if (t.metadata.albumName != null) {
            title = t.metadata.albumName!;
            break;
          }
        }

        albums.add(Album(
          title: title.isNotEmpty ? title : basename(entity.path),
          artists: artists,
          cover: await cover.exists() ? cover : null,
          tracks: tracks,
        ));
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
