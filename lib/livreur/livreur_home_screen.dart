import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/supabase_client.dart';
import '../../services/colis_service.dart';
import '../../services/auth_service.dart';
import '../../models/colis_model.dart';

class LivreurHomeScreen extends StatefulWidget {
  const LivreurHomeScreen({super.key});

  @override
  State<LivreurHomeScreen> createState() => _LivreurHomeScreenState();
}

class _LivreurHomeScreenState extends State<LivreurHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _colisService = ColisService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _accepterColis(ColisModel colis) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accepter ce colis ?'),
        content: Text(
          'Commune : ${colis.commune}\n'
          'Prix course : ${colis.prix} FCFA\n\n'
          'Frais d\'acceptation : 50 FCFA\n'
          '⚠️ Tu as 1h pour aller récupérer le colis après acceptation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Payer 50f et accepter'),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    // TODO: brancher ici le vrai paiement Wave/Orange Money/MTN
    // avant de confirmer l'acceptation côté base.

    final userId = supabase.auth.currentUser!.id;
    await _colisService.accepterColis(colisId: colis.id, livreurId: userId);

    if (mounted) {
      context.push('/livreur/colis/${colis.id}');
    }
  }

  Color _couleurStatut(StatutColis s) {
    switch (s) {
      case StatutColis.accepte:
        return Colors.blue;
      case StatutColis.recupere:
        return Colors.purple;
      case StatutColis.livre:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = supabase.auth.currentUser!.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Silas Livraison'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Disponibles'),
            Tab(text: 'Mes courses'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => context.push('/archives'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // --- Colis disponibles ---
          StreamBuilder<List<ColisModel>>(
            stream: _colisService.colisDisponibles(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final colis = snapshot.data!;
              if (colis.isEmpty) {
                return const Center(child: Text('Aucun colis disponible'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: colis.length,
                itemBuilder: (context, i) {
                  final c = colis[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text('${c.commune} — ${c.prix} FCFA'),
                      subtitle: Text(c.natureColis),
                      trailing: FilledButton(
                        onPressed: () => _accepterColis(c),
                        child: const Text('Accepter'),
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // --- Mes courses en cours + historique récent ---
          StreamBuilder<List<ColisModel>>(
            stream: _colisService.mesColisLivreur(userId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final colis = snapshot.data!;
              if (colis.isEmpty) {
                return const Center(child: Text('Aucune course pour le moment'));
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
                      ),
                      title: Text('${c.commune} — ${c.prix} FCFA'),
                      subtitle: Text(c.natureColis),
                      onTap: c.statut == StatutColis.livre
                          ? null
                          : () => context.push('/livreur/colis/${c.id}'),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
