import 'package:airpulse/data/repositories/library_repository_impl.dart';
import 'package:airpulse/data/sources/local/library_local_source.dart';
import 'package:airpulse/domain/entities/album.dart';
import 'package:airpulse/domain/entities/artist.dart';
import 'package:airpulse/domain/entities/playlist.dart';
import 'package:airpulse/domain/entities/song.dart';
import 'package:airpulse/presentation/providers/library_provider.dart';
import 'package:airpulse/presentation/providers/library_provider_optimized.dart';
import 'package:airpulse/presentation/controllers/library_controller.dart';
import 'package:airpulse/presentation/controllers/library_controller_optimized.dart';
import 'package:airpulse/services/library_service_optimized.dart';
import 'package:airpulse/services/library_service.dart';
import 'dart:async';
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

class ControlledLibraryService extends LibraryService {
  final List<Completer<List<Song>>> _responses = [];
  final List<(int, Completer<void>)> _fetchWaiters = [];
  int songFetchCount = 0;

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<List<Song>> getAllSongs() {
    songFetchCount++;
    final response = Completer<List<Song>>();
    _responses.add(response);
    for (final waiter in [..._fetchWaiters]) {
      if (songFetchCount >= waiter.$1) {
        waiter.$2.complete();
        _fetchWaiters.remove(waiter);
      }
    }
    return response.future;
  }

  @override
  Future<List<Album>> getAllAlbums([List<Song>? songs]) async => const [];

  @override
  Future<List<Artist>> getAllArtists([List<Song>? songs]) async => const [];

  @override
  Future<List<Playlist>> getAllPlaylists() async => const [];

  Future<void> waitForFetchCount(int count) {
    if (songFetchCount >= count) return Future.value();
    final completer = Completer<void>();
    _fetchWaiters.add((count, completer));
    return completer.future;
  }

  void completeFetch(int index, List<Song> songs) {
    _responses[index - 1].complete(songs);
  }

  void failFetch(int index, Object error) {
    _responses[index - 1].completeError(error);
  }
}

class ControlledOptimizedLibraryService implements LibraryServiceOptimized {
  final ControlledLibraryService _controlled = ControlledLibraryService();

  @override
  Future<bool> requestPermissions() => _controlled.requestPermissions();

  @override
  Future<List<Song>> getAllSongs({
    void Function(int current, int total)? onProgress,
  }) => _controlled.getAllSongs();

  @override
  Future<List<Album>> getAllAlbums([List<Song>? songs]) =>
      _controlled.getAllAlbums(songs);

  @override
  Future<List<Artist>> getAllArtists([List<Song>? songs]) =>
      _controlled.getAllArtists(songs);

  @override
  Future<List<Playlist>> getAllPlaylists() => _controlled.getAllPlaylists();

  int get songFetchCount => _controlled.songFetchCount;
  Future<void> waitForFetchCount(int count) =>
      _controlled.waitForFetchCount(count);
  void completeFetch(int index, List<Song> songs) =>
      _controlled.completeFetch(index, songs);
  void failFetch(int index, Object error) =>
      _controlled.failFetch(index, error);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Song makeSong(int index, {String? artist, String? album}) => Song(
  id: 'song-$index',
  title: 'Song $index',
  artist: artist ?? 'Artist ${index % 10}',
  album: album ?? 'Album ${index % 25}',
  filePath: '/music/$index.mp3',
  duration: Duration(seconds: index),
);

class RefreshHarness {
  final Future<void> Function() refresh;
  final bool Function() isLoading;
  final String? Function() error;
  final int Function() fetchCount;
  final Future<void> Function(int) waitForFetchCount;
  final void Function(int, List<Song>) completeFetch;
  final void Function(int, Object) failFetch;

  const RefreshHarness({
    required this.refresh,
    required this.isLoading,
    required this.error,
    required this.fetchCount,
    required this.waitForFetchCount,
    required this.completeFetch,
    required this.failFetch,
  });
}

List<RefreshHarness> createRefreshHarnesses() {
  final normalProviderService = ControlledLibraryService();
  final normalProvider = LibraryProvider(normalProviderService);

  final optimizedProviderService = ControlledLibraryService();
  final optimizedProvider = LibraryProviderOptimized(optimizedProviderService);

  final normalControllerService = ControlledLibraryService();
  final normalController = LibraryController(normalControllerService);

  final optimizedControllerService = ControlledOptimizedLibraryService();
  final optimizedController = LibraryControllerOptimized(
    optimizedControllerService,
  );

  return [
    RefreshHarness(
      refresh: normalProvider.loadLibrary,
      isLoading: () => normalProvider.isLoading,
      error: () => normalProvider.error,
      fetchCount: () => normalProviderService.songFetchCount,
      waitForFetchCount: normalProviderService.waitForFetchCount,
      completeFetch: normalProviderService.completeFetch,
      failFetch: normalProviderService.failFetch,
    ),
    RefreshHarness(
      refresh: optimizedProvider.loadLibrary,
      isLoading: () => optimizedProvider.isLoading,
      error: () => optimizedProvider.error,
      fetchCount: () => optimizedProviderService.songFetchCount,
      waitForFetchCount: optimizedProviderService.waitForFetchCount,
      completeFetch: optimizedProviderService.completeFetch,
      failFetch: optimizedProviderService.failFetch,
    ),
    RefreshHarness(
      refresh: normalController.refreshAll,
      isLoading: () => normalController.isLoading,
      error: () => normalController.error,
      fetchCount: () => normalControllerService.songFetchCount,
      waitForFetchCount: normalControllerService.waitForFetchCount,
      completeFetch: normalControllerService.completeFetch,
      failFetch: normalControllerService.failFetch,
    ),
    RefreshHarness(
      refresh: optimizedController.refreshAll,
      isLoading: () => optimizedController.isLoading,
      error: () => optimizedController.error,
      fetchCount: () => optimizedControllerService.songFetchCount,
      waitForFetchCount: optimizedControllerService.waitForFetchCount,
      completeFetch: optimizedControllerService.completeFetch,
      failFetch: optimizedControllerService.failFetch,
    ),
  ];
}

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

    expect(service.songFetchCount, 3);
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

  test(
    'normal refresh executes one load across providers and controllers',
    () async {
      for (final harness in createRefreshHarnesses()) {
        final first = harness.refresh();
        await harness.waitForFetchCount(1);
        expect(harness.isLoading(), isTrue);

        harness.completeFetch(1, [makeSong(1)]);
        await first;

        expect(harness.fetchCount(), 1);
        expect(harness.isLoading(), isFalse);
        expect(harness.error(), isNull);
      }
    },
  );

  test(
    'refresh during load adds one grouped second load across implementations',
    () async {
      for (final harness in createRefreshHarnesses()) {
        final first = harness.refresh();
        await harness.waitForFetchCount(1);

        final second = harness.refresh();
        harness.completeFetch(1, [makeSong(1)]);
        await harness.waitForFetchCount(2);
        expect(harness.fetchCount(), 2);

        harness.completeFetch(2, [makeSong(2)]);
        await Future.wait([first, second]);

        expect(harness.fetchCount(), 2);
        expect(harness.isLoading(), isFalse);
        expect(harness.error(), isNull);
      }
    },
  );

  test('multiple refresh requests are grouped into one extra load', () async {
    for (final harness in createRefreshHarnesses()) {
      final first = harness.refresh();
      await harness.waitForFetchCount(1);

      final refresh2 = harness.refresh();
      final refresh3 = harness.refresh();
      final refresh4 = harness.refresh();
      harness.completeFetch(1, [makeSong(1)]);
      await harness.waitForFetchCount(2);

      harness.completeFetch(2, [makeSong(2)]);
      await Future.wait([first, refresh2, refresh3, refresh4]);

      expect(harness.fetchCount(), 2);
      expect(harness.isLoading(), isFalse);
    }
  });

  test(
    'failed load does not block pending refresh across implementations',
    () async {
      for (final harness in createRefreshHarnesses()) {
        final first = harness.refresh();
        await harness.waitForFetchCount(1);
        final pending = harness.refresh();

        harness.failFetch(1, Exception('first load failed'));
        await harness.waitForFetchCount(2);
        harness.completeFetch(2, [makeSong(2)]);
        await Future.wait([first, pending]);

        expect(harness.fetchCount(), 2);
        expect(harness.isLoading(), isFalse);
      }
    },
  );

  test(
    'another load succeeds after a failed load leaves no blocked state',
    () async {
      for (final harness in createRefreshHarnesses()) {
        final failed = harness.refresh();
        await harness.waitForFetchCount(1);
        harness.failFetch(1, Exception('failed load'));
        await failed;

        expect(harness.fetchCount(), 1);
        expect(harness.isLoading(), isFalse);
        expect(harness.error(), isNotNull);

        final retry = harness.refresh();
        await harness.waitForFetchCount(2);
        harness.completeFetch(2, [makeSong(2)]);
        await retry;

        expect(harness.fetchCount(), 2);
        expect(harness.isLoading(), isFalse);
        expect(harness.error(), isNull);
      }
    },
  );

  test('playlist refresh remains independent from song retrieval', () async {
    final service = CountingLibraryService([makeSong(1)]);
    final provider = LibraryProvider(service);

    await provider.loadLibrary();

    expect(service.songFetchCount, 1);
    expect(provider.playlists, isEmpty);
  });

  test(
    'first and second loads failing preserve the final error across implementations',
    () async {
      for (final harness in createRefreshHarnesses()) {
        final first = harness.refresh();
        await harness.waitForFetchCount(1);
        final pending = harness.refresh();

        harness.failFetch(1, Exception('first failure'));
        await harness.waitForFetchCount(2);
        harness.failFetch(2, Exception('second failure'));
        await Future.wait([first, pending]);

        expect(harness.fetchCount(), 2);
        expect(harness.isLoading(), isFalse);
        expect(harness.error(), contains('second failure'));
      }
    },
  );

  test(
    'refresh during the second load starts a third load across implementations',
    () async {
      for (final harness in createRefreshHarnesses()) {
        final first = harness.refresh();
        await harness.waitForFetchCount(1);
        final second = harness.refresh();

        harness.completeFetch(1, [makeSong(1)]);
        await harness.waitForFetchCount(2);
        expect(harness.isLoading(), isTrue);

        final third = harness.refresh();
        harness.completeFetch(2, [makeSong(2)]);
        await harness.waitForFetchCount(3);
        harness.completeFetch(3, [makeSong(3)]);
        await Future.wait([first, second, third]);

        expect(harness.fetchCount(), 3);
        expect(harness.isLoading(), isFalse);
        expect(harness.error(), isNull);
      }
    },
  );

  test(
    'multiple refreshes during the second load remain grouped into a third load',
    () async {
      for (final harness in createRefreshHarnesses()) {
        final first = harness.refresh();
        await harness.waitForFetchCount(1);
        final pending = harness.refresh();
        harness.completeFetch(1, [makeSong(1)]);
        await harness.waitForFetchCount(2);

        final refreshA = harness.refresh();
        final refreshB = harness.refresh();
        final refreshC = harness.refresh();
        harness.completeFetch(2, [makeSong(2)]);
        await harness.waitForFetchCount(3);
        expect(harness.fetchCount(), 3);

        harness.completeFetch(3, [makeSong(3)]);
        await Future.wait([first, pending, refreshA, refreshB, refreshC]);

        expect(harness.fetchCount(), 3);
        expect(harness.isLoading(), isFalse);
      }
    },
  );

  test(
    'concurrent futures complete only after the final load result',
    () async {
      for (final harness in createRefreshHarnesses()) {
        final first = harness.refresh();
        await harness.waitForFetchCount(1);
        final concurrent = harness.refresh();

        harness.failFetch(1, Exception('initial failure'));
        await harness.waitForFetchCount(2);
        expect(harness.isLoading(), isTrue);

        harness.completeFetch(2, [makeSong(2)]);
        await Future.wait([first, concurrent]);

        expect(harness.isLoading(), isFalse);
        expect(harness.error(), isNull);
        expect(harness.fetchCount(), 2);
      }
    },
  );

  test(
    'dispose during active loads stops notifications and clears loading',
    () async {
      final providerService = ControlledLibraryService();
      final provider = LibraryProvider(providerService);
      var providerNotifications = 0;
      provider.addListener(() => providerNotifications++);

      final firstProvider = provider.loadLibrary();
      await providerService.waitForFetchCount(1);
      final notificationsBeforeDispose = providerNotifications;
      provider.dispose();
      providerService.completeFetch(1, [makeSong(1)]);
      await firstProvider;
      expect(provider.isLoading, isFalse);
      expect(providerNotifications, notificationsBeforeDispose);

      final controllerService = ControlledLibraryService();
      final controller = LibraryController(controllerService);
      var controllerNotifications = 0;
      controller.addListener(() => controllerNotifications++);

      final firstController = controller.refreshAll();
      await controllerService.waitForFetchCount(1);
      final controllerNotificationsBeforeDispose = controllerNotifications;
      controller.dispose();
      controllerService.completeFetch(1, [makeSong(1)]);
      await firstController;
      expect(controller.isLoading, isFalse);
      expect(controllerNotifications, controllerNotificationsBeforeDispose);

      final optimizedProviderService = ControlledLibraryService();
      final optimizedProvider = LibraryProviderOptimized(
        optimizedProviderService,
      );
      var optimizedProviderNotifications = 0;
      optimizedProvider.addListener(() => optimizedProviderNotifications++);

      final firstOptimizedProvider = optimizedProvider.loadLibrary();
      await optimizedProviderService.waitForFetchCount(1);
      final optimizedProviderBeforeDispose = optimizedProviderNotifications;
      optimizedProvider.dispose();
      optimizedProviderService.completeFetch(1, [makeSong(1)]);
      await firstOptimizedProvider;
      expect(optimizedProvider.isLoading, isFalse);
      expect(optimizedProviderNotifications, optimizedProviderBeforeDispose);

      final optimizedControllerService = ControlledOptimizedLibraryService();
      final optimizedController = LibraryControllerOptimized(
        optimizedControllerService,
      );
      var loadingNotifications = 0;
      optimizedController.addLoadingListener(() => loadingNotifications++);

      final firstOptimizedController = optimizedController.refreshAll();
      await optimizedControllerService.waitForFetchCount(1);
      final controllerBeforeDispose = loadingNotifications;
      optimizedController.dispose();
      optimizedControllerService.completeFetch(1, [makeSong(1)]);
      await firstOptimizedController;
      expect(optimizedController.isLoading, isFalse);
      expect(loadingNotifications, controllerBeforeDispose);
    },
  );
}
