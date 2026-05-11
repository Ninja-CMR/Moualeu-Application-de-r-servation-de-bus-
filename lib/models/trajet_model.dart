import 'package:cloud_firestore/cloud_firestore.dart';

class TrajetModel {
  final String id;
  final String departure;
  final String destination;
  final DateTime departureTime;
  final double price;

  TrajetModel({
    required this.id,
    required this.departure,
    required this.destination,
    required this.departureTime,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'departure': departure,
      'destination': destination,
      'departureTime': Timestamp.fromDate(departureTime),
      'price': price,
    };
  }

  factory TrajetModel.fromMap(String id, Map<String, dynamic> map) {
    return TrajetModel(
      id: id,
      departure: map['departure'] ?? '',
      destination: map['destination'] ?? '',
      departureTime: (map['departureTime'] as Timestamp).toDate(),
      price: (map['price'] ?? 0).toDouble(),
    );
  }
}
