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
    required String role, // client | livreur
    String? whatsapp,
  }) async {
    final res = await supabase.auth.signUp(email: email, password: password);

    if (res.user != null) {
      try {
        await supabase.from('profiles').insert({
          'id': res.user!.id,
          'nom': nom,
          'telephone': telephone,
          'whatsapp': whatsapp,
          'role': role,
        });
      } catch (e, st) {
        debugPrint('Erreur insertion profil: $e\n$st');
        // On relance pour que l'UI (AuthScreen) affiche bien l'erreur
        rethrow;
      }
    }

    if (res.session == null) {
      debugPrint(
        'signUp OK mais aucune session ouverte — '
        'la confirmation email est probablement encore activée dans Supabase.',
      );
    }

    return res;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() {
    return supabase.auth.signOut();
  }

  User? get currentUser => supabase.auth.currentUser;

  /// Retourne le profil de l'utilisateur connecté, ou null s'il n'existe pas.
  /// Utilise maybeSingle() pour distinguer "pas de ligne" d'une vraie erreur
  /// (ex: policy RLS qui bloque la lecture).
  Future<ProfileModel?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) {
        debugPrint(
          'Aucun profil trouvé pour user ${user.id} — '
          'insert manqué au signUp ou policy RLS SELECT manquante ?',
        );
        return null;
      }

      return ProfileModel.fromJson(data);
    } catch (e, st) {
      debugPrint('Erreur getCurrentProfile: $e\n$st');
      rethrow;
    }
  }

  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;
}
