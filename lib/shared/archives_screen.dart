import 'package:flutter/material.dart';
import '../../core/supabase_client.dart';
import '../../services/colis_service.dart';
import '../../models/colis_model.dart';

class ArchivesScreen extends StatelessWidget {
  const ArchivesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colisService = ColisService();
    final userId = supabase.auth.currentUser!.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Archives & Stats')),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: colisService.statsLivreur(userId),
        builder: (context, statsSnapshot) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (statsSnapshot.hasData && statsSnapshot.data != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'Résumé',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          _statRow(
                            'Livraisons complétées',
                            '${statsSnapshot.data!['total_livraisons'] ?? 0}',
                          ),
                          _statRow(
                            'Total frais payés',
                            '${statsSnapshot.data!['total_frais_payes'] ?? 0} FCFA',
                          ),
                          _statRow(
                            'Total pénalités',
                            '${statsSnapshot.data!['total_penalites'] ?? 0} FCFA',
                            couleur: Colors.red,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                Text(
                  'Historique des livraisons',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),

                FutureBuilder<List<ColisModel>>(
                  future: colisService.archivesLivreur(userId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final colis = snapshot.data!;
                    if (colis.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: Center(child: Text('Aucune livraison archivée')),
                      );
                    }
                    return Column(
                      children: colis.map((c) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.check_circle, color: Colors.green),
                            title: Text('${c.commune} — ${c.prix} FCFA'),
                            subtitle: Text(
                              c.penaliteTotale > 0
                                  ? 'Pénalité : ${c.penaliteTotale} FCFA'
                                  : 'Sans pénalité',
                            ),
                            trailing: c.livreAt != null
                                ? Text(
                                    '${c.livreAt!.day}/${c.livreAt!.month}',
                                    style: const TextStyle(fontSize: 12),
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statRow(String label, String value, {Color? couleur}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: couleur),
          ),
        ],
      ),
    );
  }
}
