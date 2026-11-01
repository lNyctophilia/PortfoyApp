import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  bool get isFirebaseAvailable => Firebase.apps.isNotEmpty;

  FirebaseAuth? get _auth {
    if (!isFirebaseAvailable) return null;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  Stream<User?> get authStateChanges {
    if (!isFirebaseAvailable || _auth == null) {
      return Stream.value(null);
    }
    return _auth!.authStateChanges();
  }

  User? get currentUser {
    if (!isFirebaseAvailable) return null;
    return _auth?.currentUser;
  }

  bool get isSignedIn => currentUser != null;

  Future<UserCredential?> signInWithGoogle() async {
    if (!isFirebaseAvailable || _auth == null) {
      throw Exception(
        'Firebase henüz başlatılmadı. Lütfen Firebase kurulum adımlarını tamamlayın.',
      );
    }

    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        return await _auth!.signInWithPopup(googleProvider);
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // Kullanıcı giriş penceresini kapattı / vazgeçti
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth!.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Google Sign-In Hatası: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      debugPrint('Google Sign-Out Hatası: $e');
    }

    try {
      if (isFirebaseAvailable && _auth != null) {
        await _auth!.signOut();
      }
    } catch (e) {
      debugPrint('FirebaseAuth Sign-Out Hatası: $e');
    }
  }
}

