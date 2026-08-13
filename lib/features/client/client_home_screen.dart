import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase_client.dart';
import '../../services/colis_service.dart';
import '../../services/auth_service.dart';
import '../../models/colis_model.dart';

class ClientHomeScreen extends StatelessWidget {
  const ClientHomeScreen({super.key});

  Color _couleurStatut(StatutColis s) {
    switch (s) {
      case StatutColis.enAttente:
        return Colors.orange;
      case StatutColis.accepte:
        return Colors.blue;
      case StatutColis.recupere:
        return Colors.purple;
      case StatutColis.livre:
        return Colors.green;
      case StatutColis.annule:
        return Colors.red;
    }
  }

  String _labelStatut(StatutColis s) {
    switch (s) {
      case StatutColis.enAttente:
        return 'En attente d\'un livreur';
      case StatutColis.accepte:
        return 'Livreur en route';
      case StatutColis.recupere:
        return 'Colis récupéré';
      case StatutColis.livre:
        return 'Livré';
      case StatutColis.annule:
        return 'Annulé';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colisService = ColisService();
    final user = supabase.auth.currentUser;

    // Sécurité : si la session a disparu, on évite le crash.
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Session utilisateur introuvable.'),
        ),
      );
    }

    final userId = user.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes colis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/client/nouveau-colis'),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau colis'),
      ),
      body: StreamBuilder<List<ColisModel>>(
        stream: colisService.mesColisClient(userId),
        builder: (context, snapshot) {
          // IMPORTANT :
          // On affiche maintenant l'erreur réelle au lieu
          // de laisser un spinner tourner indéfiniment.
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 56,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Impossible de charger tes colis',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () {
                        // Le StreamBuilder sera reconstruit.
                        (context as Element).markNeedsBuild();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final colis = snapshot.data ?? [];

          if (colis.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aucun colis pour le moment.\n\nAppuie sur + pour en créer un.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: colis.length,
            itemBuilder: (context, i) {
              final c = colis[i];

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _couleurStatut(c.statut),
                    child: const Icon(
                      Icons.inventory_2,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(c.natureColis),
                  subtitle: Text(
                    '${c.commune} — ${c.prix} FCFA\n'
                    '${_labelStatut(c.statut)}',
                  ),
                  isThreeLine: true,
                  trailing: Text(
                    _labelStatut(c.statut),
                    style: TextStyle(
                      color: _couleurStatut(c.statut),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
