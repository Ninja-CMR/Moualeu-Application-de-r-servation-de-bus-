import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trajet_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create a new trip (trajet)
  Future<void> createTrajet(TrajetModel trajet) async {
    try {
      await _db.collection('trajets').add(trajet.toMap());
    } catch (e) {
      print("Error creating trajet: $e");
      rethrow;
    }
  }

  // Get all trips
  Stream<List<TrajetModel>> get trajets {
    return _db.collection('trajets').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return TrajetModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Create a reservation (MVP: just adding to a collection or linking user to trip)
  // For now, let's keep it simple: a collection 'reservations'
  Future<void> createReservation({
    required String uid,
    required String trajetId,
    required DateTime reservationDate,
  }) async {
    try {
      await _db.collection('reservations').add({
        'uid': uid,
        'trajetId': trajetId,
        'reservationDate': Timestamp.fromDate(reservationDate),
        'status': 'confirmed',
      });
    } catch (e) {
      print("Error creating reservation: $e");
      rethrow;
    }
  }
}
