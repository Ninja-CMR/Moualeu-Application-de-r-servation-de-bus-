import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';
import '../models/trajet_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import '../utils/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();
  UserModel? _currentUser;
  bool _isLoading = true;

  final TextEditingController _departureController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  Stream<List<TrajetModel>>? _tripsStream;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _searchTrips(); // Load default or empty search
  }

  void _loadUserInfo() async {
    _currentUser = await _authService.getCurrentUserDetails();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _searchTrips() {
    setState(() {
      _tripsStream = _dbService.searchTrips(
        departure: _departureController.text.trim(),
        destination: _destinationController.text.trim(),
        maxPrice: double.tryParse(_priceController.text),
      );
    });
  }

  void _bookTrip(TrajetModel trajet) async {
    if (_currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      // Pour cet exemple, on attribue le siège numéro 1 (ou basé sur availableSeats)
      await _dbService.createReservation(
        uid: _currentUser!.uid,
        trajetId: trajet.id,
        seatNumber: trajet.totalSeats - trajet.availableSeats + 1,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Réservation réussie !"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _signOut() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.lightBlue.shade50.withOpacity(0.3),
              Colors.white,
              Colors.blue.shade50.withOpacity(0.5),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        'BIENVENUE ${_currentUser?.fullName.toUpperCase() ?? ""}',
                        style: const TextStyle(
                          color: Color(0xFFBCAAA4),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Où allez-vous\naujourd\'hui ?',
                        style: TextStyle(
                          color: Color(0xFF0D47A1),
                          fontWeight: FontWeight.bold,
                          fontSize: 34,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 25),
                      _buildSearchForm(),
                      const SizedBox(height: 25),
                      const Text(
                        "Trajets disponibles",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 15),
                      _buildTripsList(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }



  Widget _buildSearchForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          _buildCityAutocomplete(_departureController, "Départ", Icons.location_on_outlined),
          const SizedBox(height: 10),
          _buildCityAutocomplete(_destinationController, "Arrivée", Icons.location_on),
          const SizedBox(height: 10),
          TextField(
            controller: _priceController,
            decoration: const InputDecoration(hintText: "Prix Max", prefixIcon: Icon(Icons.money)),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _searchTrips,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1)),
              child: const Text("Rechercher", style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCityAutocomplete(TextEditingController controller, String hint, IconData icon) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') {
          return const Iterable<String>.empty();
        }
        return AppConstants.cameroonCities.where((String option) {
          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selection) {
        controller.text = selection;
      },
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        // Synchronize our controller with the Autocomplete internal controller
        textController.text = controller.text;
        textController.addListener(() {
          controller.text = textController.text;
        });
        
        return TextField(
          controller: textController,
          focusNode: focusNode,
          onSubmitted: (value) => onFieldSubmitted(),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
          ),
        );
      },
    );
  }

  Widget _buildTripsList() {
    return StreamBuilder<List<TrajetModel>>(
      stream: _tripsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final trips = snapshot.data!;
        if (trips.isEmpty) return const Text("Aucun trajet trouvé.");

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: trips.length,
          itemBuilder: (context, index) {
            final trip = trips[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                leading: const Icon(Icons.directions_bus, size: 40, color: Color(0xFF0D47A1)),
                title: Text("${trip.departure} -> ${trip.destination}"),
                subtitle: Text("${trip.agencyName} - ${trip.availableSeats} places libres"),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("${trip.price} FCFA", style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    ElevatedButton(
                      onPressed: () => _bookTrip(trip),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0)),
                      child: const Text("Réserver", style: TextStyle(fontSize: 12)),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF0D47A1), size: 28),
            onPressed: _signOut,
          ),
          const Text(
            'MOUALEU',
            style: TextStyle(
              color: Color(0xFF0D47A1),
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: 1.2,
            ),
          ),
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 20,
              backgroundImage: const NetworkImage('https://i.pravatar.cc/150?img=11'),
              child: _isLoading ? const CircularProgressIndicator(strokeWidth: 2) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      height: 100,
      padding: const EdgeInsets.only(bottom: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home_rounded, 'ACCUEIL', true),
          _buildNavItem(Icons.confirmation_number_outlined, 'MES BILLETS', false),
          _buildNavItem(Icons.stars_outlined, 'POINTS', false),
          _buildNavItem(Icons.person_outline, 'PROFIL', false),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF0D47A1) : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.white : Colors.grey.shade400,
            size: 26,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFF0D47A1) : Colors.grey.shade400,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
