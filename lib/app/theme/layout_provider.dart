import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme_provider.dart'; // To access sharedPreferencesProvider

enum HomeLayoutStyle { netflix, disney, directv, flow }

class LayoutNotifier extends Notifier<HomeLayoutStyle> {
  static const _layoutKey = 'selected_home_layout';

  @override
  HomeLayoutStyle build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final savedLayout = prefs.getString(_layoutKey);
    if (savedLayout != null) {
      return HomeLayoutStyle.values.firstWhere(
        (e) => e.toString() == savedLayout,
        orElse: () => HomeLayoutStyle.netflix,
      );
    }
    return HomeLayoutStyle.netflix;
  }

  void setLayout(HomeLayoutStyle layout) {
    state = layout;
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setString(_layoutKey, layout.toString());
  }
}

final layoutProvider = NotifierProvider<LayoutNotifier, HomeLayoutStyle>(() {
  return LayoutNotifier();
});
