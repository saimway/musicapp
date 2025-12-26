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

  // Fallback player if AudioService fails
  final AudioPlayer _fallbackPlayer = AudioPlayer();

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
  var useFallback = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initAudioService();
    checkPermissions();

    // Fallback listeners
    _fallbackPlayer.playerStateStream.listen((state) {
      if (useFallback.value) {
        isPlaying.value = state.playing;
        updateOverlay();
      }
    });
    _fallbackPlayer.positionStream.listen((p) {
      if (useFallback.value) position.value = p;
    });
    _fallbackPlayer.durationStream.listen((d) {
      if (useFallback.value && d != null) duration.value = d;
    });
    _fallbackPlayer.processingStateStream.listen((state) {
      if (useFallback.value && state == ProcessingState.completed) {
        playNext();
      }
    });
  }

  Future<void> _initAudioService() async {
    log("Initializing Audio Service...");
    int retries = 0;
    while (retries < 3) {
      try {
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
        return; // Success
      } catch (e) {
        log("Failed to init audio service (Attempt ${retries + 1}): $e");
        retries++;
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    // If we reach here, AudioService failed 3 times. Use fallback.
    log("AudioService failed. Switching to Fallback Player.");
    Get.snackbar("Warning", "Background play disabled (AudioService failed). Using fallback.");
    useFallback.value = true;
    isServiceReady.value = true; // Technically ready, just fallback
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
      Get.snackbar("Permission", "Storage permission required to play music.");
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
    Get.snackbar("Debug", "Trying to play song $index...", duration: const Duration(milliseconds: 500));

    if (!isServiceReady.value) {
      Get.snackbar("Error", "Player is initializing... please wait.");
      return;
    }

    try {
      currentSongIndex.value = index;
      var song = filteredSongs[index];
      currentSongTitle.value = song.title;
      currentArtist.value = song.artist ?? "Unknown";

      if (useFallback.value) {
        // Fallback Logic
        await _fallbackPlayer.setAudioSource(AudioSource.uri(Uri.parse(song.uri!)));
        await _fallbackPlayer.play();
      } else {
        // AudioService Logic
        List<MediaItem> mediaItems = filteredSongs.map((s) => MediaItem(
          id: s.uri!,
          album: s.album,
          title: s.title,
          artist: s.artist,
          duration: Duration(milliseconds: s.duration ?? 0),
        )).toList();

        await _audioHandler!.setPlaylist(mediaItems, index);
        await _audioHandler!.play();
      }

      showOverlay();
    } catch (e) {
      log("Error playing song: $e");
      Get.snackbar("Error", "Could not play song: $e", duration: const Duration(seconds: 5));
    }
  }

  Future<void> togglePlay() async {
    try {
      if (useFallback.value) {
        if (isPlaying.value) {
          await _fallbackPlayer.pause();
        } else {
          await _fallbackPlayer.play();
        }
      } else {
        if (_audioHandler == null) return;
        if (isPlaying.value) {
          await _audioHandler!.pause();
        } else {
          await _audioHandler!.play();
        }
      }
    } catch (e) {
      Get.snackbar("Error", "Playback error: $e");
    }
  }

  Future<void> playNext() async {
    if (currentSongIndex.value < filteredSongs.length - 1) {
      if (useFallback.value) {
        playSong(currentSongIndex.value + 1);
      } else {
        _audioHandler?.skipToNext();
      }
    }
  }

  Future<void> playPrevious() async {
    if (currentSongIndex.value > 0) {
      if (useFallback.value) {
        playSong(currentSongIndex.value - 1);
      } else {
        _audioHandler?.skipToPrevious();
      }
    }
  }

  void seek(Duration pos) {
    if (useFallback.value) {
      _fallbackPlayer.seek(pos);
    } else {
      _audioHandler?.seek(pos);
    }
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
