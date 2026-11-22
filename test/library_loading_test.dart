import 'package:airpulse/data/repositories/library_repository_impl.dart';
import 'package:airpulse/data/sources/local/library_local_source.dart';
import 'package:airpulse/domain/entities/album.dart';
import 'package:airpulse/domain/entities/artist.dart';
import 'package:airpulse/domain/entities/playlist.dart';
import 'package:airpulse/domain/entities/song.dart';
import 'package:airpulse/presentation/providers/library_provider.dart';
import 'package:airpulse/services/library_service.dart';
import 'package:flutter_test/flutter_test.dart';

class CountingLocalSource extends LibraryLocalSource {
  final List<Song> songs;
  int fetchCount = 0;

  CountingLocalSource(this.songs);

  @override
  Future<List<Song>> fetchSongs() async {
    fetchCount++;
    return songs;
  }
}

class CountingLibraryService extends LibraryService {
  final List<Song> songs;
  final bool permissionGranted;
  int songFetchCount = 0;
  int albumBuildCount = 0;
  int artistBuildCount = 0;
  List<Song>? albumsInput;
  List<Song>? artistsInput;

  CountingLibraryService(this.songs, {this.permissionGranted = true});

  @override
  Future<bool> requestPermissions() async => permissionGranted;

  @override
  Future<List<Song>> getAllSongs() async {
    songFetchCount++;
    return songs;
  }

  @override
  Future<List<Album>> getAllAlbums([List<Song>? songs]) async {
    albumBuildCount++;
    albumsInput = songs;
    if (songs == null) return [];
    final map = <String, List<Song>>{};
    for (final song in songs) {
      map.putIfAbsent(song.album, () => []).add(song);
    }
    return map.entries
        .map(
          (entry) => Album(
            id: entry.key,
            title: entry.key,
            artist: entry.value.first.artist,
            songs: entry.value,
          ),
        )
        .toList();
  }

  @override
  Future<List<Artist>> getAllArtists([List<Song>? songs]) async {
    artistBuildCount++;
    artistsInput = songs;
    if (songs == null) return [];
    final map = <String, List<Song>>{};
    for (final song in songs) {
      map.putIfAbsent(song.artist, () => []).add(song);
    }
    return map.entries
        .map(
          (entry) => Artist(id: entry.key, name: entry.key, songs: entry.value),
        )
        .toList();
  }

  @override
  Future<List<Playlist>> getAllPlaylists() async => const [];
}

Song makeSong(int index, {String? artist, String? album}) => Song(
  id: 'song-$index',
  title: 'Song $index',
  artist: artist ?? 'Artist ${index % 10}',
  album: album ?? 'Album ${index % 25}',
  filePath: '/music/$index.mp3',
  duration: Duration(seconds: index),
);

void main() {
  test('normal load retrieves complete songs once and reuses them', () async {
    for (final count in [0, 1000, 5000]) {
      final songs = List.generate(count, makeSong);
      final service = CountingLibraryService(songs);
      final provider = LibraryProvider(service);

      await provider.loadLibrary();

      expect(service.songFetchCount, 1);
      expect(service.albumsInput, same(songs));
      expect(service.artistsInput, same(songs));
      expect(provider.songs.length, count);
    }
  });

  test('refresh and concurrent loads do not duplicate retrieval', () async {
    final service = CountingLibraryService(List.generate(100, makeSong));
    final provider = LibraryProvider(service);

    await Future.wait([provider.loadLibrary(), provider.loadLibrary()]);
    await provider.loadLibrary();

    expect(service.songFetchCount, 2);
  });

  test('denied permissions preserve normal load behavior', () async {
    final service = CountingLibraryService([
      makeSong(1),
    ], permissionGranted: false);
    final provider = LibraryProvider(service);

    await provider.loadLibrary();

    expect(service.songFetchCount, 1);
    expect(provider.songs, hasLength(1));
  });

  test(
    'repository builds empty, missing metadata, multi artist and duplicates',
    () async {
      final songs = <Song>[
        makeSong(1, artist: '', album: ''),
        makeSong(2, artist: 'Artist A', album: 'Shared Album'),
        makeSong(3, artist: 'Artist B', album: 'Shared Album'),
        makeSong(4, artist: 'Artist A', album: 'Shared Album'),
        makeSong(2, artist: 'Artist A', album: 'Shared Album'),
      ];
      final source = CountingLocalSource(songs);
      final repository = LibraryRepositoryImpl(source);

      final fetched = await repository.getAllSongs();
      final albums = await repository.getAllAlbums(fetched);
      final artists = await repository.getAllArtists(fetched);

      expect(source.fetchCount, 1);
      expect(
        albums.singleWhere((album) => album.title == 'Shared Album').artist,
        'Artist A',
      );
      expect(
        albums.singleWhere((album) => album.title == 'Shared Album').songs,
        hasLength(4),
      );
      expect(
        artists.where((artist) => artist.name == 'Artist A').single.songs,
        hasLength(3),
      );
      expect(artists.any((artist) => artist.name.isEmpty), isTrue);
    },
  );

  test('playlist refresh remains independent from song retrieval', () async {
    final service = CountingLibraryService([makeSong(1)]);
    final provider = LibraryProvider(service);

    await provider.loadLibrary();

    expect(service.songFetchCount, 1);
    expect(provider.playlists, isEmpty);
  });
}
