import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/institution.dart';
import '../providers/auth_provider.dart';
import 'onboarding_service.dart';

class InstitutionNotifier extends StreamNotifier<Institution?> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<Institution?> build() {
    final authState = ref.watch(authProvider);
    final onboardingState = ref.watch(onboardingProvider).valueOrNull;

    return authState.when(
      data: (user) {
        if (user == null) {
          return Stream.value(null);
        }

        final collegeId = onboardingState?.userData['collegeId'] as String?;

        if (collegeId == null || collegeId.isEmpty) {
          return Stream.value(null);
        }

        return _firestore
            .collection('institutions')
            .doc(collegeId)
            .snapshots()
            .map((doc) {
          if (doc.exists) {
            return Institution.fromFirestore(doc);
          }
          return null;
        });
      },
      loading: () => const Stream.empty(),
      error: (e, st) {
        debugPrint('Error loading institution stream: $e');
        return Stream.value(null);
      },
    );
  }
}

final institutionProvider =
    StreamNotifierProvider<InstitutionNotifier, Institution?>(() {
  return InstitutionNotifier();
});
