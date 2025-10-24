import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _profileComplete = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get profileComplete => _profileComplete;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      if (user != null) {
        await _checkProfileComplete();
      } else {
        _profileComplete = false;
      }
      notifyListeners();
    });
  }

  Future<void> _checkProfileComplete() async {
    if (_user == null) return;
    
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();
      
      _profileComplete = doc.exists && doc.data() != null && doc.data()!['firstName'] != null;
    } catch (e) {
      _profileComplete = false;
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'An error occurred during sign in';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUpWithEmailAndPassword(String email, String password, String name) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await result.user?.updateDisplayName(name);
    } on FirebaseAuthException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'An error occurred during sign up';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      // Check if this is a new user and handle accordingly
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        // New user - they'll be redirected to registration screen
        print('AuthProvider: New Google user signed in');
      } else {
        // Existing user - check if profile is complete
        print('AuthProvider: Existing Google user signed in');
        await _checkProfileComplete();
      }
    } on FirebaseAuthException catch (e) {
      print('AuthProvider: Firebase auth error: ${e.message}');
      _error = e.message;
    } catch (e) {
      print('AuthProvider: General error during Google sign in: $e');
      _error = 'An error occurred during Google sign in';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      _error = 'Error signing out';
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> markProfileComplete() async {
    print('AuthProvider: Marking profile as complete');
    _profileComplete = true;
    notifyListeners();
    print('AuthProvider: Profile completion status updated, notifying listeners');
  }

  Future<void> signOutAndReturnToLogin() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      _profileComplete = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error signing out';
      notifyListeners();
    }
  }
}