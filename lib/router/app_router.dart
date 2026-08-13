import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../core/supabase_client.dart';
import '../features/auth/auth_screen.dart';
import '../features/client/client_home_screen.dart';
import '../features/client/creer_colis_screen.dart';
import '../features/livreur/livreur_home_screen.dart';
import '../features/livreur/colis_detail_screen.dart';
import '../features/shared/archives_screen.dart';

final _authService = AuthService();

final router = GoRouter(
  initialLocation: '/',
  refreshListenable: GoRouterRefreshStream(_authService.authStateChanges),
  redirect: (context, state) async {
    final loggedIn = supabase.auth.currentUser != null;
    final loggingIn = state.matchedLocation == '/auth';

    if (!loggedIn) {
      return loggingIn ? null : '/auth';
    }

    // Utilisateur connecté : s'il est sur /auth ou sur la racine '/',
    // on le redirige vers son espace selon son rôle
    if (loggingIn || state.matchedLocation == '/') {
      try {
        final profile = await _authService.getCurrentProfile();
        if (profile == null) {
          debugPrint(
            'Aucun profil trouvé pour ${supabase.auth.currentUser?.id} '
            '— vérifie la table profiles et les policies RLS.',
          );
          return '/auth';
        }
        return profile.isLivreur ? '/livreur' : '/client';
      } catch (e, st) {
        debugPrint('Erreur lors du chargement du profil: $e\n$st');
        // On évite de laisser l'utilisateur bloqué silencieusement sur un écran blanc
        return '/auth';
      }
    }

    return null;
  },
  routes: [
    GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),

    // --- Espace client ---
    GoRoute(
      path: '/client',
      builder: (context, state) => const ClientHomeScreen(),
    ),
    GoRoute(
      path: '/client/nouveau-colis',
      builder: (context, state) => const CreerColisScreen(),
    ),

    // --- Espace livreur ---
    GoRoute(
      path: '/livreur',
      builder: (context, state) => const LivreurHomeScreen(),
    ),
    GoRoute(
      path: '/livreur/colis/:id',
      builder: (context, state) => ColisDetailScreen(
        colisId: state.pathParameters['id']!,
      ),
    ),

    // --- Partagé ---
    GoRoute(
      path: '/archives',
      builder: (context, state) => const ArchivesScreen(),
    ),
  ],
);

/// Permet à GoRouter de réagir aux changements d'état d'authentification Supabase
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
