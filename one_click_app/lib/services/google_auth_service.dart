import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:http/http.dart' as http;

class GoogleSignInException implements Exception {
  final String message;
  final String code; // 'cancelled', 'network-error', 'unknown'
  final dynamic originalError;

  GoogleSignInException({
    required this.message,
    required this.code,
    this.originalError,
  });

  @override
  String toString() => message;
}

class AppUser {
  final String id;
  final String displayName;
  final String email;
  final String? photoUrl;

  AppUser({
    required this.id,
    required this.displayName,
    required this.email,
    this.photoUrl,
  });
}

class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? '681496090649-fi3bar761t1lif9jt5o86gi79jvkd2df.apps.googleusercontent.com' : null,
    scopes: [
      'email',
      'https://www.googleapis.com/auth/classroom.courses.readonly',
      'https://www.googleapis.com/auth/classroom.coursework.me.readonly',
      'https://www.googleapis.com/auth/classroom.student-submissions.me.readonly',
      'https://www.googleapis.com/auth/classroom.coursework.students.readonly',
    ],
  );

  /// Streams the current Firebase User state
  Stream<AppUser?> get userStream {
    return _auth.authStateChanges().map((User? user) {
      if (user != null) {
        return AppUser(
          id: user.uid,
          displayName: user.displayName ?? 'Student',
          email: user.email ?? '',
          photoUrl: user.photoURL,
        );
      }
      return null;
    });
  }

  Future<AppUser?> signIn() async {
    try {
      if (kIsWeb) {
        GoogleAuthProvider authProvider = GoogleAuthProvider();
        authProvider.addScope('https://www.googleapis.com/auth/classroom.courses.readonly');
        authProvider.addScope('https://www.googleapis.com/auth/classroom.coursework.me.readonly');
        
        if (kDebugMode) {
          debugPrint('Google Sign-In Origin: ${Uri.base.origin}');
        }
        
        try {
          final UserCredential userCredential = await _auth.signInWithPopup(authProvider);
          final User? user = userCredential.user;

          if (user != null) {
            return AppUser(
              id: user.uid,
              displayName: user.displayName ?? 'Student',
              email: user.email ?? '',
              photoUrl: user.photoURL,
            );
          }
        } catch (e) {
          debugPrint('🔥 [GSI POPUP ERROR] Sign in failed: $e');
          String code = 'unknown';
          String message = 'Google Sign-In failed.';
          if (e is FirebaseAuthException) {
            if (e.code == 'popup-closed-by-user' || e.code == 'cancelled') {
              code = 'cancelled';
              message = 'Sign-in was cancelled.';
            } else if (e.code == 'network-request-failed') {
              code = 'network-error';
              message = 'Network error occurred. Please check your connection.';
            } else {
              message = e.message ?? message;
            }
          }
          throw GoogleSignInException(message: message, code: code, originalError: e);
        }
        return null;
      } else {
        try {
          final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
          if (googleUser == null) {
            throw GoogleSignInException(
              message: 'Sign-in cancelled by user.',
              code: 'cancelled',
            );
          }
          
          final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
          final OAuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

          final UserCredential userCredential = await _auth.signInWithCredential(credential);
          final User? user = userCredential.user;

          if (user != null) {
            return AppUser(
              id: user.uid,
              displayName: user.displayName ?? 'Student',
              email: user.email ?? '',
              photoUrl: user.photoURL,
            );
          }
        } catch (e) {
          debugPrint('🔥 [AUTH ERROR] Sign-In Failed: $e');
          if (e is GoogleSignInException) {
            rethrow;
          }
          String code = 'unknown';
          String message = 'Google Sign-In failed.';
          if (e is PlatformException) {
            if (e.code == 'sign_in_canceled' || e.code == '12501') {
              code = 'cancelled';
              message = 'Sign-in was cancelled.';
            } else if (e.code == 'network_error' || e.code == '7') {
              code = 'network-error';
              message = 'Network error occurred. Please check your connection.';
            } else {
              message = e.message ?? message;
            }
          } else if (e is FirebaseAuthException) {
            if (e.code == 'network-request-failed') {
              code = 'network-error';
              message = 'Network error occurred.';
            } else {
              message = e.message ?? message;
            }
          }
          throw GoogleSignInException(message: message, code: code, originalError: e);
        }
        return null;
      }
    } catch (e) {
      if (e is GoogleSignInException) {
        rethrow;
      }
      throw GoogleSignInException(
        message: 'An unexpected error occurred during sign-in.',
        code: 'unknown',
        originalError: e,
      );
    }
  }

  Future<AppUser?> signInSilently() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        return AppUser(
          id: currentUser.uid,
          displayName: currentUser.displayName ?? 'Student',
          email: currentUser.email ?? '',
          photoUrl: currentUser.photoURL,
        );
      }
      return null;
    } catch (e, stack) {
      debugPrint('Error during silent sign in: $e\n$stack');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
      await _auth.signOut();
    } catch (e, stack) {
      debugPrint('Error during sign out: $e\n$stack');
    }
  }

  /// Returns an authenticated HTTP client for Google API calls
  Future<http.Client?> getAuthenticatedClient() async {
    // Ensure we are signed in silently first to populate currentUser in GoogleSignIn
    await _googleSignIn.signInSilently();
    return _googleSignIn.authenticatedClient();
  }
}
