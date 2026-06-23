import '../entities/channel_entity.dart';

abstract class ChannelRepository {
  Stream<List<ChannelEntity>> getChannels();
  Future<void> addChannel(ChannelEntity channel);
  Future<void> updateChannel(ChannelEntity channel);
  Future<void> deleteChannel(String id);
}
