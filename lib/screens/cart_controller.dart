import 'package:flutter/foundation.dart';
import 'shopping.dart';

/// Une ligne du panier : un produit avec une taille, une couleur et une
/// quantité données.
class CartItem {
  final String productId;
  final String name;
  final double price; // prix unitaire
  final String? imageUrl;
  final String? size; // null si le produit n'a pas de tailles
  final String? colour; // null si le produit n'a pas de couleurs
  int quantity;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    this.imageUrl,
    this.size,
    this.colour,
    this.quantity = 1,
  });

  /// Identifie une ligne : deux ajouts du même produit avec la même taille,
  /// la même couleur et le même prix sont fusionnés en une seule ligne.
  /// (Le prix est inclus car un produit en promotion a un prix différent.)
  String get lineKey => '$productId|${size ?? ''}|${colour ?? ''}|$price';

  /// Total de la ligne (prix unitaire × quantité).
  double get total => price * quantity;
}

/// Panier partagé par toute l'application (accueil, recherche, fiche produit,
/// écran panier). Il prévient automatiquement les écrans qui l'écoutent
/// quand son contenu change : le badge du panier se met donc à jour seul.
///
/// Utilisation : `CartController.instance.add(product: p)`.
class CartController extends ChangeNotifier {
  CartController._();

  /// Instance unique.
  static final CartController instance = CartController._();

  /// Frais de livraison fixes (appliqués seulement si le panier n'est pas vide).
  static const double shippingFee = 10;

  final List<CartItem> _items = [];
  double _discount = 0;

  // ───────────────────────── Lecture ─────────────────────────

  List<CartItem> get items => List.unmodifiable(_items);

  bool get isEmpty => _items.isEmpty;

  /// Nombre total d'articles (somme des quantités) : valeur du badge.
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.fold(0, (sum, item) => sum + item.total);

  double get shipping => _items.isEmpty ? 0 : shippingFee;

  /// Réduction en montant, plafonnée au sous-total.
  double get discount {
    if (_items.isEmpty) return 0;
    return _discount > subtotal ? subtotal : _discount;
  }

  /// Total à payer : sous-total + livraison − réduction.
  double get total => subtotal + shipping - discount;

  // ───────────────────────── Modification ─────────────────────────

  /// Ajoute un produit. S'il est déjà dans le panier (même taille, même
  /// couleur, même prix), on augmente simplement sa quantité.
  void add({
    required ShoppingProduct product,
    String? size,
    String? colour,
    int quantity = 1,
  }) {
    final item = CartItem(
      productId: product.id,
      name: product.name,
      price: product.price,
      imageUrl: product.imageUrl,
      size: size,
      colour: colour,
      quantity: quantity,
    );

    final existing = _items.where((i) => i.lineKey == item.lineKey);
    if (existing.isNotEmpty) {
      existing.first.quantity += quantity;
    } else {
      _items.add(item);
    }
    // Journal de débogage (visible dans la console, uniquement en mode debug).
    if (kDebugMode) {
      debugPrint('[Cart] ajout de "${product.name}" -> $itemCount article(s), '
          '${_items.length} ligne(s) (controller #${identityHashCode(this)})');
    }
    notifyListeners();
  }

  void increase(CartItem item) {
    item.quantity++;
    notifyListeners();
  }

  /// Diminue la quantité, sans jamais descendre sous 1
  /// (pour supprimer une ligne, on utilise [remove]).
  void decrease(CartItem item) {
    if (item.quantity > 1) {
      item.quantity--;
      notifyListeners();
    }
  }

  /// Supprime une ligne et renvoie sa position (utile pour l'annuler).
  int remove(CartItem item) {
    final index = _items.indexOf(item);
    if (index >= 0) {
      _items.removeAt(index);
      notifyListeners();
    }
    return index;
  }

  /// Remet une ligne supprimée à sa position d'origine (bouton "UNDO").
  void insert(int index, CartItem item) {
    final position = index.clamp(0, _items.length);
    _items.insert(position, item);
    notifyListeners();
  }

  /// Définit la réduction en montant (ex. issue d'un code promo).
  void setDiscount(double amount) {
    _discount = amount < 0 ? 0 : amount;
    notifyListeners();
  }

  /// Vide le panier (à appeler après un paiement réussi).
  void clear() {
    _items.clear();
    _discount = 0;
    notifyListeners();
  }
}