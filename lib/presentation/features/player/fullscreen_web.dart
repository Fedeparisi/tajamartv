import 'dart:html' as html;
import 'package:flutter/services.dart';

void enterFullScreen() {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  try {
    html.document.documentElement?.requestFullscreen();
  } catch (e) {
    // Browser might prevent it without direct click event context
  }
}

void exitFullScreen() {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  try {
    if (html.document.fullscreenElement != null) {
      html.document.exitFullscreen();
    }
  } catch (e) {
    // Browser might prevent it
  }
}

void registerFullscreenListener(void Function(bool) onChange) {
  html.document.onFullscreenChange.listen((event) {
    onChange(html.document.fullscreenElement != null);
  });
}
