import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class OnboardingState {
  final bool hasCompletedOnboarding;
  final Map<String, dynamic> userData;
  final bool isLoading;

  OnboardingState({
    required this.hasCompletedOnboarding,
    required this.userData,
    required this.isLoading,
  });

  OnboardingState copyWith({
    bool? hasCompletedOnboarding,
    Map<String, dynamic>? userData,
    bool? isLoading,
  }) {
    return OnboardingState(
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      userData: userData ?? this.userData,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class OnboardingNotifier extends StreamNotifier<OnboardingState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<OnboardingState> build() {
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return Stream.value(OnboardingState(
            hasCompletedOnboarding: false,
            userData: {},
            isLoading: false,
          ));
        }

        return _firestore
            .collection('users')
            .doc(user.id)
            .snapshots()
            .map((doc) {
          if (doc.exists) {
            final data = doc.data() ?? {};
            return OnboardingState(
              hasCompletedOnboarding: data['hasCompletedOnboarding'] ?? false,
              userData: data,
              isLoading: false,
            );
          } else {
            return OnboardingState(
              hasCompletedOnboarding: false,
              userData: {'department': 'CSE'},
              isLoading: false,
            );
          }
        });
      },
      loading: () => Stream.value(OnboardingState(
        hasCompletedOnboarding: false,
        userData: {},
        isLoading: true,
      )),
      error: (e, st) {
        debugPrint("AUTH ERROR: Failed to fetch user data: $e");
        return Stream.value(OnboardingState(
          hasCompletedOnboarding: false,
          userData: {'department': 'CSE'},
          isLoading: false,
        ));
      },
    );
  }

  OnboardingState get currentState => state.valueOrNull ?? OnboardingState(
    hasCompletedOnboarding: false,
    userData: {},
    isLoading: false,
  );

  Future<void> completeOnboarding(Map<String, dynamic> userData) async {
    final user = FirebaseAuth.instance.currentUser;
    state = AsyncValue.data(OnboardingState(
      hasCompletedOnboarding: true,
      userData: {...userData, 'hasCompletedOnboarding': true},
      isLoading: false,
    ));

    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).set({
          ...userData,
          'hasCompletedOnboarding': true,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint("AUTH: Onboarding completed and saved to Firestore");
      } catch (e) {
        debugPrint("AUTH ERROR: Failed to save onboarding data to Firestore: $e");
      }
    }
  }
}

final onboardingProvider = StreamNotifierProvider<OnboardingNotifier, OnboardingState>(() {
  return OnboardingNotifier();
});