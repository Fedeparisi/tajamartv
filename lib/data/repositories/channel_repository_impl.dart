import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/channel_entity.dart';
import '../../domain/repositories/channel_repository.dart';
import '../models/channel_model.dart';

class ChannelRepositoryImpl implements ChannelRepository {
  final Box _box = Hive.box('channels_box');

  List<ChannelEntity> _getChannelsList() {
    final list = _box.values.map<ChannelEntity>((item) {
      final map = Map<String, dynamic>.from(item as Map);
      final id = map['id'] as String? ?? '';
      return ChannelModel.fromJson(map, id);
    }).toList();
    list.sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  @override
  Stream<List<ChannelEntity>> getChannels() async* {
    yield _getChannelsList();
    await for (final _ in _box.watch()) {
      yield _getChannelsList();
    }
  }

  @override
  Future<void> addChannel(ChannelEntity channel) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final model = ChannelModel(
      id: id,
      companyId: channel.companyId,
      name: channel.name,
      logo: channel.logo,
      categoryId: channel.categoryId,
      url: channel.url,
      streamType: channel.streamType,
      language: channel.language,
      country: channel.country,
      epgId: channel.epgId,
      featured: channel.featured,
      active: channel.active,
      order: channel.order,
      status: channel.status,
    );
    final map = model.toJson();
    map['id'] = id;
    await _box.put(id, map);
  }

  @override
  Future<void> updateChannel(ChannelEntity channel) async {
    final model = ChannelModel(
      id: channel.id,
      companyId: channel.companyId,
      name: channel.name,
      logo: channel.logo,
      categoryId: channel.categoryId,
      url: channel.url,
      streamType: channel.streamType,
      language: channel.language,
      country: channel.country,
      epgId: channel.epgId,
      featured: channel.featured,
      active: channel.active,
      order: channel.order,
      status: channel.status,
    );
    final map = model.toJson();
    map['id'] = channel.id;
    await _box.put(channel.id, map);
  }

  @override
  Future<void> deleteChannel(String id) async {
    await _box.delete(id);
  }
}
