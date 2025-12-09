import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'dart:typed_data';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  User? getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }

  /// Encode l'email pour l'utiliser comme clé Firebase
  String _encodeEmail(String email) {
    return email
        .toLowerCase()  // ← IMPORTANT : normaliser en minuscules
        .replaceAll('.', ',')
        .replaceAll('@', '_at_')
        .replaceAll('#', '_hash_')
        .replaceAll('\$', '_dollar_')
        .replaceAll('[', '_')
        .replaceAll(']', '_');
  }

  Future<String> signUpUser({
    required String email,
    required String password,
    required String username,
    Uint8List? profileImage,
  }) async {
    String res = "Some error occurred";

    try {
      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');

      if (email.isNotEmpty && password.isNotEmpty && username.isNotEmpty) {
        if (!emailRegex.hasMatch(email)) {
          return "Email invalide";
        }

        // Normaliser l'email en minuscules
        final normalizedEmail = email.toLowerCase();

        // Auth Firebase
        UserCredential cred = await _auth.createUserWithEmailAndPassword(
          email: normalizedEmail,
          password: password,
        );

        // Convertir image en base64
        String? base64Image = profileImage != null
            ? base64Encode(profileImage)
            : null;

        // Encoder l'email pour l'utiliser comme clé
        String encodedEmail = _encodeEmail(normalizedEmail);

        // Enregistrer dans RealTime Database
        await _db.child("users").child(encodedEmail).set({
          "username": username,
          "email": normalizedEmail,  // Email normalisé
          "uid": cred.user!.uid,
          "photoBase64": base64Image,
        });

        res = "success";
      } else {
        res = "Rentrer tous les champs";
      }
    } catch (e) {
      res = e.toString();
    }

    return res;
  }

  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    String res = "Some error occurred";

    try {
      if (email.isNotEmpty && password.isNotEmpty) {
        // Normaliser l'email
        final normalizedEmail = email.toLowerCase();
        
        await _auth.signInWithEmailAndPassword(
          email: normalizedEmail,
          password: password,
        );
        res = "success";
      } else {
        res = "Rentrer tous les champs";
      }
    } catch (e) {
      res = e.toString();
    }

    return res;
  }

  Future<String> logoutUser() async {
    String res = "Some error occurred";

    try {
      await _auth.signOut();
      res = "success";
    } catch (e) {
      res = e.toString();
    }

    return res;
  }
}