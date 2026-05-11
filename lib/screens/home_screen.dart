import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  void _loadUserInfo() async {
    _currentUser = await _authService.getCurrentUserDetails();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleReservation() async {
    if (_currentUser == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Traitement de votre réservation...")),
    );

    try {
      // Pour le MVP, on crée un trajet fictif s'il n'en existe pas ou on réserve un trajet par défaut
      await _dbService.createReservation(
        uid: _currentUser!.uid,
        trajetId: "trajet_mvp_default", // ID fictif pour le MVP
        reservationDate: DateTime.now(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Réservation réussie !"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de la réservation: ${e.toString()}")),
        );
      }
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
                      const Text(
                        'BIENVENUE',
                        style: TextStyle(
                          color: Color(0xFFBCAAA4), // Soft Gold/Brown
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Voyagez depuis\nvotre quartier',
                        style: TextStyle(
                          color: const Color(0xFF0D47A1), // Deep Blue
                          fontWeight: FontWeight.bold,
                          fontSize: 34,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 25),
                      _buildMainIllustration(),
                      const SizedBox(height: 35),
                      _buildActionButtons(),
                      const SizedBox(height: 35),
                      _buildInfoCards(),
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

  Widget _buildMainIllustration() {
    return Center(
      child: Container(
        height: 280,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            'assets/homeImage.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _buildButton(
          text: 'Réserver un trajet',
          iconPath: 'assets/icon/reservationIcon.png',
          color: const Color(0xFF1565C0), // Primary Blue
          textColor: Colors.white,
          isFilled: true,
          onTap: _handleReservation,
        ),
        const SizedBox(height: 16),
        _buildButton(
          text: 'Voir mes réservations',
          iconPath: 'assets/icon/voirreservations.png',
          color: const Color(0xFFECEFF1), // Light Blue Grey
          textColor: const Color(0xFF1565C0),
          isFilled: false,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Bientôt disponible dans la prochaine version")),
            );
          },
        ),
      ],
    );
  }

  Widget _buildButton({
    required String text,
    required String iconPath,
    required Color color,
    required Color textColor,
    required bool isFilled,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      height: 65,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(35),
        boxShadow: isFilled
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                )
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(35),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                iconPath,
                height: 22,
                color: textColor,
              ),
              const SizedBox(width: 12),
              Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCards() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            title: 'STATUS',
            value: 'Actif',
            icon: Icons.bolt,
            iconColor: Colors.orange.shade400,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildInfoCard(
            title: 'POINTS',
            value: '1,240',
            icon: Icons.stars,
            iconColor: const Color(0xFF1565C0),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 15),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.w900,
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
