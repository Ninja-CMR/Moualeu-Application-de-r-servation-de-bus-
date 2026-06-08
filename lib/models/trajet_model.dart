import 'package:cloud_firestore/cloud_firestore.dart';

class TrajetModel {
  final String id;
  final String departure;
  final String destination;
  final DateTime departureTime;
  final double price;
  final int totalSeats;
  final int availableSeats;
  final String agencyId;
  final String agencyName;
  final String? busImageUrl;

  TrajetModel({
    required this.id,
    required this.departure,
    required this.destination,
    required this.departureTime,
    required this.price,
    required this.totalSeats,
    required this.availableSeats,
    required this.agencyId,
    required this.agencyName,
    this.busImageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'departure': departure,
      'destination': destination,
      'departureTime': Timestamp.fromDate(departureTime),
      'price': price,
      'totalSeats': totalSeats,
      'availableSeats': availableSeats,
      'agencyId': agencyId,
      'agencyName': agencyName,
      'busImageUrl': busImageUrl,
    };
  }

  factory TrajetModel.fromMap(String id, Map<String, dynamic> map) {
    return TrajetModel(
      id: id,
      departure: map['departure'] ?? '',
      destination: map['destination'] ?? '',
      departureTime: (map['departureTime'] as Timestamp).toDate(),
      price: (map['price'] ?? 0).toDouble(),
      totalSeats: map['totalSeats'] ?? 0,
      availableSeats: map['availableSeats'] ?? 0,
      agencyId: map['agencyId'] ?? '',
      agencyName: map['agencyName'] ?? '',
      busImageUrl: map['busImageUrl'],
    );
  }
}
