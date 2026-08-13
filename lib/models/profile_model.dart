class ProfileModel {
  final String id;
  final String nom;
  final String telephone;
  final String? whatsapp;
  final String role; // client | livreur | admin
  final String? photoUrl;
  final bool soldeDisponible;

  ProfileModel({
    required this.id,
    required this.nom,
    required this.telephone,
    this.whatsapp,
    required this.role,
    this.photoUrl,
    this.soldeDisponible = true,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      nom: json['nom'] as String,
      telephone: json['telephone'] as String,
      whatsapp: json['whatsapp'] as String?,
      role: json['role'] as String,
      photoUrl: json['photo_url'] as String?,
      soldeDisponible: json['solde_disponible'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'telephone': telephone,
      'whatsapp': whatsapp,
      'role': role,
      'photo_url': photoUrl,
      'solde_disponible': soldeDisponible,
    };
  }

  bool get isClient => role == 'client';
  bool get isLivreur => role == 'livreur';
  bool get isAdmin => role == 'admin';
}
