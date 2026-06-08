import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pinput/pinput.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';

class VerificationScreen extends StatefulWidget {
  final String verificationId;
  final String fullName;
  final String email;
  final String phone;
  final String password;

  const VerificationScreen({
    super.key,
    required this.verificationId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _pinController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  
  // Timer for resending code
  int _secondsRemaining = 30;
  bool _canResend = false;
  Timer? _timer;
  late String _currentVerificationId;

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 30;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _resendCode() async {
    if (!_canResend) return;

    setState(() => _isLoading = true);
    try {
      await _authService.verifyPhone(
        phoneNumber: widget.phone,
        onCodeSent: (verificationId, resendToken) {
          setState(() {
            _currentVerificationId = verificationId;
            _isLoading = false;
          });
          _startTimer();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Code renvoyé !")),
          );
        },
        onVerificationFailed: (e) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Échec du renvoi: ${e.message}")),
          );
        },
        onVerificationCompleted: (credential) async {
          await _authService.signInWithCredential(credential);
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          }
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: ${e.toString()}")),
      );
    }
  }

  void _verifyOTP() async {
    if (_pinController.text.length < 6) return;

    setState(() => _isLoading = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _currentVerificationId,
        smsCode: _pinController.text,
      );

      // Sign in the user
      UserCredential userCredential = await _authService.signInWithCredential(credential);

      // Create the user document in Firestore (since it's a first-time signup)
      if (userCredential.user != null) {
        UserModel newUser = UserModel(
          uid: userCredential.user!.uid,
          fullName: widget.fullName,
          email: widget.email,
          phone: widget.phone,
          role: 'user',
          createdAt: DateTime.now(),
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(newUser.toMap());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Compte créé et vérifié avec succès !"), backgroundColor: Colors.green),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur de vérification: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(fontSize: 20, color: Color(0xFF0D47A1), fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0D47A1)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Verification',
          style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blueGrey.shade100.withOpacity(0.6),
              Colors.lightBlue.shade50.withOpacity(0.4),
              Colors.orangeAccent.shade100.withOpacity(0.1),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const Text(
                  'Vérifiez votre\ncompte',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.2),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.message, color: Colors.green, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: 'Nous vous avons envoyé un code de vérification à 6 chiffres au ',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                            children: [
                              TextSpan(
                                text: widget.phone,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Center(
                  child: Pinput(
                    length: 6,
                    controller: _pinController,
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: defaultPinTheme.copyDecorationWith(
                      border: Border.all(color: const Color(0xFF0D47A1), width: 2),
                    ),
                    onCompleted: (pin) => _verifyOTP(),
                  ),
                ),
                const SizedBox(height: 40),
                Center(
                  child: GestureDetector(
                    onTap: _canResend ? _resendCode : null,
                    child: Text.rich(
                      TextSpan(
                        text: "Vous n'avez pas reçu le code ? ",
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                        children: [
                          TextSpan(
                            text: _canResend ? 'Renvoyer' : 'Attendez ${_secondsRemaining}s',
                            style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              color: _canResend ? const Color(0xFF1565C0) : Colors.grey
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text('Vérifier et continuer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                            ],
                          ),
                  ),
                ),
                const Spacer(),
                Center(
                  child: Text(
                    'En continuant, vous acceptez de recevoir des\nmessages automatisés pour la sécurisation de\nvotre compte.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500, height: 1.3),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
