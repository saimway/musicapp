import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'dart:developer';
import '../services/audio_handler.dart';

// Since WindowSize is not available, we use a constant for width
// or standard logic. Using -1 usually implies MATCH_PARENT in many plugins.
// However, to be safe, we will use default overlay behavior or a large integer
// if the plugin supports it, or rely on 'OverlayFlag.defaultFlag' which usually handles it.

class MusicController extends GetxController {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  late MyAudioHandler _audioHandler;

  var songs = <SongModel>[].obs;
  var filteredSongs = <SongModel>[].obs; // For the organizer

  var isPlaying = false.obs;
  var currentSongIndex = (-1).obs;
  var currentSongTitle = "".obs;
  var currentArtist = "".obs;
  var duration = Duration.zero.obs;
  var position = Duration.zero.obs;

  var filterType = "All Songs".obs; // Organizer State

  @override
  void onInit() {
    super.onInit();
    _initAudioService();
    checkPermissions();
  }

  Future<void> _initAudioService() async {
    _audioHandler = await AudioService.init(
      builder: () => MyAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.island_vibes.channel.audio',
        androidNotificationChannelName: 'Island Vibes Music',
        androidNotificationOngoing: true,
      ),
    );

    // Listen to playback state
    _audioHandler.playbackState.listen((state) {
      isPlaying.value = state.playing;
      updateOverlay();
    });

    // Listen to media item changes
    _audioHandler.mediaItem.listen((item) {
      if (item != null) {
        currentSongTitle.value = item.title;
        currentArtist.value = item.artist ?? "Unknown";
        updateOverlay();
      }
    });

    // Listen to position updates (simplistic)
    AudioService.position.listen((p) {
      position.value = p;
    });
  }

  Future<void> checkPermissions() async {
    var storageStatus = await Permission.storage.request();
    var audioStatus = await Permission.audio.request();

    if (storageStatus.isGranted || audioStatus.isGranted) {
      fetchSongs();
    }

    bool status = await FlutterOverlayWindow.isPermissionGranted();
    if (!status) {
      await FlutterOverlayWindow.requestPermission();
    }
  }

  Future<void> fetchSongs() async {
    try {
      List<SongModel> fetchedSongs = await _audioQuery.querySongs(
        sortType: SongSortType.DATE_ADDED,
        orderType: OrderType.DESC_OR_GREATER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      var validSongs = fetchedSongs.where((song) => song.duration != null && song.duration! > 10000).toList();
      songs.value = validSongs;
      filterSongs("All Songs"); // Initial filter

    } catch (e) {
      log("Error fetching songs: $e");
    }
  }

  void filterSongs(String type) {
    filterType.value = type;
    if (type == "All Songs") {
      filteredSongs.value = songs;
    } else if (type == "Artists") {
      // Logic to show unique artists - for simplicity in this UI, we just sort by artist
      filteredSongs.value = List.from(songs)..sort((a, b) => (a.artist ?? "").compareTo(b.artist ?? ""));
    } else if (type == "Albums") {
       filteredSongs.value = List.from(songs)..sort((a, b) => (a.album ?? "").compareTo(b.album ?? ""));
    } else {
      filteredSongs.value = songs;
    }
  }

  Future<void> playSong(int index) async {
    try {
      currentSongIndex.value = index;
      var song = filteredSongs[index]; // Use filtered list

      // Create MediaItems for the playlist
      List<MediaItem> mediaItems = filteredSongs.map((s) => MediaItem(
        id: s.uri!,
        album: s.album,
        title: s.title,
        artist: s.artist,
        duration: Duration(milliseconds: s.duration ?? 0),
      )).toList();

      await _audioHandler.setPlaylist(mediaItems, index);
      await _audioHandler.play();

      showOverlay();
    } catch (e) {
      log("Error playing song: $e");
    }
  }

  Future<void> togglePlay() async {
    if (isPlaying.value) {
      await _audioHandler.pause();
    } else {
      await _audioHandler.play();
    }
  }

  Future<void> playNext() async => _audioHandler.skipToNext();
  Future<void> playPrevious() async => _audioHandler.skipToPrevious();

  void seek(Duration pos) {
    _audioHandler.seek(pos);
  }

  // --- Overlay Logic ---

  Future<void> showOverlay() async {
    if (await FlutterOverlayWindow.isActive()) return;

    // Removing WindowSize.matchParent as it was causing issues.
    // width: -1 is often standard for MATCH_PARENT in android plugins
    // or we can omit it to let the flag handle it.
    await FlutterOverlayWindow.showOverlay(
      enableDrag: true,
      overlayTitle: "Dynamic Island",
      overlayContent: 'Island Vibes Playing',
      flag: OverlayFlag.defaultFlag, // defaultFlag usually makes it non-focusable but visible
      visibility: NotificationVisibility.visibilitySecret,
      positionGravity: PositionGravity.top,
      height: 140,
      width: -1, // -1 is commonly MATCH_PARENT in JNI/Android channels
      startPosition: const OverlayPosition(0, 0),
    );

    updateOverlay();
  }

  void updateOverlay() {
    FlutterOverlayWindow.shareData({
      'title': currentSongTitle.value,
      'artist': currentArtist.value,
      'isPlaying': isPlaying.value,
    });
  }
}
