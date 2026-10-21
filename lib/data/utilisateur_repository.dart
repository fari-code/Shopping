import 'package:sqflite/sqflite.dart';
import 'package:shopping/data/db_helper.dart';
import 'package:shopping/models/utilisateur.dart';

// Contrat du repository
abstract class UtilisateurRepository {
  Future<void> ajouter(Utilisateur utilisateur);

  Future<Utilisateur?> trouverParEmail(String email);
}

// Implémentation SQLite
class SqliteUtilisateurRepository implements UtilisateurRepository {
  @override
  Future<void> ajouter(Utilisateur utilisateur) async {
    final db = await DbHelper.db;

    await db.insert('users', utilisateur.toMap());
  }

  @override
  Future<Utilisateur?> trouverParEmail(String email) async {
    final db = await DbHelper.db;

    final rows = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    return Utilisateur.fromMap(rows.first);
  }
}
