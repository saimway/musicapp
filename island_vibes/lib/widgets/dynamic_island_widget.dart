import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:animate_do/animate_do.dart';

class DynamicIslandWidget extends StatefulWidget {
  const DynamicIslandWidget({super.key});

  @override
  State<DynamicIslandWidget> createState() => _DynamicIslandWidgetState();
}

class _DynamicIslandWidgetState extends State<DynamicIslandWidget> {
  String songTitle = "Loading...";
  String artist = "";
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    // Listen for updates from the main app
    FlutterOverlayWindow.overlayListener.listen((event) {
      if (event is Map) {
        if (mounted) {
          setState(() {
            if (event['title'] != null) songTitle = event['title'];
            if (event['artist'] != null) artist = event['artist'];
            if (event['isPlaying'] != null) isPlaying = event['isPlaying'];
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // A black pill shape mimicking Dynamic Island
    return Material(
      color: Colors.transparent,
      child: Center(
        child: GestureDetector(
          // Interaction to close or expand could be added here
          onTap: () {
            // Optional: Bring app to foreground (requires extra implementation)
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            width: MediaQuery.of(context).size.width * 0.92,
            height: 70, // Compact height
            decoration: BoxDecoration(
              color: const Color(0xFF000000), // Pure black
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Mock Album Art / Visualizer
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: isPlaying
                    ? const Icon(Icons.graphic_eq, color: Colors.white, size: 20)
                    : const Icon(Icons.music_note, color: Colors.white, size: 20),
                ),

                const SizedBox(width: 12),

                // Text Info
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Scrolling text if too long
                      SizedBox(
                        height: 20,
                        child: Text(
                          songTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            decoration: TextDecoration.none
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        artist,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          decoration: TextDecoration.none
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Mini Waveform Animation (Fake Visualizer)
                if (isPlaying)
                  Row(
                    children: [
                      _buildBar(10),
                      const SizedBox(width: 2),
                      _buildBar(18),
                      const SizedBox(width: 2),
                      _buildBar(14),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBar(double height) {
    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      infinite: true,
      child: Container(
        width: 3,
        height: height,
        decoration: BoxDecoration(
          color: Colors.greenAccent,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
