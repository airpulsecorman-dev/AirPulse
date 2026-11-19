import 'package:airpulse/domain/entities/song.dart';
import 'package:airpulse/services/audio_handler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Android Auto song media items', () {
    test('use hierarchical IDs encoded by song ID', () {
      expect(
        AirPulseAudioHandler.androidAutoSongMediaId('media/123'),
        'song/media%2F123',
      );
    });

    test('preserve duplicate titles and distinct stable IDs', () async {
      const first = Song(
        id: '1',
        title: 'Repeat',
        artist: 'Artist',
        album: 'Album',
        filePath: '/music/1.mp3',
        duration: Duration(minutes: 3),
      );
      const second = Song(
        id: '2',
        title: 'Repeat',
        artist: 'Artist',
        album: 'Album',
        filePath: '/music/2.mp4',
        duration: Duration(minutes: 4),
      );

      final firstItem = await AirPulseAudioHandler.songToMediaItem(first);
      final secondItem = await AirPulseAudioHandler.songToMediaItem(second);

      expect(firstItem.id, 'song/1');
      expect(secondItem.id, 'song/2');
      expect(firstItem.id, isNot(secondItem.id));
      expect(firstItem.title, secondItem.title);
    });

    test('include file and song IDs needed for resolution', () async {
      const song = Song(
        id: 'track-42',
        title: 'Song',
        artist: 'Artist',
        album: 'Album',
        filePath: '/music/song.mp3',
        duration: Duration(minutes: 2, seconds: 30),
      );

      final item = await AirPulseAudioHandler.songToMediaItem(song);

      expect(item.extras?['filePath'], '/music/song.mp3');
      expect(item.extras?['songId'], 'track-42');
      expect(item.extras?['type'], 'song');
      expect(item.duration, const Duration(minutes: 2, seconds: 30));
    });
  });
}
