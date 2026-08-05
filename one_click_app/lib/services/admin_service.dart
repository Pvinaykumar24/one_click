import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class AdminNotifier extends StreamNotifier<bool> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Stream<bool> build() {
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return Stream.value(false);
        }
        return FirebaseAuth.instance.idTokenChanges().asyncMap((fbUser) async {
          if (fbUser == null) return false;
          try {
            final tokenResult = await fbUser.getIdTokenResult();
            return tokenResult.claims?['admin'] == true;
          } catch (e) {
            debugPrint('Error checking admin custom claim: $e');
            return false;
          }
        });
      },
      loading: () => const Stream.empty(),
      error: (e, st) {
        debugPrint('Error checking admin token: $e');
        return Stream.value(false);
      },
    );
  }

  bool get isAdmin => state.valueOrNull ?? false;

  Future<void> wipeAllUserData() async {
    if (!isAdmin) {
      throw Exception('Unauthorized: Only administrators can wipe user data.');
    }

    try {
      debugPrint('Wiping all user data client-side (authorized via custom claims)...');
      
      final usersSnapshot = await _db.collection('users').get();
      final batch = _db.batch();

      for (var userDoc in usersSnapshot.docs) {
        final uid = userDoc.id;
        
        final subCollections = [
          'finances', 
          'cgpa', 
          'attendance', 
          'timetable', 
          'notifications',
          'assignments'
        ];
        
        for (var sub in subCollections) {
          final subSnap = await _db.collection('users').doc(uid).collection(sub).get();
          for (var doc in subSnap.docs) {
            batch.delete(doc.reference);
          }
        }
        
        batch.delete(userDoc.reference);
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error wiping data: $e');
      rethrow;
    }
  }
}

final adminProvider = StreamNotifierProvider<AdminNotifier, bool>(() {
  return AdminNotifier();
});
