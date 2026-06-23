import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../../../domain/entities/profile_entity.dart';

final profileProvider = StateNotifierProvider<ProfileNotifier, List<ProfileEntity>>((ref) {
  return ProfileNotifier();
});

class ProfileNotifier extends StateNotifier<List<ProfileEntity>> {
  ProfileNotifier() : super([]) {
    _loadProfiles();
  }

  late final Box _box;
  final _uuid = const Uuid();

  void _loadProfiles() {
    _box = Hive.box('profiles_box');
    
    if (_box.isEmpty) {
      // Seed default profiles
      final defaultProfiles = [
        const ProfileEntity(
          id: '1',
          userId: 'usr_me',
          name: 'Adulto',
          avatarUrl: 'assets/images/avatar_adult.png',
          type: 'adult',
        ),
        const ProfileEntity(
          id: '2',
          userId: 'usr_me',
          name: 'Infantil',
          avatarUrl: 'assets/images/avatar_kids.png',
          type: 'kids',
        ),
        const ProfileEntity(
          id: '3',
          userId: 'usr_me',
          name: 'Invitado',
          avatarUrl: 'assets/images/avatar_cine.png',
          type: 'guest',
        ),
      ];

      for (final profile in defaultProfiles) {
        _box.put(profile.id, _profileToMap(profile));
      }
      state = defaultProfiles;
    } else {
      final List<ProfileEntity> list = [];
      for (final key in _box.keys) {
        final map = Map<String, dynamic>.from(_box.get(key));
        list.add(_profileFromMap(map));
      }
      state = list;
    }
  }

  Future<void> addProfile({
    required String name,
    required String avatarUrl,
    required String type,
    String? pinCode,
  }) async {
    final newProfile = ProfileEntity(
      id: _uuid.v4(),
      userId: 'usr_me',
      name: name,
      avatarUrl: avatarUrl,
      type: type,
      pinCode: pinCode,
    );

    await _box.put(newProfile.id, _profileToMap(newProfile));
    state = [...state, newProfile];
  }

  Future<void> updateProfile(ProfileEntity profile) async {
    await _box.put(profile.id, _profileToMap(profile));
    state = [
      for (final p in state)
        if (p.id == profile.id) profile else p
    ];
  }

  Future<void> deleteProfile(String id) async {
    await _box.delete(id);
    state = state.where((p) => p.id != id).toList();
  }

  Map<String, dynamic> _profileToMap(ProfileEntity profile) {
    return {
      'id': profile.id,
      'userId': profile.userId,
      'name': profile.name,
      'avatarUrl': profile.avatarUrl,
      'type': profile.type,
      'pinCode': profile.pinCode,
    };
  }

  ProfileEntity _profileFromMap(Map<String, dynamic> map) {
    return ProfileEntity(
      id: map['id'] as String,
      userId: map['userId'] as String,
      name: map['name'] as String,
      avatarUrl: map['avatarUrl'] as String,
      type: map['type'] as String? ?? 'adult',
      pinCode: map['pinCode'] as String?,
    );
  }
}
