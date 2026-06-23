import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/subscription_entity.dart';

class AdminBillingScreen extends StatefulWidget {
  const AdminBillingScreen({super.key});

  @override
  State<AdminBillingScreen> createState() => _AdminBillingScreenState();
}

class _AdminBillingScreenState extends State<AdminBillingScreen> {
  final List<SubscriptionEntity> _subscriptions = List.generate(
    15,
    (index) => SubscriptionEntity(
      id: 'sub_$index',
      userId: 'usr_$index',
      companyId: 'company_tajamar',
      packageId: index % 3 == 0 ? 'PREMIUM' : 'BÁSICO',
      status: index % 5 == 0 ? 'expired' : 'active',
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now().add(Duration(days: index % 5 == 0 ? -1 : 30)),
      paymentMethod: index % 2 == 0 ? 'mercadopago' : 'transfer',
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Gestión de Suscripciones y Pagos',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download),
              label: const Text('Exportar Excel'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Card(
            color: AppColors.panel,
            child: ListView.separated(
              itemCount: _subscriptions.length,
              separatorBuilder: (context, index) => const Divider(color: AppColors.glassBorder),
              itemBuilder: (context, index) {
                final sub = _subscriptions[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.background,
                    child: Icon(
                      sub.paymentMethod == 'mercadopago' ? Icons.payment : Icons.account_balance,
                      color: AppColors.secondary,
                    ),
                  ),
                  title: Text(
                    'Suscripción ${sub.packageId}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Usuario: ${sub.userId} • Vence: ${sub.endDate.toString().split(' ')[0]}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: sub.status == 'active'
                              ? AppColors.online.withOpacity(0.2)
                              : AppColors.offline.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: sub.status == 'active' ? AppColors.online : AppColors.offline,
                          ),
                        ),
                        child: Text(
                          sub.status.toUpperCase(),
                          style: TextStyle(
                            color: sub.status == 'active' ? AppColors.online : AppColors.offline,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(icon: const Icon(Icons.receipt, color: AppColors.textSecondary), onPressed: () {}),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
