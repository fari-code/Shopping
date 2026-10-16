class Utilisateur {
  final int? id;
  final String nom;
  final String prenom;
  final String email;
  final String passwordHash;

  Utilisateur({
    this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.passwordHash,
  });

  Map<String, Object?> toMap() {
    return {
      'nom': nom,
      'prenom': prenom,
      'email': email.trim().toLowerCase(),
      'password_hash': passwordHash,
    };
  }

  factory Utilisateur.fromMap(Map<String, Object?> map) {
    return Utilisateur(
      id: map['id'] as int?,
      nom: map['nom'] as String,
      prenom: map['prenom'] as String,
      email: map['email'] as String,
      passwordHash: map['password_hash'] as String,
    );
  }
}