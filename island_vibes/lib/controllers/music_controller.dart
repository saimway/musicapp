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
  MyAudioHandler? _audioHandler; // Made nullable for safety

  var songs = <SongModel>[].obs;
  var filteredSongs = <SongModel>[].obs;

  var isPlaying = false.obs;
  var currentSongIndex = (-1).obs;
  var currentSongTitle = "".obs;
  var currentArtist = "".obs;
  var duration = Duration.zero.obs;
  var position = Duration.zero.obs;

  var filterType = "All Songs".obs;
  var isServiceReady = false.obs; // Track initialization

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
    }
  }

  Future<void> checkPermissions() async {
    log("Checking permissions...");
    var storageStatus = await Permission.storage.request();
    var audioStatus = await Permission.audio.request();

    if (storageStatus.isGranted || audioStatus.isGranted) {
      log("Storage permission granted.");
      fetchSongs();
    } else {
      log("Storage permission denied.");
    }

    bool status = await FlutterOverlayWindow.isPermissionGranted();
    if (!status) {
      await FlutterOverlayWindow.requestPermission();
    }
  }

  Future<void> fetchSongs() async {
    try {
      log("Fetching songs...");
      List<SongModel> fetchedSongs = await _audioQuery.querySongs(
        sortType: SongSortType.DATE_ADDED,
        orderType: OrderType.DESC_OR_GREATER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      var validSongs = fetchedSongs.where((song) => song.duration != null && song.duration! > 10000).toList();
      songs.value = validSongs;
      filterSongs("All Songs");
      log("Fetched ${songs.length} songs.");

    } catch (e) {
      log("Error fetching songs: $e");
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
    if (!isServiceReady.value || _audioHandler == null) {
      log("Audio Service not ready yet!");
      Get.snackbar("Wait", "Audio Service is initializing...");
      return;
    }

    try {
      log("Playing song at index $index");
      currentSongIndex.value = index;
      var song = filteredSongs[index];

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
    }
  }

  Future<void> togglePlay() async {
    if (_audioHandler == null) return;
    if (isPlaying.value) {
      await _audioHandler!.pause();
    } else {
      await _audioHandler!.play();
    }
  }

  Future<void> playNext() async => _audioHandler?.skipToNext();
  Future<void> playPrevious() async => _audioHandler?.skipToPrevious();

  void seek(Duration pos) {
    _audioHandler?.seek(pos);
  }

  // --- Overlay Logic ---

  Future<void> showOverlay() async {
    if (await FlutterOverlayWindow.isActive()) return;

    await FlutterOverlayWindow.showOverlay(
      enableDrag: true,
      overlayTitle: "Dynamic Island",
      overlayContent: 'Island Vibes Playing',
      flag: OverlayFlag.defaultFlag,
      visibility: NotificationVisibility.visibilitySecret,
      // positionGravity removed
      height: 140,
      width: -1,
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
