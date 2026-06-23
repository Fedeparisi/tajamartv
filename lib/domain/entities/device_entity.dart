import 'package:equatable/equatable.dart';

class DeviceEntity extends Equatable {
  final String id;
  final String userId;
  final String companyId;
  final String platform; // android, android_tv, web, windows
  final String deviceName;
  final String deviceId; // ID único del dispositivo hardware/software
  final DateTime lastAccess;
  final bool active;

  const DeviceEntity({
    required this.id,
    required this.userId,
    required this.companyId,
    required this.platform,
    required this.deviceName,
    required this.deviceId,
    required this.lastAccess,
    this.active = true,
  });

  @override
  List<Object?> get props => [
        id, userId, companyId, platform, deviceName, deviceId, lastAccess, active
      ];
}
