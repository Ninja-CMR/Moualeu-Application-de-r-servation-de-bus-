import 'package:cloud_firestore/cloud_firestore.dart';

class ReservationModel {
  final String id;
  final String userId;
  final String trajetId;
  final int seatNumber;
  final String status; // 'pending', 'confirmed', 'cancelled'
  final DateTime timestamp;

  ReservationModel({
    required this.id,
    required this.userId,
    required this.trajetId,
    required this.seatNumber,
    required this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'trajetId': trajetId,
      'seatNumber': seatNumber,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory ReservationModel.fromMap(String id, Map<String, dynamic> map) {
    return ReservationModel(
      id: id,
      userId: map['userId'] ?? '',
      trajetId: map['trajetId'] ?? '',
      seatNumber: map['seatNumber'] ?? 0,
      status: map['status'] ?? 'pending',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}
