import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/channel_entity.dart';
import '../../domain/repositories/channel_repository.dart';
import '../models/channel_model.dart';

class ChannelRepositoryImpl implements ChannelRepository {
  final _db = FirebaseFirestore.instance;

  @override
  Stream<List<ChannelEntity>> getChannels() {
    return _db
        .collection('channels')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map<ChannelEntity>((doc) {
        final map = doc.data();
        final id = doc.id;
        return ChannelModel.fromJson(map, id);
      }).toList();
      list.sort((a, b) => a.order.compareTo(b.order));
      return list;
    });
  }

  @override
  Future<void> addChannel(ChannelEntity channel) async {
    final ref = _db.collection('channels').doc();
    final id = ref.id;
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
    await ref.set(map);
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
    await _db.collection('channels').doc(channel.id).set(map);
  }

  @override
  Future<void> deleteChannel(String id) async {
    await _db.collection('channels').doc(id).delete();
  }
}
