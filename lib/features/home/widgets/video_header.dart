
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoHeader extends StatefulWidget {
  final Widget child;

  const VideoHeader({
    super.key,
    required this.child,
  });

  @override
  State<VideoHeader> createState() => _VideoHeaderState();
}

class _VideoHeaderState extends State<VideoHeader> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/video/rain-shave-video.mp4')
      ..initialize().then((_) {
        _controller.setLooping(true);
        _controller.setVolume(0.0); // Mute for background
        _controller.play();
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }).catchError((error) {
         debugPrint("Video initialization failed: $error");
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Keep the original container properties for fallback/sizing
      width: double.infinity,
       // Remove fixed height to let content dictate, or use AspectRatio?
       // The original container had no explicit height, it was just padding around content.
       // But for video cover, we might want to ensure it covers the area.
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A), // Black fallback
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Video Background
          if (_isInitialized)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                   // Enforce aspect ratio to cover
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            ),
            
          // 2. Gradient Overlay (Vignette) - Essential for text readability
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.3,
                  colors: [
                    Colors.black54, // Semi-transparent center
                    Color(0xFF0A0A0A), // Solid black corners
                  ],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),
          
          // Additional dark overlay for better contrast
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.4),
            ),
          ),

          // 3. Content
          // We wrap the child in the original padding
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 150, 24, 60),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
