import 'package:equatable/equatable.dart';

class ChannelEntity extends Equatable {
  final String id;
  final String companyId;
  final String name;
  final String logo;
  final String categoryId;
  final String url;
  final String streamType; // hls, dash, rtmp, mp4, youtube, m3u8
  final String language;
  final String country;
  final String epgId;
  final bool featured;
  final bool active;
  final int order;
  final String status; // online, unstable, offline

  const ChannelEntity({
    required this.id,
    required this.companyId,
    required this.name,
    required this.logo,
    required this.categoryId,
    required this.url,
    required this.streamType,
    required this.language,
    required this.country,
    required this.epgId,
    this.featured = false,
    this.active = true,
    this.order = 0,
    this.status = 'online',
  });

  @override
  List<Object?> get props => [
        id, companyId, name, logo, categoryId, url, streamType,
        language, country, epgId, featured, active, order, status,
      ];
}
