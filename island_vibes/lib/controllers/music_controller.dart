import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'dart:developer';
import '../services/audio_handler.dart';

class MusicController extends GetxController {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  MyAudioHandler? _audioHandler;

  var songs = <SongModel>[].obs;
  var filteredSongs = <SongModel>[].obs;

  var isPlaying = false.obs;
  var currentSongIndex = (-1).obs;
  var currentSongTitle = "".obs;
  var currentArtist = "".obs;
  var duration = Duration.zero.obs;
  var position = Duration.zero.obs;

  var filterType = "All Songs".obs;
  var isServiceReady = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initAudioService();
    checkPermissions();
  }

  Future<void> _initAudioService() async {
    try {
      log("Initializing Audio Service...");
      _audioHandler = await AudioService.init(
        builder: () => MyAudioHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.example.island_vibes.channel.audio',
          androidNotificationChannelName: 'Island Vibes Music',
          androidNotificationOngoing: true,
        ),
      );
      isServiceReady.value = true;
      log("Audio Service Initialized.");

      _audioHandler!.playbackState.listen((state) {
        isPlaying.value = state.playing;
        updateOverlay();
      });

      _audioHandler!.mediaItem.listen((item) {
        if (item != null) {
          currentSongTitle.value = item.title;
          currentArtist.value = item.artist ?? "Unknown";
          updateOverlay();
        }
      });

      AudioService.position.listen((p) {
        position.value = p;
      });
    } catch (e) {
      log("Failed to init audio service: $e");
      Get.snackbar("Error", "Failed to init audio: $e");
    }
  }

  Future<void> checkPermissions() async {
    log("Checking permissions...");
    var storageStatus = await Permission.storage.request();
    var audioStatus = await Permission.audio.request();

    // Explicitly check MANAGE_EXTERNAL_STORAGE for Android 11+ if needed,
    // but usually audio/storage is enough for media.

    if (storageStatus.isGranted || audioStatus.isGranted) {
      log("Storage permission granted.");
      fetchSongs();
    } else {
      log("Storage permission denied.");
      Get.snackbar("Permission", "Storage permission required to play music.");
      // Fallback: Try to fetch anyway in case permission logic is quirky on some devices
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
      filterSongs("All Songs");

    } catch (e) {
      log("Error fetching songs: $e");
      Get.snackbar("Error", "Failed to fetch songs: $e");
    }
  }

  void filterSongs(String type) {
    filterType.value = type;
    if (type == "All Songs") {
      filteredSongs.value = songs;
    } else if (type == "Artists") {
      filteredSongs.value = List.from(songs)..sort((a, b) => (a.artist ?? "").compareTo(b.artist ?? ""));
    } else if (type == "Albums") {
       filteredSongs.value = List.from(songs)..sort((a, b) => (a.album ?? "").compareTo(b.album ?? ""));
    } else {
      filteredSongs.value = songs;
    }
  }

  Future<void> playSong(int index) async {
    // VISUAL FEEDBACK
    Get.snackbar("Debug", "Trying to play song $index...", duration: const Duration(seconds: 1));

    if (_audioHandler == null) {
      Get.snackbar("Error", "Audio Service is not ready yet. Please wait.");
      return;
    }

    try {
      currentSongIndex.value = index;
      var song = filteredSongs[index];

      // Debug URI
      print("Playing URI: ${song.uri}");

      List<MediaItem> mediaItems = filteredSongs.map((s) => MediaItem(
        id: s.uri!,
        album: s.album,
        title: s.title,
        artist: s.artist,
        duration: Duration(milliseconds: s.duration ?? 0),
      )).toList();

      await _audioHandler!.setPlaylist(mediaItems, index);
      await _audioHandler!.play();

      showOverlay();
    } catch (e) {
      log("Error playing song: $e");
      Get.snackbar("Error", "Could not play song: $e", duration: const Duration(seconds: 5));
    }
  }

  Future<void> togglePlay() async {
    if (_audioHandler == null) return;
    try {
      if (isPlaying.value) {
        await _audioHandler!.pause();
      } else {
        await _audioHandler!.play();
      }
    } catch (e) {
      Get.snackbar("Error", "Playback error: $e");
    }
  }

  Future<void> playNext() async => _audioHandler?.skipToNext();
  Future<void> playPrevious() async => _audioHandler?.skipToPrevious();

  void seek(Duration pos) {
    _audioHandler?.seek(pos);
  }

  // --- Overlay Logic ---

  Future<void> showOverlay() async {
    try {
      if (await FlutterOverlayWindow.isActive()) return;

      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: "Dynamic Island",
        overlayContent: 'Island Vibes Playing',
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilitySecret,
        height: 140,
        width: -1,
        startPosition: const OverlayPosition(0, 0),
      );
      updateOverlay();
    } catch (e) {
      print("Overlay error: $e");
      // Don't snackbar here, it might be annoying
    }
  }

  void updateOverlay() {
    try {
      FlutterOverlayWindow.shareData({
        'title': currentSongTitle.value,
        'artist': currentArtist.value,
        'isPlaying': isPlaying.value,
      });
    } catch (e) {
      print("Overlay update error: $e");
    }
  }
}
