import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'address_screen.dart';
import 'cart_controller.dart';

// Permet aux autres fichiers qui importent cart_screen.dart de continuer
// à accéder à CartItem et CartController.
export 'cart_controller.dart';

// ───────────────────────── Constantes de style ─────────────────────────

const _ink = Color(0xFF1C1A17); // texte principal
const _amber = Color(0xFFF59A00); // montants du résumé
const _cardDark = Color(0xFF262626); // fond des cartes article
const _trashRed = Color(0xFFFF1F1F); // icône de suppression

/// Écran du panier ("My Cart") : liste des articles + résumé et bouton Checkout.
/// Il lit le panier partagé [CartController] et se met à jour tout seul.
class CartScreen extends StatelessWidget {
  final String currency;

  const CartScreen({super.key, this.currency = r'$'});

  /// Formate un montant : "20" si entier, "19.99" sinon.
  /// (L'ancien code utilisait toInt(), qui tronquait les décimales.)
  String _money(double value) {
    final text = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
    return '$currency$text';
  }

  /// Supprime une ligne et propose de l'annuler pendant quelques secondes.
  void _remove(BuildContext context, CartItem item) {
    final cart = CartController.instance;
    final index = cart.remove(item);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${item.name} removed'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () => cart.insert(index, item),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartController.instance;

    return Scaffold(
      body: Container(
        // Même dégradé jaune → orange que les autres écrans.
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFD400), Color(0xFFFFB000), _amber],
            stops: [0, .35, 1],
          ),
        ),
        child: SafeArea(
          bottom: false,
          // ListenableBuilder reconstruit l'écran à chaque changement du panier.
          child: ListenableBuilder(
            listenable: cart,
            builder: (context, _) {
              // Journal de débogage (uniquement en mode debug).
              if (kDebugMode) {
                debugPrint('[CartScreen] affiche ${cart.items.length} ligne(s) '
                    '(controller #${identityHashCode(cart)})');
              }
              return Column(
                children: [
                  _header(context),
                  Expanded(
                    child: cart.isEmpty
                        ? _emptyState()
                        : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      itemCount: cart.items.length,
                      separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                      itemBuilder: (_, index) {
                        final item = cart.items[index];
                        return _CartItemCard(
                          item: item,
                          currency: currency,
                          money: _money,
                          onMinus: () => cart.decrease(item),
                          onPlus: () => cart.increase(item),
                          onDelete: () => _remove(context, item),
                        );
                      },
                    ),
                  ),
                  _summarySheet(context, cart),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// En-tête : flèche retour à gauche, titre centré.
  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: _ink),
            onPressed: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: Center(
              child: Text(
                'My Cart',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
            ),
          ),
          // Espace égal à celui de la flèche pour que le titre reste centré.
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  /// Message affiché quand le panier est vide.
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shopping_cart_outlined, size: 56, color: _ink),
          const SizedBox(height: 12),
          Text(
            'Your cart is empty',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: _ink,
            ),
          ),
        ],
      ),
    );
  }

  /// Panneau blanc du bas : Subtotal, Shipping, Discount, Total + Checkout.
  Widget _summarySheet(BuildContext context, CartController cart) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, 26, 24, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _summaryRow('Subtotal', _money(cart.subtotal)),
          const SizedBox(height: 14),
          _summaryRow('Shipping', _money(cart.shipping)),
          const SizedBox(height: 14),
          // Réduction affichée avec un signe "-" quand elle est > 0.
          _summaryRow(
            'Discount',
            cart.discount > 0 ? '-${_money(cart.discount)}' : _money(0),
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.black38, height: 1, thickness: 0.7),
          const SizedBox(height: 14),
          _summaryRow('Total', _money(cart.total)),
          const SizedBox(height: 26),
          _CheckoutButton(
            // Bouton désactivé si le panier est vide.
            onPressed: cart.isEmpty
                ? null
                : () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddressScreen(currency: currency),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        Text(
          amount,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _amber,
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── Widgets internes ─────────────────────────

/// Convertit une taille abrégée en libellé complet ("M" -> "Medium").
/// Les tailles numériques (pointures) restent inchangées.
String _sizeLabel(String size) {
  switch (size.toUpperCase()) {
    case 'XS':
      return 'Extra Small';
    case 'S':
      return 'Small';
    case 'M':
      return 'Medium';
    case 'L':
      return 'Large';
    case 'XL':
      return 'Extra Large';
    default:
      return size;
  }
}

/// Carte sombre d'un article : image à gauche, infos au centre,
/// corbeille rouge en haut à droite, prix en bas à droite.
class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final String currency; // symbole monétaire (ex. "$")
  final String Function(double) money; // montant déjà formaté avec le symbole
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onDelete;

  const _CartItemCard({
    required this.item,
    required this.currency,
    required this.money,
    required this.onMinus,
    required this.onPlus,
    required this.onDelete,
  });

  /// Ligne "Label:  valeur" (label gris, valeur blanche).
  Widget _detailRow(String label, Widget value) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Text(
              label,
              style: GoogleFonts.poppins(fontSize: 9.5, color: Colors.grey[500]),
            ),
          ),
          value,
        ],
      ),
    );
  }

  Widget _valueText(String text) => Text(
    text,
    style: GoogleFonts.poppins(
      fontSize: 9.5,
      fontWeight: FontWeight.w500,
      color: Colors.white,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final controlStyle = GoogleFonts.poppins(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    );

    return Container(
      height: 112,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          // Image du produit.
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              width: 88,
              height: double.infinity,
              child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                  ? Image.network(
                item.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imageFallback(),
              )
                  : _imageFallback(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Stack(
              children: [
                // Nom + détails (couleur, taille, quantité).
                Padding(
                  padding: const EdgeInsets.only(top: 8, right: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Couleur et taille : masquées si le produit n'en a pas.
                      if (item.colour != null)
                        _detailRow('Colour:', _valueText(item.colour!)),
                      if (item.size != null)
                        _detailRow('Size:', _valueText(_sizeLabel(item.size!))),
                      // Contrôle de quantité : "-  1  +"
                      _detailRow(
                        'Quantity:',
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _qtyButton('-', onMinus, controlStyle),
                            SizedBox(
                              width: 22,
                              child: Text(
                                '${item.quantity}',
                                textAlign: TextAlign.center,
                                style: controlStyle,
                              ),
                            ),
                            _qtyButton('+', onPlus, controlStyle),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Corbeille rouge (supprime la ligne).
                Positioned(
                  top: 2,
                  right: 0,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onDelete,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.delete_outline,
                          size: 20, color: _trashRed),
                    ),
                  ),
                ),
                // Prix de la ligne (prix × quantité) en bas à droite.
                Positioned(
                  bottom: 4,
                  right: 6,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: currency,
                          style: const TextStyle(fontSize: 10),
                        ),
                        // Montant sans le symbole (déjà affiché en petit à gauche).
                        TextSpan(text: money(item.total).substring(currency.length)),
                      ],
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Texte "-" ou "+" cliquable avec une zone de toucher confortable.
  Widget _qtyButton(String symbol, VoidCallback onTap, TextStyle style) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 22,
        height: 24,
        child: Center(child: Text(symbol, style: style)),
      ),
    );
  }

  Widget _imageFallback() => Container(
    color: Colors.white12,
    child: const Icon(Icons.image_outlined, color: Colors.white54),
  );
}

/// Bouton "Checkout" : dégradé orange → jaune avec ombre portée.
class _CheckoutButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _CheckoutButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [_amber, Color(0xFFFFD400)],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onPressed,
            child: SizedBox(
              height: 50,
              width: double.infinity,
              child: Center(
                child: Text(
                  'Checkout',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}