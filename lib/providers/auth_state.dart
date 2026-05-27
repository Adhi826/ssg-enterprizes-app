import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthState {
  final bool isAuthenticated;
  final String userEmail;
  final String userName;
  final String profileImageUrl;
  final String languageCode;

  AuthState({
    required this.isAuthenticated,
    required this.userEmail,
    required this.userName,
    this.profileImageUrl = '',
    required this.languageCode,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? userEmail,
    String? userName,
    String? profileImageUrl,
    String? languageCode,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      languageCode: languageCode ?? this.languageCode,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState(isAuthenticated: false, userEmail: '', userName: '', profileImageUrl: '', languageCode: 'en')) {
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final userEmail = prefs.getString('userEmail') ?? '';
    final userName = prefs.getString('userName') ?? '';
    final profileImageUrl = prefs.getString('profileImageUrl') ?? '';
    final languageCode = prefs.getString('languageCode') ?? 'en';
    
    state = AuthState(
      isAuthenticated: isLoggedIn,
      userEmail: userEmail,
      userName: userName,
      profileImageUrl: profileImageUrl,
      languageCode: languageCode,
    );
  }

  Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        return false; // User cancelled account selection
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;
      
      if (user != null) {
        final name = user.displayName ?? 'Sri Siva Gayathri User';
        final email = user.email ?? '';
        final photoUrl = user.photoURL ?? '';
        
        // Save user data to Firestore
        try {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'name': name,
            'email': email,
            'profileImage': photoUrl,
            'lastLogin': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (e) {
          print("Error saving user to Firestore: $e");
        }
        
        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userEmail', email);
        await prefs.setString('userName', name);
        await prefs.setString('profileImageUrl', photoUrl);
        
        state = AuthState(
          isAuthenticated: true,
          userEmail: email,
          userName: name,
          profileImageUrl: photoUrl,
          languageCode: state.languageCode,
        );
        return true;
      }
    } catch (e) {
      print("Google Sign-In failed: $e");
    }
    return false;
  }

  Future<void> logout() async {
    try {
      await GoogleSignIn().signOut();
    } catch (e) {
      print("Google signout error: $e");
    }
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print("Firebase signout error: $e");
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('userEmail');
    await prefs.remove('userName');
    await prefs.remove('profileImageUrl');

    state = AuthState(
      isAuthenticated: false,
      userEmail: '',
      userName: '',
      profileImageUrl: '',
      languageCode: state.languageCode,
    );
  }

  Future<void> setLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', code);
    state = state.copyWith(languageCode: code);
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
