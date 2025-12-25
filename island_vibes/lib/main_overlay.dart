import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'widgets/dynamic_island_widget.dart';

// This is the entry point for the overlay
@pragma("vm:entry-point")
void overlayMain() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: DynamicIslandWidget(),
  ));
}
