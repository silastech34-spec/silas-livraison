import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';
import 'profile_model.dart';

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
      await supabase.from('profiles').insert({
        'id': res.user!.id,
        'nom': nom,
        'telephone': telephone,
        'whatsapp': whatsapp,
        'role': role,
      });
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

  Future<ProfileModel?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    return ProfileModel.fromJson(data);
  }

  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;
}
