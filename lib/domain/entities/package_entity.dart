import 'package:equatable/equatable.dart';

class PackageEntity extends Equatable {
  final String id;
  final String companyId;
  final String name; // BÁSICO, ESTÁNDAR, PREMIUM, FULL
  final double price;
  final String currency;
  final int maxDevices; // Cantidad máxima de dispositivos registrados
  final int maxConcurrent; // Streams simultáneos
  final List<String> categoryIds; // Categorías incluidas
  final List<String> channelIds; // Canales específicos incluidos (o ['all'])
  final int trialDays;
  final bool active;

  const PackageEntity({
    required this.id,
    required this.companyId,
    required this.name,
    required this.price,
    this.currency = 'ARS',
    this.maxDevices = 1,
    this.maxConcurrent = 1,
    this.categoryIds = const [],
    this.channelIds = const ['all'],
    this.trialDays = 0,
    this.active = true,
  });

  @override
  List<Object?> get props => [
        id, companyId, name, price, currency, maxDevices, maxConcurrent,
        categoryIds, channelIds, trialDays, active
      ];
}
