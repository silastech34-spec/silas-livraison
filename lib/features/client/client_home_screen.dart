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
    final userId = supabase.auth.currentUser!.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes colis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().signOut(),
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
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final colis = snapshot.data!;
          if (colis.isEmpty) {
            return const Center(
              child: Text('Aucun colis pour le moment.\nAppuie sur + pour en créer un.',
                  textAlign: TextAlign.center),
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
                    child: const Icon(Icons.inventory_2, color: Colors.white, size: 20),
                  ),
                  title: Text(c.natureColis),
                  subtitle: Text(
                    '${c.commune} — ${c.prix} FCFA\n${_labelStatut(c.statut)}',
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
