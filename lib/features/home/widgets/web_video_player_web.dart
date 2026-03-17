import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;

void registerWebVideoView() {
  ui_web.platformViewRegistry.registerViewFactory(
    'video-bg-view',
    (int viewId) {
      final video = web.document.createElement('video') as web.HTMLVideoElement;
      video.style.border = 'none';
      video.style.width = '100%';
      video.style.height = '100%';
      video.style.objectFit = 'cover';
      video.src = 'assets/assets/video/rain-shave-video.mp4';
      video.autoplay = true;
      video.loop = true;
      video.muted = true;
      video.setAttribute('playsinline', 'true');
      return video;
    },
  );
}
