import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String companyId;
  final String email;
  final String displayName;
  final String role; // super_admin, admin, operator, client
  final String? subscriptionId;
  final bool blocked;
  final bool emailVerified;
  final bool twoFactorEnabled;

  const UserEntity({
    required this.id,
    required this.companyId,
    required this.email,
    required this.displayName,
    this.role = 'client',
    this.subscriptionId,
    this.blocked = false,
    this.emailVerified = false,
    this.twoFactorEnabled = false,
  });

  @override
  List<Object?> get props => [
        id,
        companyId,
        email,
        displayName,
        role,
        subscriptionId,
        blocked,
        emailVerified,
        twoFactorEnabled,
      ];
}
