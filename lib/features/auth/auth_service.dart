import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Google Sign-In
  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
        // Fallback for Windows/Web testing (Not primary target, but crash prevention)
        debugPrint(
          "Google Sign-In: Windows/Web detected. Using manual provider flow implicitly or not supported fully without setup.",
        );
        // For simple mobile-only focus, we might just return null or show error if run on Windows.
        // But to be safe vs crash:
        if (defaultTargetPlatform == TargetPlatform.windows) {
          throw "Google Sign-In is not configured for Windows in this mobile-first app. Please run on Android/iOS Emulator.";
        }
      }

      final GoogleSignIn googleSignIn = GoogleSignIn();

      // Explicitly sign out to force account selector, useful for testing
      // await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint("Google Sign-In canceled by user.");
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuth Error: ${e.message} (${e.code})');
      if (e.code == 'account-exists-with-different-credential') {
        throw 'Account exists with different credential.';
      } else if (e.code == 'invalid-credential') {
        throw 'Invalid credential. Check SHA-1 fingerprint in Firebase Console.';
      }
      rethrow;
    } catch (e) {
      debugPrint('Google Sign-In General Error: $e');
      if (e.toString().contains('PlatformException(sign_in_failed')) {
        throw 'Sign-In Failed. \nPossible causes:\n1. SHA-1 fingerprint missing in Firebase Console.\n2. Google Play Services missing on Emulator.\n3. applicationId mismatch.';
      }
      rethrow;
    }
  }

  // Apple Sign-In
  // Apple Sign-In
  Future<User?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final OAuthCredential credential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      return userCredential.user;
    } catch (e) {
      debugPrint("Apple Sign-In Error: $e");
      // Handle cancellation or error
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
