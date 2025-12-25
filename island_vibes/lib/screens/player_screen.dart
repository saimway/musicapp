import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:animate_do/animate_do.dart';
import '../controllers/music_controller.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MusicController controller = Get.find<MusicController>();

    return Scaffold(
      backgroundColor: Colors.black, // Immersive background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 30),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Album Art
            Expanded(
              flex: 5,
              child: Obx(() {
                if (controller.currentSongIndex.value == -1) return const SizedBox();
                var song = controller.songs[controller.currentSongIndex.value];

                return ZoomIn(
                  child: Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: MediaQuery.of(context).size.width * 0.8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                          )
                        ],
                      ),
                      child: QueryArtworkWidget(
                        id: song.id,
                        type: ArtworkType.AUDIO,
                        artworkHeight: MediaQuery.of(context).size.width * 0.8,
                        artworkWidth: MediaQuery.of(context).size.width * 0.8,
                        artworkBorder: BorderRadius.circular(20),
                        nullArtworkWidget: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.music_note, size: 120, color: Colors.white24),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),

            // Song Info
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  Obx(() => FadeInUp(
                    child: Text(
                      controller.currentSongTitle.value,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),
                  const SizedBox(height: 10),
                  Obx(() => Text(
                    controller.currentArtist.value,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    maxLines: 1,
                  )),
                ],
              ),
            ),

            // Progress Bar
            Obx(() {
              final position = controller.position.value;
              final duration = controller.duration.value;
              return Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
                      trackHeight: 2.0,
                    ),
                    child: Slider(
                      min: 0,
                      max: duration.inSeconds.toDouble(),
                      value: position.inSeconds.toDouble().clamp(0, duration.inSeconds.toDouble()),
                      activeColor: Colors.white,
                      inactiveColor: Colors.white24,
                      onChanged: (value) {
                        controller.seek(Duration(seconds: value.toInt()));
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(position), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        Text(_formatDuration(duration), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              );
            }),

            // Controls
            Expanded(
              flex: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous, size: 40, color: Colors.white),
                    onPressed: () => controller.playPrevious(),
                  ),

                  // Play/Pause Button
                  Obx(() => Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: IconButton(
                      iconSize: 40,
                      icon: Icon(
                        controller.isPlaying.value ? Icons.pause : Icons.play_arrow,
                        color: Colors.black,
                      ),
                      onPressed: () => controller.togglePlay(),
                    ),
                  )),

                  IconButton(
                    icon: const Icon(Icons.skip_next, size: 40, color: Colors.white),
                    onPressed: () => controller.playNext(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
