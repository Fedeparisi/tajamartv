import 'package:equatable/equatable.dart';

class ProfileEntity extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String avatarUrl;
  final String type; // adult, kids, guest
  final String? pinCode; // Para control parental

  const ProfileEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.avatarUrl,
    this.type = 'adult',
    this.pinCode,
  });

  @override
  List<Object?> get props => [id, userId, name, avatarUrl, type, pinCode];
}
