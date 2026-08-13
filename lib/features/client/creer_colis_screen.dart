import 'package:flutter/material.dart';
import '../../services/colis_service.dart';

class CreerColisScreen extends StatefulWidget {
  const CreerColisScreen({super.key});

  @override
  State<CreerColisScreen> createState() => _CreerColisScreenState();
}

class _CreerColisScreenState extends State<CreerColisScreen> {
  final _colisService = ColisService();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _loadingCommunes = true;
  String? _error;

  List<Map<String, dynamic>> _communes = [];
  String? _communeSelectionnee;
  int? _prixSelectionne;

  final _natureCtrl = TextEditingController();

  final _recupNumeroCtrl = TextEditingController();
  final _recupNomCtrl = TextEditingController();
  final _recupAdresseCtrl = TextEditingController();

  final _livraisonNumeroCtrl = TextEditingController();
  final _livraisonNomCtrl = TextEditingController();
  final _livraisonAdresseCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _chargerCommunes();
  }

  Future<void> _chargerCommunes() async {
    final data = await _colisService.getCommunesTarifs();
    setState(() {
      _communes = data;
      _loadingCommunes = false;
    });
  }

  Future<void> _soumettre() async {
    if (!_formKey.currentState!.validate()) return;
    if (_communeSelectionnee == null) {
      setState(() => _error = 'Choisis une commune');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _colisService.creerColis(
        commune: _communeSelectionnee!,
        prix: _prixSelectionne!,
        natureColis: _natureCtrl.text.trim(),
        recupNumero: _recupNumeroCtrl.text.trim(),
        recupNom: _recupNomCtrl.text.trim(),
        recupAdresse: _recupAdresseCtrl.text.trim(),
        livraisonNumero: _livraisonNumeroCtrl.text.trim(),
        livraisonNom: _livraisonNomCtrl.text.trim(),
        livraisonAdresse: _livraisonAdresseCtrl.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Colis soumis avec succès')),
        );
      }
    } catch (e) {
      setState(() => _error = 'Erreur : ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau colis')),
      body: _loadingCommunes
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                     value: _communeSelectionnee,
                      decoration: const InputDecoration(labelText: 'Commune'),
                      items: _communes.map((c) {
                        return DropdownMenuItem<String>(
                          value: c['commune'] as String,
                          child: Text(
                            '${c['commune']} — ${c['prix']} FCFA',
                          ),
                        );
                      }).toList(),
                      onChanged: (v) {
                        final commune = _communes.firstWhere((c) => c['commune'] == v);
                        setState(() {
                          _communeSelectionnee = v;
                          _prixSelectionne = commune['prix'] as int;
                        });
                      },
                      validator: (v) => v == null ? 'Requis' : null,
                    ),
                    if (_prixSelectionne != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Prix de la course : $_prixSelectionne FCFA',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],

                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _natureCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nature du colis',
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                    ),

                    const SizedBox(height: 24),
                    Text(
                      'Récupération',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Divider(),
                    TextFormField(
                      controller: _recupNumeroCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Numéro de récupération',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _recupNomCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nom de récupération',
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _recupAdresseCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Adresse de récupération',
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                    ),

                    const SizedBox(height: 24),
                    Text(
                      'Livraison',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Divider(),
                    TextFormField(
                      controller: _livraisonNumeroCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Numéro de livraison',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _livraisonNomCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nom de livraison',
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _livraisonAdresseCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Adresse de livraison',
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],

                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loading ? null : _soumettre,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Soumettre le colis'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
