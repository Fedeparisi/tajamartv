import 'package:equatable/equatable.dart';

class SubscriptionEntity extends Equatable {
  final String id;
  final String userId;
  final String companyId;
  final String packageId;
  final String status; // active, suspended, cut, expired
  final DateTime startDate;
  final DateTime endDate;
  final bool autoRenew;
  final String paymentMethod; // mercadopago, transfer, manual

  const SubscriptionEntity({
    required this.id,
    required this.userId,
    required this.companyId,
    required this.packageId,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.autoRenew = true,
    this.paymentMethod = 'manual',
  });

  @override
  List<Object?> get props => [
        id, userId, companyId, packageId, status, startDate, endDate, autoRenew, paymentMethod
      ];
}
