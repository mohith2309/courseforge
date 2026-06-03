import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleUser {
  final String uid;
  final String name;
  final String? email;
  final String? photoUrl;
  final String? idToken;
  const GoogleUser({
    required this.uid,
    required this.name,
    this.email,
    this.photoUrl,
    this.idToken,
  });
}

/// "Sign in with Google", backed by Firebase Auth on the dittoc-5a839 project.
/// The web client id is the serverClientId so the returned idToken is minted
/// for Firebase. Returns null if the user cancels.
class GoogleAuthService {
  static const _webClientId =
      '374206849691-kq29tkl0mrtrp59p8i998bvj4tb0qedp.apps.googleusercontent.com';

  final GoogleSignIn _google =
      GoogleSignIn(serverClientId: _webClientId, scopes: const ['email']);

  Future<GoogleUser?> signIn() async {
    final account = await _google.signIn();
    if (account == null) return null; // cancelled

    final gauth = await account.authentication;
    final cred = GoogleAuthProvider.credential(
      idToken: gauth.idToken,
      accessToken: gauth.accessToken,
    );
    final result = await FirebaseAuth.instance.signInWithCredential(cred);
    final u = result.user!;
    return GoogleUser(
      uid: u.uid,
      name: u.displayName ?? account.displayName ?? account.email.split('@').first,
      email: u.email ?? account.email,
      photoUrl: u.photoURL ?? account.photoUrl,
      idToken: await u.getIdToken(),
    );
  }

  Future<void> signOut() async {
    await _google.signOut();
    await FirebaseAuth.instance.signOut();
  }
}
