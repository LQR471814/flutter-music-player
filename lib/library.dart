import 'dart:io';

import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:path/path.dart';

class Track {
  final Metadata metadata;
  final String path;

  const Track({
    required this.metadata,
    required this.path,
  });

  static Future<Track> fromFile(File file) async {
    final metadata = await MetadataRetriever.fromFile(file);
    return Track(path: file.path, metadata: metadata);
  }
}

class Album {
  final String title;
  final List<Track> tracks;
  final String? author;
  final File? cover;

  Album({
    required this.title,
    required this.tracks,
    this.author,
    this.cover,
  });
}

class Library {
  final Directory root;
  final List<Album> albums = [];

  Library(this.root) {
    root.watch().listen((event) => _load());
  }

  Future<void> _load() async {
    albums.clear();
    final items = await root.list().toList();
    for (final entity in items) {
      if (entity is File) {
        final track = await Track.fromFile(entity);

        final title = track.metadata.albumName ?? '';
        final author = track.metadata.albumArtistName ?? '';

        albums.add(Album(
          title: title.isNotEmpty ? title : basename(entity.path),
          author: author.isNotEmpty ? author : null,
          tracks: [track],
        ));
      } else if (entity is Directory) {
        final cover = File(join(entity.path, 'cover.png'));
        final tracks = [
          for (final file in await entity.list().toList())
            if (file is File) await Track.fromFile(file),
        ];

        final title = tracks.first.metadata.albumName ?? '';
        final author = tracks.first.metadata.albumArtistName ?? '';

        albums.add(Album(
          title: title.isNotEmpty ? title : basename(entity.path),
          author: author.isNotEmpty ? author : null,
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
