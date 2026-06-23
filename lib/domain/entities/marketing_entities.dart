import 'package:equatable/equatable.dart';

class AdEntity extends Equatable {
  final String id;
  final String companyId;
  final String title;
  final String imageUrl;
  final String targetUrl;
  final String type; // banner, preroll, midroll
  final String position; // home_carousel, player_overlay
  final bool active;
  final DateTime startDate;
  final DateTime endDate;

  const AdEntity({
    required this.id,
    required this.companyId,
    required this.title,
    required this.imageUrl,
    required this.targetUrl,
    required this.type,
    required this.position,
    this.active = true,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [id, companyId, title, imageUrl, targetUrl, type, position, active, startDate, endDate];
}

class AnalyticsEventEntity extends Equatable {
  final String id;
  final String companyId;
  final String userId;
  final String eventName; // channel_view, app_open, ad_click
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  const AnalyticsEventEntity({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.eventName,
    required this.metadata,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [id, companyId, userId, eventName, metadata, timestamp];
}
