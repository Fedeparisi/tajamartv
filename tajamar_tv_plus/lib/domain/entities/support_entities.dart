import 'package:equatable/equatable.dart';

class TicketEntity extends Equatable {
  final String id;
  final String userId;
  final String companyId;
  final String category; // Técnico, Comercial, Facturación
  final String status; // open, in_progress, resolved, closed
  final String subject;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TicketEntity({
    required this.id,
    required this.userId,
    required this.companyId,
    required this.category,
    required this.status,
    required this.subject,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, userId, companyId, category, status, subject, createdAt, updatedAt];
}

class MessageEntity extends Equatable {
  final String id;
  final String ticketId;
  final String senderId; // ID del usuario o admin
  final String content;
  final DateTime timestamp;
  final bool isAdmin;

  const MessageEntity({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.content,
    required this.timestamp,
    required this.isAdmin,
  });

  @override
  List<Object?> get props => [id, ticketId, senderId, content, timestamp, isAdmin];
}
