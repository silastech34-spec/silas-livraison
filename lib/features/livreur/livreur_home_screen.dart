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

    _tabController = TabController(
      length: 2,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

    final user = supabase.auth.currentUser;

    if (user == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session utilisateur introuvable.'),
        ),
      );

      return;
    }

    try {
      // TODO : brancher le vrai paiement Wave/Orange Money/MTN.
      await _colisService.accepterColis(
        colisId: colis.id,
        livreurId: user.id,
      );

      if (mounted) {
        context.push('/livreur/colis/${colis.id}');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
        ),
      );
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

  Widget _erreurStream(Object? error) {
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
              'Impossible de charger les colis',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                setState(() {});
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

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
            onPressed: () async {
              await AuthService().signOut();
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ------------------------------------------------
          // COLIS DISPONIBLES
          // ------------------------------------------------
          StreamBuilder<List<ColisModel>>(
            stream: _colisService.colisDisponibles(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _erreurStream(snapshot.error);
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
                      'Aucun colis disponible pour le moment.',
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
                      title: Text(
                        '${c.commune} — ${c.prix} FCFA',
                      ),
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

          // ------------------------------------------------
          // MES COURSES
          // ------------------------------------------------
          StreamBuilder<List<ColisModel>>(
            stream: _colisService.mesColisLivreur(userId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _erreurStream(snapshot.error);
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
                      'Aucune course pour le moment.',
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
                          Icons.local_shipping,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        '${c.commune} — ${c.prix} FCFA',
                      ),
                      subtitle: Text(c.natureColis),
                      onTap: c.statut == StatutColis.livre
                          ? null
                          : () => context.push(
                                '/livreur/colis/${c.id}',
                              ),
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
