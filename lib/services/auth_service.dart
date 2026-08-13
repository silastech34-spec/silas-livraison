import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../models/profile_model.dart';

class AuthService {
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String nom,
    required String telephone,
    required String role,
    String? whatsapp,
  }) async {
    final res = await supabase.auth.signUp(
      email: email.trim(),
      password: password,
    );

    if (res.user == null) {
      throw const AuthException(
        'Impossible de créer le compte.',
      );
    }

    try {
      await supabase.from('profiles').upsert(
        {
          'id': res.user!.id,
          'nom': nom.trim(),
          'telephone': telephone.trim(),
          'whatsapp': whatsapp,
          'role': role,
        },
        onConflict: 'id',
      );

      debugPrint(
        'Profil créé avec succès pour ${res.user!.id}',
      );
    } catch (e, st) {
      debugPrint('Erreur insertion profil: $e');
      debugPrint('$st');
      rethrow;
    }

    if (res.session == null) {
      debugPrint(
        'Compte créé mais aucune session. '
        'La confirmation email est probablement activée dans Supabase.',
      );
    }

    return res;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();

    if (cleanEmail.isEmpty) {
      throw const AuthException('Veuillez saisir votre email.');
    }

    if (password.isEmpty) {
      throw const AuthException('Veuillez saisir votre mot de passe.');
    }

    debugPrint('Tentative de connexion : $cleanEmail');

    final response = await supabase.auth.signInWithPassword(
      email: cleanEmail,
      password: password,
    );

    if (response.user == null || response.session == null) {
      throw const AuthException(
        'Connexion impossible : aucune session Supabase.',
      );
    }

    debugPrint(
      'Connexion réussie : ${response.user!.id}',
    );

    return response;
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  User? get currentUser => supabase.auth.currentUser;

  Future<ProfileModel?> getCurrentProfile() async {
    final user = currentUser;

    if (user == null) {
      debugPrint('getCurrentProfile : aucun utilisateur connecté.');
      return null;
    }

    try {
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) {
        debugPrint(
          'Profil introuvable pour ${user.id}.',
        );
        return null;
      }

      debugPrint(
        'Profil trouvé : ${data['role']}',
      );

      return ProfileModel.fromJson(data);
    } catch (e, st) {
      debugPrint('Erreur getCurrentProfile : $e');
      debugPrint('$st');
      rethrow;
    }
  }

  Stream<AuthState> get authStateChanges {
    return supabase.auth.onAuthStateChange;
  }
}
