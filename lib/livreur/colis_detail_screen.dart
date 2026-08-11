import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/supabase_client.dart';
import '../../services/colis_service.dart';
import '../../models/colis_model.dart';

class ColisDetailScreen extends StatefulWidget {
  final String colisId;
  const ColisDetailScreen({super.key, required this.colisId});

  @override
  State<ColisDetailScreen> createState() => _ColisDetailScreenState();
}

class _ColisDetailScreenState extends State<ColisDetailScreen> {
  final _colisService = ColisService();
  Timer? _timer;
  int _tick = 0; // force le rebuild chaque seconde pour les décomptes

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _tick++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuree(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h}h ${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
    }
    return '${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
  }

  Future<void> _relacher(String colisId) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Relâcher ce colis ?'),
        content: const Text(
          'Le colis redeviendra disponible pour un autre livreur. Cette action est immédiate.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Relâcher'),
          ),
        ],
      ),
    );

    if (confirme == true) {
      await _colisService.relacherColis(colisId);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _marquerRecupere(String colisId) async {
    await _colisService.marquerRecupere(colisId);
  }

  Future<void> _marquerLivre(String colisId, DateTime? recupereAt) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la livraison ?'),
        content: const Text('Cette action clôture la course.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer livré'),
          ),
        ],
      ),
    );

    if (confirme == true) {
      await _colisService.marquerLivre(colisId, recupereAt: recupereAt);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détail de la course')),
      body: StreamBuilder<List<ColisModel>>(
        stream: supabase
            .from('colis')
            .stream(primaryKey: ['id'])
            .eq('id', widget.colisId)
            .map((rows) => rows.map((r) => ColisModel.fromJson(r)).toList()),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final colis = snapshot.data!.first;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(colis.natureColis,
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text('${colis.commune} — ${colis.prix} FCFA'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                _sectionAdresse(
                  context,
                  titre: 'Récupération',
                  nom: colis.recupNom,
                  numero: colis.recupNumero,
                  adresse: colis.recupAdresse,
                  icone: Icons.store,
                ),
                const SizedBox(height: 12),
                _sectionAdresse(
                  context,
                  titre: 'Livraison',
                  nom: colis.livraisonNom,
                  numero: colis.livraisonNumero,
                  adresse: colis.livraisonAdresse,
                  icone: Icons.location_on,
                ),

                const SizedBox(height: 24),

                // --- Statut ACCEPTE : décompte récupération + boutons ---
                if (colis.statut == StatutColis.accepte) ...[
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text('Temps restant pour récupérer'),
                          const SizedBox(height: 8),
                          Text(
                            _formatDuree(
                              colis.tempsRestantRecuperation ?? Duration.zero,
                            ),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if ((colis.tempsRestantRecuperation ?? Duration.zero) ==
                              Duration.zero)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                'Délai dépassé — relâche automatique en cours',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _marquerRecupere(colis.id),
                    icon: const Icon(Icons.check),
                    label: const Text('Colis récupéré'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () => _relacher(colis.id),
                    icon: const Icon(Icons.close),
                    label: const Text('Relâcher le colis'),
                  ),
                ],

                // --- Statut RECUPERE : décompte pénalité + bouton livré ---
                if (colis.statut == StatutColis.recupere) ...[
                  Card(
                    color: colis.penaliteEnCours > 0
                        ? Colors.red.shade50
                        : Colors.purple.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text('Colis en cours de livraison'),
                          const SizedBox(height: 8),
                          if (colis.penaliteEnCours > 0)
                            Text(
                              'Pénalité en cours : ${colis.penaliteEnCours} FCFA',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            )
                          else
                            const Text(
                              'Livre avant la prochaine heure pour éviter une pénalité',
                              textAlign: TextAlign.center,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _marquerLivre(colis.id, colis.recupereAt),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Colis livré'),
                  ),
                ],

                // --- Statut LIVRE : récap ---
                if (colis.statut == StatutColis.livre) ...[
                  Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 40),
                          const SizedBox(height: 8),
                          const Text('Course terminée'),
                          const SizedBox(height: 8),
                          Text('Frais d\'acceptation : ${colis.fraisAcceptation} FCFA'),
                          if (colis.penaliteTotale > 0)
                            Text(
                              'Pénalité appliquée : ${colis.penaliteTotale} FCFA',
                              style: const TextStyle(color: Colors.red),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionAdresse(
    BuildContext context, {
    required String titre,
    required String nom,
    required String numero,
    required String adresse,
    required IconData icone,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icone, size: 20),
                const SizedBox(width: 8),
                Text(titre, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(),
            Text('Nom : $nom'),
            Text('Téléphone : $numero'),
            Text('Adresse : $adresse'),
          ],
        ),
      ),
    );
  }
}
