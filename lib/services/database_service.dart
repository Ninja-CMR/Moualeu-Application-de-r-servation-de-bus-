import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/agency_model.dart';
import '../models/trajet_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Admin Methods ---

  // Add a new agency
  Future<void> addAgency(AgencyModel agency) async {
    await _db.collection('agencies').doc(agency.id).set(agency.toMap());
  }

  // Get all agencies
  Stream<List<AgencyModel>> get agencies {
    return _db.collection('agencies').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => AgencyModel.fromMap(doc.id, doc.data())).toList();
    });
  }

  // Create a new trip (admin only)
  Future<void> createTrajet(TrajetModel trajet) async {
    try {
      await _db.collection('trajets').add(trajet.toMap());
    } catch (e) {
      print("Error creating trajet: $e");
      rethrow;
    }
  }

  // --- User Methods ---

  // Search trips with filters
  Stream<List<TrajetModel>> searchTrips({
    String? departure,
    String? destination,
    double? maxPrice,
  }) {
    Query query = _db.collection('trajets');

    if (departure != null && departure.isNotEmpty) {
      query = query.where('departure', isEqualTo: departure);
    }
    if (destination != null && destination.isNotEmpty) {
      query = query.where('destination', isEqualTo: destination);
    }
    if (maxPrice != null) {
      query = query.where('price', isLessThanOrEqualTo: maxPrice);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return TrajetModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Transactional Reservation
  Future<void> createReservation({
    required String uid,
    required String trajetId,
    required int seatNumber,
  }) async {
    return _db.runTransaction((transaction) async {
      DocumentReference trajetRef = _db.collection('trajets').doc(trajetId);
      DocumentSnapshot trajetSnapshot = await transaction.get(trajetRef);

      if (!trajetSnapshot.exists) {
        throw Exception("Le trajet n'existe pas");
      }

      int availableSeats = trajetSnapshot['availableSeats'] ?? 0;

      if (availableSeats <= 0) {
        throw Exception("Plus de places disponibles");
      }

      // 1. Update available seats
      transaction.update(trajetRef, {'availableSeats': availableSeats - 1});

      // 2. Create reservation document
      DocumentReference reservationRef = _db.collection('reservations').doc();
      transaction.set(reservationRef, {
        'userId': uid,
        'trajetId': trajetId,
        'seatNumber': seatNumber,
        'status': 'confirmed',
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }

  // Get all trips
  Stream<List<TrajetModel>> get trajets {
    return _db.collection('trajets').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return TrajetModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // --- Initialization / Seeding ---

  // Helper to initialize the database with some sample data
  Future<void> initializeDatabase() async {
    try {
      // 1. Create a sample agency
      String agencyId = _db.collection('agencies').doc().id;
      AgencyModel sampleAgency = AgencyModel(
        id: agencyId,
        name: "Moualeu Express",
        logoUrl: "https://example.com/logo.png",
      );
      await addAgency(sampleAgency);

      // 2. Create a sample trip
      TrajetModel sampleTrajet = TrajetModel(
        id: '', 
        departure: "Douala",
        destination: "Yaoundé",
        departureTime: DateTime.now().add(const Duration(days: 1)),
        price: 5000.0,
        totalSeats: 70,
        availableSeats: 70,
        agencyId: agencyId,
        agencyName: sampleAgency.name,
      );
      await createTrajet(sampleTrajet);
      
      print("Database initialized successfully");
    } catch (e) {
      print("Error initializing database: $e");
      rethrow;
    }
  }
}
