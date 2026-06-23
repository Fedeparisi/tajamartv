import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../../domain/entities/profile_entity.dart';

final profileProvider = StateNotifierProvider<ProfileNotifier, List<ProfileEntity>>((ref) {
  return ProfileNotifier();
});

class ProfileNotifier extends StateNotifier<List<ProfileEntity>> {
  final _db = FirebaseFirestore.instance;
  StreamSubscription? _subscription;
  final _uuid = const Uuid();

  ProfileNotifier() : super([]) {
    _listenToProfiles();
  }

  void _listenToProfiles() {
    _subscription = _db.collection('profiles').snapshots().listen((snapshot) {
      final profiles = snapshot.docs.map((doc) {
        final map = doc.data();
        return ProfileEntity(
          id: doc.id,
          userId: map['userId'] as String? ?? 'usr_me',
          name: map['name'] as String? ?? '',
          avatarUrl: map['avatarUrl'] as String? ?? 'assets/images/avatar_adult.png',
          type: map['type'] as String? ?? 'adult',
          pinCode: map['pinCode'] as String?,
        );
      }).toList();

      if (profiles.isEmpty) {
        _seedDefaultProfiles();
      } else {
        state = profiles;
      }
    }, onError: (e) {
      // Fallback or log error
    });
  }

  Future<void> _seedDefaultProfiles() async {
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
      await _db.collection('profiles').doc(profile.id).set({
        'id': profile.id,
        'userId': profile.userId,
        'name': profile.name,
        'avatarUrl': profile.avatarUrl,
        'type': profile.type,
        'pinCode': profile.pinCode,
      });
    }
  }

  Future<void> addProfile({
    required String name,
    required String avatarUrl,
    required String type,
    String? pinCode,
  }) async {
    final id = _uuid.v4();
    final newProfile = ProfileEntity(
      id: id,
      userId: 'usr_me',
      name: name,
      avatarUrl: avatarUrl,
      type: type,
      pinCode: pinCode,
    );

    await _db.collection('profiles').doc(id).set({
      'id': newProfile.id,
      'userId': newProfile.userId,
      'name': newProfile.name,
      'avatarUrl': newProfile.avatarUrl,
      'type': newProfile.type,
      'pinCode': newProfile.pinCode,
    });
  }

  Future<void> updateProfile(ProfileEntity profile) async {
    await _db.collection('profiles').doc(profile.id).set({
      'id': profile.id,
      'userId': profile.userId,
      'name': profile.name,
      'avatarUrl': profile.avatarUrl,
      'type': profile.type,
      'pinCode': profile.pinCode,
    });
  }

  Future<void> deleteProfile(String id) async {
    await _db.collection('profiles').doc(id).delete();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
