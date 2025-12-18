
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb


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
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      if (kIsWeb) {
        // Explicitly pointing to the built asset location for Web
        _controller = VideoPlayerController.networkUrl(
          Uri.parse('assets/assets/video/rain-shave-video.mp4'),
        );
      } else {
        _controller = VideoPlayerController.asset('assets/video/rain-shave-video.mp4');
      }
      
      await _controller.initialize();
      await _controller.setLooping(true);
      await _controller.setVolume(0.0);
      await _controller.play();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
      }
    } catch (error) {
      debugPrint("Video initialization failed: $error");
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A), 
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Background (Video or Fallback Image)
          Positioned.fill(
            child: _buildBackground(),
          ),
            
          // 2. Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.3,
                  colors: [
                    Colors.black54, 
                    Color(0xFF0A0A0A), 
                  ],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),
          
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.4),
            ),
          ),

          // 3. Content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 150, 24, 60),
            child: widget.child,
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    if (_isInitialized && !_hasError) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller.value.size.width,
          height: _controller.value.size.height,
          child: VideoPlayer(_controller),
        ),
      );
    }

    // Fallback Image (No debug text, clean fallback)
    return Image.asset(
      'assets/images/gallery/haircut3.png', 
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const SizedBox(), 
    );
  }
}
