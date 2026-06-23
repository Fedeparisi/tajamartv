import 'package:equatable/equatable.dart';

class EpgEntity extends Equatable {
  final String id;
  final String channelEpgId; // ID del canal en la guía
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String category;

  const EpgEntity({
    required this.id,
    required this.channelEpgId,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.category,
  });

  @override
  List<Object?> get props => [id, channelEpgId, title, description, startTime, endTime, category];
}
