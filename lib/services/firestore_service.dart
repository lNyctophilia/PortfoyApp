import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/portfolio.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  bool get isFirebaseAvailable => Firebase.apps.isNotEmpty;

  FirebaseFirestore? get _firestore {
    if (!isFirebaseAvailable) return null;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Kullanıcının Firestore'daki tüm portföylerini çeker.
  Future<List<Portfolio>> loadPortfolios(String uid) async {
    if (!isFirebaseAvailable || _firestore == null) {
      throw Exception('Firebase Firestore hazır değil.');
    }

    try {
      final snapshot = await _firestore!
          .collection('users')
          .doc(uid)
          .collection('portfolios')
          .get();

      if (snapshot.docs.isEmpty) {
        return [];
      }

      final List<Portfolio> portfolios = [];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          portfolios.add(Portfolio.fromJson(data));
        } catch (e) {
          debugPrint('Portföy çözümlenirken hata oluştu (${doc.id}): $e');
        }
      }
      return portfolios;
    } catch (e) {
      debugPrint('Firestore loadPortfolios Hatası: $e');
      rethrow;
    }
  }

  /// Tüm portföyleri topluca Firestore'a yazar ve silinenleri temizler.
  Future<void> savePortfolios(String uid, List<Portfolio> portfolios) async {
    if (!isFirebaseAvailable || _firestore == null) {
      return;
    }

    try {
      final userDocRef = _firestore!.collection('users').doc(uid);
      final portfoliosColRef = userDocRef.collection('portfolios');

      final batch = _firestore!.batch();

      // Mevcut bulut kayıtlarını sorgula (silinenleri temizlemek için)
      final existingDocs = await portfoliosColRef.get();
      final currentIds = portfolios.map((p) => p.id).toSet();

      for (final doc in existingDocs.docs) {
        if (!currentIds.contains(doc.id)) {
          batch.delete(doc.reference);
        }
      }

      // Yeni/güncellenmiş portföyleri yaz
      for (final portfolio in portfolios) {
        final docRef = portfoliosColRef.doc(portfolio.id);
        batch.set(docRef, portfolio.toJson(), SetOptions(merge: true));
      }

      // Kullanıcı kök belgesine son eşitleme zamanını kaydet
      batch.set(
        userDocRef,
        {
          'lastSyncAt': FieldValue.serverTimestamp(),
          'portfolioCount': portfolios.length,
        },
        SetOptions(merge: true),
      );

      await batch.commit();
    } catch (e) {
      debugPrint('Firestore savePortfolios Hatası: $e');
    }
  }

  /// Tek bir portföyü Firestore'a kaydeder / günceller.
  Future<void> saveSinglePortfolio(String uid, Portfolio portfolio) async {
    if (!isFirebaseAvailable || _firestore == null) return;

    try {
      await _firestore!
          .collection('users')
          .doc(uid)
          .collection('portfolios')
          .doc(portfolio.id)
          .set(portfolio.toJson(), SetOptions(merge: true));

      await _firestore!.collection('users').doc(uid).set({
        'lastSyncAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore saveSinglePortfolio Hatası: $e');
    }
  }

  /// Tek bir portföyü Firestore'dan siler.
  Future<void> deletePortfolio(String uid, String portfolioId) async {
    if (!isFirebaseAvailable || _firestore == null) return;

    try {
      await _firestore!
          .collection('users')
          .doc(uid)
          .collection('portfolios')
          .doc(portfolioId)
          .delete();

      await _firestore!.collection('users').doc(uid).set({
        'lastSyncAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore deletePortfolio Hatası: $e');
    }
  }

  /// Uygulama ayarlarını Firestore'a kaydeder.
  Future<void> saveSettings(String uid, Map<String, dynamic> settings) async {
    if (!isFirebaseAvailable || _firestore == null) return;

    try {
      await _firestore!.collection('users').doc(uid).set({
        'settings': settings,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore saveSettings Hatası: $e');
    }
  }

  /// Uygulama ayarlarını Firestore'dan çeker.
  Future<Map<String, dynamic>?> loadSettings(String uid) async {
    if (!isFirebaseAvailable || _firestore == null) return null;

    try {
      final doc = await _firestore!.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['settings'] as Map<String, dynamic>?;
      }
    } catch (e) {
      debugPrint('Firestore loadSettings Hatası: $e');
    }
    return null;
  }
}

