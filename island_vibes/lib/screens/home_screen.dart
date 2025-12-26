import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:animate_do/animate_do.dart';
import '../controllers/music_controller.dart';
import 'player_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MusicController controller = Get.find<MusicController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Island Vibes", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          IconButton(
            onPressed: () => controller.checkPermissions(),
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh Library"
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Obx(() => Row(
                children: [
                  _buildChip("All Songs", controller),
                  _buildChip("Artists", controller),
                  _buildChip("Albums", controller),
                ],
              )),
            ),
          ),

          Expanded(
            child: Obx(() {
              if (controller.filteredSongs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.music_note, size: 80, color: Colors.grey),
                      const SizedBox(height: 20),
                      Text(
                        controller.songs.isEmpty ? "No songs found" : "No songs match filter",
                        style: const TextStyle(color: Colors.grey)
                      ),
                      if (controller.songs.isEmpty)
                        TextButton(
                          onPressed: () => controller.checkPermissions(),
                          child: const Text("Check Permissions"),
                        )
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 100),
                itemCount: controller.filteredSongs.length,
                itemBuilder: (context, index) {
                  SongModel song = controller.filteredSongs[index];

                  return FadeInUp(
                    duration: const Duration(milliseconds: 400),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: QueryArtworkWidget(
                        id: song.id,
                        type: ArtworkType.AUDIO,
                        nullArtworkWidget: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.music_note, color: Colors.white),
                        ),
                        artworkBorder: BorderRadius.circular(10),
                      ),
                      title: Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      subtitle: Text(
                        song.artist ?? "Unknown Artist",
                        maxLines: 1,
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      onTap: () {
                        print("Tapped song at index: $index");
                        controller.playSong(index);
                        Get.to(() => const PlayerScreen(), transition: Transition.downToUp);
                      },
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, MusicController controller) {
    bool isSelected = controller.filterType.value == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          if (selected) controller.filterSongs(label);
        },
        selectedColor: Colors.white,
        backgroundColor: Colors.grey[900],
        labelStyle: TextStyle(
          color: isSelected ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
