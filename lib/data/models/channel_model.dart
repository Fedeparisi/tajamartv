import '../../domain/entities/channel_entity.dart';

class ChannelModel extends ChannelEntity {
  const ChannelModel({
    required super.id,
    required super.companyId,
    required super.name,
    required super.logo,
    required super.categoryId,
    required super.url,
    required super.streamType,
    required super.language,
    required super.country,
    required super.epgId,
    super.featured = false,
    super.active = true,
    super.order = 0,
    super.status = 'online',
  });

  factory ChannelModel.fromJson(Map<String, dynamic> json, String documentId) {
    return ChannelModel(
      id: documentId,
      companyId: json['companyId'] ?? '',
      name: json['name'] ?? '',
      logo: json['logo'] ?? '',
      categoryId: json['categoryId'] ?? 'General',
      url: json['url'] ?? '',
      streamType: json['streamType'] ?? 'hls',
      language: json['language'] ?? 'es',
      country: json['country'] ?? 'AR',
      epgId: json['epgId'] ?? '',
      featured: json['featured'] ?? false,
      active: json['active'] ?? true,
      order: json['order'] ?? 0,
      status: json['status'] ?? 'online',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companyId': companyId,
      'name': name,
      'logo': logo,
      'categoryId': categoryId,
      'url': url,
      'streamType': streamType,
      'language': language,
      'country': country,
      'epgId': epgId,
      'featured': featured,
      'active': active,
      'order': order,
      'status': status,
    };
  }
}
