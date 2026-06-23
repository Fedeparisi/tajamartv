import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/channel_repository_impl.dart';
import '../../../../domain/entities/channel_entity.dart';
import '../../../../domain/repositories/channel_repository.dart';

final channelRepositoryProvider = Provider<ChannelRepository>((ref) {
  return ChannelRepositoryImpl();
});

final channelsStreamProvider = StreamProvider<List<ChannelEntity>>((ref) {
  final repository = ref.watch(channelRepositoryProvider);
  return repository.getChannels();
});

class ChannelAdminController extends StateNotifier<AsyncValue<void>> {
  final ChannelRepository _repository;

  ChannelAdminController(this._repository) : super(const AsyncData(null));

  Future<void> addChannel(ChannelEntity channel) async {
    state = const AsyncLoading();
    try {
      await _repository.addChannel(channel);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteChannel(String id) async {
    state = const AsyncLoading();
    try {
      await _repository.deleteChannel(id);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateChannel(ChannelEntity channel) async {
    state = const AsyncLoading();
    try {
      await _repository.updateChannel(channel);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final channelAdminControllerProvider = StateNotifierProvider<ChannelAdminController, AsyncValue<void>>((ref) {
  final repository = ref.watch(channelRepositoryProvider);
  return ChannelAdminController(repository);
});
