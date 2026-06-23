import 'package:equatable/equatable.dart';

class CompanyEntity extends Equatable {
  final String id;
  final String name;
  final String logo;
  final String primaryColor;
  final String secondaryColor;
  final String domain;
  final bool whiteLabel;
  final Map<String, dynamic> settings;
  final bool active;

  const CompanyEntity({
    required this.id,
    required this.name,
    this.logo = '',
    this.primaryColor = '#2563EB',
    this.secondaryColor = '#60A5FA',
    this.domain = '',
    this.whiteLabel = false,
    this.settings = const {},
    this.active = true,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        logo,
        primaryColor,
        secondaryColor,
        domain,
        whiteLabel,
        settings,
        active,
      ];
}
