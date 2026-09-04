import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class RadioAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  static const String streamUrl =
      'https://radyoserver1.okeylisans.com:8060/stream.mp3';

  RadioAudioHandler() {
    _player.playbackEventStream.listen(_broadcastState);

    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        stop();
      }

      _broadcastCurrentState();
    });

    _setInitialMediaItem();
  }

  // ============================================================
  // SES
  // ============================================================

  double get volume => _player.volume;

  Future<void> setVolume(double value) async {
    final safeValue = value.clamp(0.0, 1.0);

    await _player.setVolume(safeValue);

    _broadcastCurrentState();
  }

  // ============================================================
  // BAŞLANGIÇ MEDIA ITEM
  // ============================================================

  void _setInitialMediaItem() {
    final item = MediaItem(
      id: streamUrl,
      album: 'RADYO HAYAL',
      title: 'RADYO HAYAL',
      artist: 'Hayallerin Ötesinde',
      displayTitle: 'RADYO HAYAL',
      displaySubtitle: 'Hayallerin Ötesinde',
      playable: true,
      genre: 'Türkçe Radyo',
    );

    mediaItem.add(item);
    queue.add([item]);
  }

  // ============================================================
  // ŞARKI BİLGİLERİNİ GÜNCELLE
  // ============================================================

  void updateSong({
    required String title,
    required String artist,
    String? imageUrl,
  }) {
    final cleanTitle =
        title.trim().isEmpty ? 'RADYO HAYAL' : title.trim();

    final cleanArtist =
        artist.trim().isEmpty
            ? 'Hayallerin Ötesinde'
            : artist.trim();

    Uri? artwork;

    if (imageUrl != null &&
        imageUrl.trim().isNotEmpty &&
        imageUrl.startsWith('http')) {
      artwork = Uri.tryParse(imageUrl.trim());
    }

    final item = MediaItem(
      id: streamUrl,
      album: 'RADYO HAYAL',
      title: cleanTitle,
      artist: cleanArtist,
      displayTitle: cleanTitle,
      displaySubtitle: cleanArtist,
      artUri: artwork,
      playable: true,
      genre: 'RADYO HAYAL • Canlı Yayın',
    );

    mediaItem.add(item);
    queue.add([item]);

    _broadcastCurrentState();
  }

  // ============================================================
  // MEDIA SESSION DURUMU
  // ============================================================

  void _broadcastCurrentState() {
    _broadcastState(_player.playbackEvent);
  }

  void _broadcastState(PlaybackEvent event) {
    final processingState = {
      ProcessingState.idle:
          AudioProcessingState.idle,
      ProcessingState.loading:
          AudioProcessingState.loading,
      ProcessingState.buffering:
          AudioProcessingState.buffering,
      ProcessingState.ready:
          AudioProcessingState.ready,
      ProcessingState.completed:
          AudioProcessingState.completed,
    }[_player.processingState]!;

    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          if (_player.playing)
            MediaControl.pause
          else
            MediaControl.play,
        ],
        systemActions: const {
          MediaAction.play,
          MediaAction.pause,
        },
        androidCompactActionIndices: const [0],
        playing: _player.playing,
        processingState: processingState,
        updatePosition: event.updatePosition,
        bufferedPosition: event.bufferedPosition,
        speed: _player.speed,
        queueIndex: 0,
      ),
    );
  }

  // ============================================================
  // PLAY
  // ============================================================

  @override
  Future<void> play() async {
    try {
      if (_player.processingState == ProcessingState.idle) {
        await _player.setAudioSource(
          AudioSource.uri(
            Uri.parse(streamUrl),
          ),
        );
      }

      await _player.play();

      _broadcastCurrentState();
    } catch (e) {
      playbackState.add(
        playbackState.value.copyWith(
          playing: false,
          processingState: AudioProcessingState.error,
          errorMessage: e.toString(),
        ),
      );

      rethrow;
    }
  }

  // ============================================================
  // PAUSE
  // ============================================================

  @override
  Future<void> pause() async {
    await _player.pause();

    _broadcastCurrentState();
  }

  // ============================================================
  // STOP
  // ============================================================

  @override
  Future<void> stop() async {
    await _player.stop();

    playbackState.add(
      playbackState.value.copyWith(
        controls: const [
          MediaControl.play,
        ],
        systemActions: const {
          MediaAction.play,
        },
        playing: false,
        processingState: AudioProcessingState.idle,
      ),
    );

    await super.stop();
  }

  // ============================================================
  // SEEK
  // ============================================================

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  // ============================================================
  // SPEED
  // ============================================================

  @override
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);

    _broadcastCurrentState();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  Future<void> disposeHandler() async {
    await _player.dispose();
  }
}