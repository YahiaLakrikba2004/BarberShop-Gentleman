import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart';
import 'web_video_player.dart';

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

  // Video plays only on web (HtmlElementView) and mobile (video_player).
  // On Windows/Linux desktop the plugin has codec issues — use image fallback.
  bool get _videoSupported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      registerWebVideoView();
    } else if (_videoSupported) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    if (kIsWeb) return; // Prevent logs on web
    try {
      _controller = VideoPlayerController.asset('assets/video/rain-shave-video.mp4');
      
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
    if (!kIsWeb && _videoSupported) _controller.dispose();
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
              color: Colors.black.withValues(alpha: 0.4),
            ),
          ),

          // 3. Content
          Builder(builder: (context) {
            final isDesktop = MediaQuery.of(context).size.width > 800;
            return Padding(
              padding: EdgeInsets.fromLTRB(
                isDesktop ? 80 : 24,
                isDesktop ? 120 : 150,
                isDesktop ? 80 : 24,
                isDesktop ? 80 : 60,
              ),
              child: widget.child,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    if (kIsWeb) {
      return const HtmlElementView(viewType: 'video-bg-view');
    }

    if (_videoSupported && _isInitialized && !_hasError) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller.value.size.width,
          height: _controller.value.size.height,
          child: VideoPlayer(_controller),
        ),
      );
    }

    // Fallback image (used on Windows/Linux desktop and when video fails)
    return Image.asset(
      'assets/images/gallery/haircut3.png',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0A0A0A)),
    );
  }
}
