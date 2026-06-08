import 'package:cloud_firestore/cloud_firestore.dart';

class AgencyModel {
  final String id;
  final String name;
  final String? logoUrl;

  AgencyModel({
    required this.id,
    required this.name,
    this.logoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'logoUrl': logoUrl,
    };
  }

  factory AgencyModel.fromMap(String id, Map<String, dynamic> map) {
    return AgencyModel(
      id: id,
      name: map['name'] ?? '',
      logoUrl: map['logoUrl'],
    );
  }
}
