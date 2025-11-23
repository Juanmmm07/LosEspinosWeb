import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseUser {
  final String id;
  final String name;
  final String email;
  final String? photoURL;
  final bool isAdmin;

  FirebaseUser({
    required this.id,
    required this.name,
    required this.email,
    this.photoURL,
    this.isAdmin = false,
  });
}

class FirebaseAuthService extends ChangeNotifier {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb 
        ? '572940136466-cfqqbduaia4u067uocb1e02ngeq0qrdd.apps.googleusercontent.com' // Tu Web Client ID
        : null,
  );
  
  FirebaseUser? _currentUser;
  bool _isInitialized = false;

  final List<String> _adminEmails = [
    'admin@losespinos.com',
    'juan.rodriguez16@estudiantesunibague.edu.co',
    'carlos.rincon@estudiantesunibague.edu.co',
    'jonathan.fonsecan@estudiantesunibague.edu.co'
  ];

  FirebaseUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    _auth.authStateChanges().listen((fb.User? user) {
      if (user != null) {
        _currentUser = FirebaseUser(
          id: user.uid,
          name: user.displayName ?? 'Usuario',
          email: user.email ?? '',
          photoURL: user.photoURL,
          isAdmin: _adminEmails.contains(user.email?.toLowerCase()),
        );
      } else {
        _currentUser = null;
      }
      notifyListeners();
    });

    final user = _auth.currentUser;
    if (user != null) {
      _currentUser = FirebaseUser(
        id: user.uid,
        name: user.displayName ?? 'Usuario',
        email: user.email ?? '',
        photoURL: user.photoURL,
        isAdmin: _adminEmails.contains(user.email?.toLowerCase()),
      );
    }

    _isInitialized = true;
    notifyListeners();
  }

  // Método actualizado para Web y Mobile
  Future<bool> signInWithGoogle() async {
    try {
      fb.UserCredential userCredential;

      if (kIsWeb) {
        // Para WEB: usar signInWithPopup
        final googleProvider = fb.GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        // Para MOBILE: usar GoogleSignIn
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        
        if (googleUser == null) {
          return false;
        }

        final GoogleSignInAuthentication googleAuth = 
            await googleUser.authentication;

        final credential = fb.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
      }

      final user = userCredential.user;

      if (user != null) {
        _currentUser = FirebaseUser(
          id: user.uid,
          name: user.displayName ?? 'Usuario',
          email: user.email ?? '',
          photoURL: user.photoURL,
          isAdmin: _adminEmails.contains(user.email?.toLowerCase()),
        );
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      print('Error en signInWithGoogle: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
      await _auth.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      print('Error en logout: $e');
    }
  }

  bool isEmailAdmin(String email) {
    return _adminEmails.contains(email.toLowerCase());
  }

  void addAdminEmail(String email) {
    if (!_adminEmails.contains(email.toLowerCase())) {
      _adminEmails.add(email.toLowerCase());
    }
  }
  
}