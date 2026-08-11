enum StatutColis { enAttente, accepte, recupere, livre, annule }

StatutColis statutFromString(String s) {
  switch (s) {
    case 'accepte':
      return StatutColis.accepte;
    case 'recupere':
      return StatutColis.recupere;
    case 'livre':
      return StatutColis.livre;
    case 'annule':
      return StatutColis.annule;
    case 'en_attente':
    default:
      return StatutColis.enAttente;
  }
}

String statutToString(StatutColis s) {
  switch (s) {
    case StatutColis.accepte:
      return 'accepte';
    case StatutColis.recupere:
      return 'recupere';
    case StatutColis.livre:
      return 'livre';
    case StatutColis.annule:
      return 'annule';
    case StatutColis.enAttente:
      return 'en_attente';
  }
}

class ColisModel {
  final String id;
  final String clientId;
  final String? livreurId;

  final String commune;
  final int prix;

  final String natureColis;

  final String recupNumero;
  final String recupNom;
  final String recupAdresse;

  final String livraisonNumero;
  final String livraisonNom;
  final String livraisonAdresse;

  final StatutColis statut;

  final DateTime? accepteAt;
  final DateTime? recupereAt;
  final DateTime? livreAt;

  final int fraisAcceptation;
  final int penaliteTotale;

  final DateTime createdAt;

  ColisModel({
    required this.id,
    required this.clientId,
    this.livreurId,
    required this.commune,
    required this.prix,
    required this.natureColis,
    required this.recupNumero,
    required this.recupNom,
    required this.recupAdresse,
    required this.livraisonNumero,
    required this.livraisonNom,
    required this.livraisonAdresse,
    required this.statut,
    this.accepteAt,
    this.recupereAt,
    this.livreAt,
    this.fraisAcceptation = 50,
    this.penaliteTotale = 0,
    required this.createdAt,
  });

  factory ColisModel.fromJson(Map<String, dynamic> json) {
    return ColisModel(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      livreurId: json['livreur_id'] as String?,
      commune: json['commune'] as String,
      prix: json['prix'] as int,
      natureColis: json['nature_colis'] as String,
      recupNumero: json['recup_numero'] as String,
      recupNom: json['recup_nom'] as String,
      recupAdresse: json['recup_adresse'] as String,
      livraisonNumero: json['livraison_numero'] as String,
      livraisonNom: json['livraison_nom'] as String,
      livraisonAdresse: json['livraison_adresse'] as String,
      statut: statutFromString(json['statut'] as String),
      accepteAt: json['accepte_at'] != null
          ? DateTime.parse(json['accepte_at'] as String)
          : null,
      recupereAt: json['recupere_at'] != null
          ? DateTime.parse(json['recupere_at'] as String)
          : null,
      livreAt: json['livre_at'] != null
          ? DateTime.parse(json['livre_at'] as String)
          : null,
      fraisAcceptation: json['frais_acceptation'] as int? ?? 50,
      penaliteTotale: json['penalite_totale'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'client_id': clientId,
      'commune': commune,
      'prix': prix,
      'nature_colis': natureColis,
      'recup_numero': recupNumero,
      'recup_nom': recupNom,
      'recup_adresse': recupAdresse,
      'livraison_numero': livraisonNumero,
      'livraison_nom': livraisonNom,
      'livraison_adresse': livraisonAdresse,
    };
  }

  // Temps restant avant relâche auto (1h après acceptation)
  Duration? get tempsRestantRecuperation {
    if (statut != StatutColis.accepte || accepteAt == null) return null;
    final limite = accepteAt!.add(const Duration(hours: 1));
    final restant = limite.difference(DateTime.now());
    return restant.isNegative ? Duration.zero : restant;
  }

  // Pénalité calculée en temps réel côté UI (le serveur fait foi au final)
  int get penaliteEnCours {
    if (statut != StatutColis.recupere || recupereAt == null) return penaliteTotale;
    final heuresEcoulees = DateTime.now().difference(recupereAt!).inHours;
    return heuresEcoulees * 200;
  }
}
