import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';

const List<String> supportedAudio = ["mp3", "wav"];
const List<String> supportedImages = [
  "jpeg",
  "jpg",
  "png",
  "gif",
  "webp",
  "bmp",
];

//* Definitions
abstract class DataStoreEntry {
  late final String name;
}

abstract class DataStoreFolder implements DataStoreEntry {
  @override
  late final String name;
  Future<List<DataStoreEntry>> children();
  Future<Uint8List?> cover();
}

abstract class DataStoreAudio implements DataStoreEntry {
  @override
  late final String name;
  late final String fileExtension;

  Future<Metadata> metadata();
  Future<Uint8List> audio();
}

abstract class DataStore {
  Future<List<DataStoreEntry>> entries();
  Stream<void> watch();
}

//* Local implementation
List<String> getSplitName(File file) {
  final nameParts = basename(file.path).split('.');
  final ext = nameParts.last;
  return [(nameParts..removeLast()).join("."), ext];
}

class LocalFolder implements DataStoreFolder {
  @override
  late final String name;

  final Directory directory;

  LocalFolder(this.directory) : name = basename(directory.path);

  @override
  Future<List<DataStoreEntry>> children() async {
    List<DataStoreEntry> entries = [];
    for (FileSystemEntity entity in await directory.list().toList()) {
      if (entity is Directory) {
        entries.add(LocalFolder(entity));
      } else if (entity is File) {
        final ext = getSplitName(entity)[1];
        if (supportedAudio.contains(ext)) {
          entries.add(LocalAudio.fromFile(entity));
        }
      }
    }
    return entries;
  }

  @override
  Future<Uint8List?> cover() async {
    for (final ext in supportedImages) {
      File f = File("cover.$ext");
      if (await f.exists()) {
        return f.readAsBytes();
      }
    }
    return null;
  }

  @override
  String toString() => "Folder - $name Path - ${directory.path}";
}

class LocalAudio implements DataStoreAudio {
  @override
  late final String name;
  @override
  late final String fileExtension;

  final File file;

  LocalAudio({
    required this.name,
    required this.fileExtension,
    required this.file,
  });

  LocalAudio.fromFile(this.file) {
    final split = getSplitName(file);
    name = split[0];
    fileExtension = split[1];
  }

  @override
  Future<Uint8List> audio() => file.readAsBytes();

  @override
  Future<Metadata> metadata() => MetadataRetriever.fromFile(file);

  @override
  String toString() => "Audio - $name.$fileExtension";
}

class LocalStore implements DataStore {
  final LocalFolder root;

  LocalStore(Directory rootDir) : root = LocalFolder(rootDir);

  @override
  Future<List<DataStoreEntry>> entries() => root.children();

  @override
  Stream<void> watch() => root.directory.watch();
}
