import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream of auth state changes
  Stream<User?> get user => _auth.authStateChanges();

  // --- Phone Auth Methods ---

  // 1. Verify Phone Number
  Future<void> verifyPhone({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException e) onVerificationFailed,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onVerificationCompleted,
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (String verificationId) {},
      timeout: const Duration(seconds: 60),
    );
  }

  // 2. Sign In with OTP Credential
  Future<UserCredential> signInWithCredential(PhoneAuthCredential credential) async {
    try {
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print("Error signing in with phone: $e");
      rethrow;
    }
  }

  // --- Email/Password Auth Methods ---
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    String role = 'user', // Added role parameter
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create a user document in Firestore
      if (userCredential.user != null) {
        UserModel newUser = UserModel(
          uid: userCredential.user!.uid,
          fullName: fullName,
          email: email,
          phone: phone,
          role: role, // Pass the role
          createdAt: DateTime.now(),
        );

        await _db.collection('users').doc(userCredential.user!.uid).set(newUser.toMap());
      }

      return userCredential;
    } catch (e) {
      print("Error in signUp: $e");
      rethrow;
    }
  }

  // Sign in with Email and Password
  Future<UserCredential?> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      print("Error in signIn: $e");
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get current user details from Firestore
  Future<UserModel?> getCurrentUserDetails() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await _db.collection('users').doc(user.uid).get();
        if (doc.exists) {
          return UserModel.fromMap(doc.data() as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      print("Error fetching user details: $e");
      return null;
    }
  }

  // Get user data by UID
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print("Error fetching user data: $e");
      return null;
    }
  }
}
