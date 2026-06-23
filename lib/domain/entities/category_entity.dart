import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
  final String id;
  final String companyId;
  final String name;
  final int order;
  final bool active;

  const CategoryEntity({
    required this.id,
    required this.companyId,
    required this.name,
    this.order = 0,
    this.active = true,
  });

  @override
  List<Object?> get props => [id, companyId, name, order, active];
}
