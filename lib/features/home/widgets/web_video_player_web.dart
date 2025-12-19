import 'dart:ui_web' as ui_web;
import 'dart:html' as html;

void registerWebVideoView() {
  ui_web.platformViewRegistry.registerViewFactory(
    'video-bg-view',
    (int viewId) {
      return html.VideoElement()
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..src = 'assets/assets/video/rain-shave-video.mp4'
        ..autoplay = true
        ..loop = true
        ..muted = true
        ..attributes['playsinline'] = 'true';
    },
  );
}
