import 'package:flutter/services.dart';

void enterFullScreen() {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
}

void exitFullScreen() {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
}

void registerFullscreenListener(void Function(bool) onChange) {
  // No-op on non-web platforms
}
