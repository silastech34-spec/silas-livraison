import 'supabase_client.dart';
import 'colis_model.dart';

class ColisService {
  // ---------- CLIENT : soumettre un colis ----------
  Future<void> creerColis({
    required String commune,
    required int prix,
    required String natureColis,
    required String recupNumero,
    required String recupNom,
    required String recupAdresse,
    required String livraisonNumero,
    required String livraisonNom,
    required String livraisonAdresse,
  }) async {
    final userId = supabase.auth.currentUser!.id;

    await supabase.from('colis').insert({
      'client_id': userId,
      'commune': commune,
      'prix': prix,
      'nature_colis': natureColis,
      'recup_numero': recupNumero,
      'recup_nom': recupNom,
      'recup_adresse': recupAdresse,
      'livraison_numero': livraisonNumero,
      'livraison_nom': livraisonNom,
      'livraison_adresse': livraisonAdresse,
    });
  }

  // ---------- LIVREUR : colis disponibles (en_attente) ----------
  Stream<List<ColisModel>> colisDisponibles() {
    return supabase
        .from('colis')
        .stream(primaryKey: ['id'])
        .eq('statut', 'en_attente')
        .order('created_at')
        .map((rows) => rows.map((r) => ColisModel.fromJson(r)).toList());
  }

  // ---------- LIVREUR : mes colis en cours + historique ----------
  Stream<List<ColisModel>> mesColisLivreur(String livreurId) {
    return supabase
        .from('colis')
        .stream(primaryKey: ['id'])
        .eq('livreur_id', livreurId)
        .order('created_at', ascending: false)
        .map((rows) => rows.map((r) => ColisModel.fromJson(r)).toList());
  }

  // ---------- CLIENT : suivi de mes colis ----------
  Stream<List<ColisModel>> mesColisClient(String clientId) {
    return supabase
        .from('colis')
        .stream(primaryKey: ['id'])
        .eq('client_id', clientId)
        .order('created_at', ascending: false)
        .map((rows) => rows.map((r) => ColisModel.fromJson(r)).toList());
  }

  // ---------- LIVREUR : accepter un colis (paiement 50f géré côté paiement mobile avant cet appel) ----------
  Future<void> accepterColis({
    required String colisId,
    required String livreurId,
  }) async {
    // NOTE: le paiement Wave/Orange/MTN des 50f doit être confirmé
    // AVANT d'appeler cette fonction (via ton service de paiement).
    await supabase
        .from('colis')
        .update({
          'livreur_id': livreurId,
          'statut': 'accepte',
          'accepte_at': DateTime.now().toIso8601String(),
        })
        .eq('id', colisId)
        .eq('statut', 'en_attente'); // évite la double-acceptation
  }

  // ---------- LIVREUR : relâcher un colis (bouton manuel, à tout moment tant que "accepte") ----------
  Future<void> relacherColis(String colisId) async {
    await supabase
        .from('colis')
        .update({
          'statut': 'en_attente',
          'livreur_id': null,
          'accepte_at': null,
        })
        .eq('id', colisId)
        .eq('statut', 'accepte');
  }

  // ---------- LIVREUR : colis récupéré (démarre la pénalité) ----------
  Future<void> marquerRecupere(String colisId) async {
    await supabase
        .from('colis')
        .update({
          'statut': 'recupere',
          'recupere_at': DateTime.now().toIso8601String(),
        })
        .eq('id', colisId)
        .eq('statut', 'accepte');
  }

  // ---------- LIVREUR : colis livré (calcule la pénalité finale) ----------
  Future<void> marquerLivre(String colisId, {required DateTime? recupereAt}) async {
    int penalite = 0;
    if (recupereAt != null) {
      final heures = DateTime.now().difference(recupereAt).inHours;
      penalite = heures * 200;
    }

    await supabase
        .from('colis')
        .update({
          'statut': 'livre',
          'livre_at': DateTime.now().toIso8601String(),
          'penalite_totale': penalite,
        })
        .eq('id', colisId)
        .eq('statut', 'recupere');
  }

  // ---------- ARCHIVES / STATS ----------
  Future<List<ColisModel>> archivesLivreur(String livreurId) async {
    final data = await supabase
        .from('colis')
        .select()
        .eq('livreur_id', livreurId)
        .eq('statut', 'livre')
        .order('livre_at', ascending: false);

    return (data as List).map((r) => ColisModel.fromJson(r)).toList();
  }

  Future<Map<String, dynamic>?> statsLivreur(String livreurId) async {
    final data = await supabase
        .from('stats_livreur')
        .select()
        .eq('livreur_id', livreurId)
        .maybeSingle();

    return data;
  }

  // ---------- TARIFS ----------
  Future<List<Map<String, dynamic>>> getCommunesTarifs() async {
    final data = await supabase
        .from('communes_tarifs')
        .select()
        .order('commune');

    return (data as List).cast<Map<String, dynamic>>();
  }
}
