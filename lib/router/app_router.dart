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

  refreshListenable: GoRouterRefreshStream(
    _authService.authStateChanges,
  ),

  redirect: (context, state) async {
    final user = supabase.auth.currentUser;

    final loggedIn = user != null;
    final loggingIn = state.matchedLocation == '/auth';

    debugPrint(
      'ROUTER => page=${state.matchedLocation}, '
      'loggedIn=$loggedIn, '
      'user=${user?.id}',
    );

    // ============================================================
    // UTILISATEUR NON CONNECTÉ
    // ============================================================

    if (!loggedIn) {
      if (loggingIn) {
        return null;
      }

      return '/auth';
    }

    // ============================================================
    // UTILISATEUR CONNECTÉ
    // ============================================================

    // S'il est déjà sur une page protégée,
    // on ne fait rien.
    if (!loggingIn && state.matchedLocation != '/') {
      return null;
    }

    // ============================================================
    // RÉCUPÉRATION DU PROFIL
    // ============================================================

    try {
      final profile = await _authService.getCurrentProfile();

      // ----------------------------------------------------------
      // PROFIL TROUVÉ
      // ----------------------------------------------------------

      if (profile != null) {
        debugPrint(
          'Profil trouvé. Role = ${profile.role}',
        );

        if (profile.isLivreur) {
          return '/livreur';
        }

        return '/client';
      }

      // ----------------------------------------------------------
      // UTILISATEUR AUTHENTIFIÉ MAIS PROFIL ABSENT
      // ----------------------------------------------------------

      debugPrint(
        'ATTENTION : utilisateur connecté mais profil absent '
        'dans public.profiles.',
      );

      debugPrint(
        'User ID : ${user.id}',
      );

      // IMPORTANT :
      // On ne renvoie PAS vers /auth.
      //
      // Sinon l'utilisateur peut avoir l'impression
      // que son login ne fonctionne pas alors que
      // Supabase l'a bien authentifié.

      return '/client';
    } catch (e, st) {
      debugPrint(
        'ERREUR ROUTER / PROFIL : $e',
      );

      debugPrint('$st');

      // L'utilisateur est bien authentifié.
      // On ne doit donc pas le renvoyer vers /auth.

      return '/client';
    }
  },

  routes: [
    // ============================================================
    // AUTHENTIFICATION
    // ============================================================

    GoRoute(
      path: '/auth',
      builder: (context, state) {
        return const AuthScreen();
      },
    ),

    // ============================================================
    // CLIENT
    // ============================================================

    GoRoute(
      path: '/client',
      builder: (context, state) {
        return const ClientHomeScreen();
      },
    ),

    GoRoute(
      path: '/client/nouveau-colis',
      builder: (context, state) {
        return const CreerColisScreen();
      },
    ),

    // ============================================================
    // LIVREUR
    // ============================================================

    GoRoute(
      path: '/livreur',
      builder: (context, state) {
        return const LivreurHomeScreen();
      },
    ),

    GoRoute(
      path: '/livreur/colis/:id',
      builder: (context, state) {
        return ColisDetailScreen(
          colisId: state.pathParameters['id']!,
        );
      },
    ),

    // ============================================================
    // PARTAGÉ
    // ============================================================

    GoRoute(
      path: '/archives',
      builder: (context, state) {
        return const ArchivesScreen();
      },
    ),
  ],
);

/// Permet à GoRouter de réagir aux changements
/// d'état d'authentification Supabase.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();

    _subscription = stream
        .asBroadcastStream()
        .listen((_) {
      notifyListeners();
    });
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
