import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/layout_provider.dart';
import 'layouts/netflix_layout.dart';
import 'layouts/disney_layout.dart';
import 'layouts/directv_layout.dart';
import 'layouts/flow_layout.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layoutStyle = ref.watch(layoutProvider);

    switch (layoutStyle) {
      case HomeLayoutStyle.disney:
        return const DisneyLayout();
      case HomeLayoutStyle.directv:
        return const DirectvLayout();
      case HomeLayoutStyle.flow:
        return const FlowLayout();
      case HomeLayoutStyle.netflix:
      default:
        return const NetflixLayout();
    }
  }
}
