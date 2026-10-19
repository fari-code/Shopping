import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'address_screen.dart';
import 'cart_screen.dart';
import 'shopping.dart';

// ───────────────────────── Constantes de style ─────────────────────────

const _bg = Color(0xFFFDA400); // fond orange de l'écran
const _ink = Color(0xFF1E1E1E); // texte et bordures sombres
const _muted = Color(0xFF8A5A00); // texte secondaire (description)
const _lime = Color(0xFF33FF00); // vert vif du bouton "Buy now" et du vendeur
const _buttonDark = Color(0xFF262626); // bouton "Add to Cart"

/// Choix faits par l'utilisateur sur l'écran produit.
/// Cet objet est transmis au panier ou au paiement via les callbacks
/// [ProductDetailScreen.onAddToCart] et [ProductDetailScreen.onBuyNow].
class ProductSelection {
  final ShoppingProduct product;
  final String? size; // null si le produit n'a pas de tailles
  final String? colour; // null si le produit n'a pas de couleurs
  final int quantity;

  const ProductSelection({
    required this.product,
    required this.quantity,
    this.size,
    this.colour,
  });

  /// Prix total de la ligne (prix unitaire × quantité).
  double get total => product.price * quantity;
}

class ProductDetailScreen extends StatefulWidget {
  final ShoppingProduct product;
  final String currency;

  /// Appelé quand l'utilisateur appuie sur "Add to Cart".
  /// Si null, un simple message de confirmation est affiché.
  final ValueChanged<ProductSelection>? onAddToCart;

  /// Appelé quand l'utilisateur appuie sur "Buy now"
  /// (typiquement : ouvrir l'écran Address / paiement).
  final ValueChanged<ProductSelection>? onBuyNow;

  const ProductDetailScreen({
    super.key,
    required this.product,
    this.currency = '\$',
    this.onAddToCart,
    this.onBuyNow,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String? _selectedSize;
  String? _selectedColour;
  int _quantity = 1;
  bool _isFavorite = false;

  /// Champ de quantité personnalisée (la case vide à droite de 1-2-3-4).
  final TextEditingController _qtyController = TextEditingController();

  ShoppingProduct get _product => widget.product;

  @override
  void initState() {
    super.initState();
    // Sélection par défaut : première taille et première couleur du produit.
    if (_product.sizes.isNotEmpty) _selectedSize = _product.sizes.first;
    if (_product.colours.isNotEmpty) _selectedColour = _product.colours.first;
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  // ───────────────────────── Helpers ─────────────────────────

  /// Formate un prix : "20" si entier, "19.99" sinon.
  /// (L'ancien code utilisait toInt(), qui tronquait les décimales.)
  String _formatPrice(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);

  /// Convertit le nom d'une couleur du produit en vraie couleur d'affichage.
  Color _colourFromName(String name) {
    switch (name.trim().toLowerCase()) {
      case 'black':
        return const Color(0xFF000000);
      case 'white':
        return Colors.white;
      case 'grey':
      case 'gray':
        return const Color(0xFF9E9E9E);
      case 'cyan':
        return const Color(0xFF00E5FF);
      case 'magenta':
      case 'pink':
        return const Color(0xFFFF00FF);
      case 'green':
        return _lime;
      case 'red':
        return const Color(0xFFE53935);
      case 'blue':
        return const Color(0xFF1E6BFF);
      case 'brown':
        return const Color(0xFF7B4A12);
      case 'yellow':
        return const Color(0xFFFFE600);
      default:
        return const Color(0xFF9E9E9E); // couleur inconnue : gris
    }
  }

  /// "1000+" à partir de 1000 avis, sinon le nombre exact.
  String _reviewsLabel(int count) =>
      count >= 1000 ? '${(count ~/ 1000) * 1000}+' : '$count';

  /// Regroupe les choix de l'utilisateur pour le panier / le paiement.
  ProductSelection _selection() => ProductSelection(
    product: _product,
    size: _selectedSize,
    colour: _selectedColour,
    quantity: _quantity,
  );

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Ajoute la sélection actuelle au panier partagé.
  void _addSelectionToCart() {
    CartController.instance.add(
      product: _product,
      size: _selectedSize,
      colour: _selectedColour,
      quantity: _quantity,
    );
  }

  void _addToCart() {
    _addSelectionToCart();
    widget.onAddToCart?.call(_selection());
    _showMessage('${_product.name} added to cart');
  }

  /// Achat immédiat : on ajoute l'article au panier puis on ouvre
  /// l'écran d'adresse / paiement.
  void _buyNow() {
    _addSelectionToCart();
    final callback = widget.onBuyNow;
    if (callback != null) {
      callback(_selection());
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddressScreen(currency: widget.currency),
      ),
    );
  }

  /// Choix d'une quantité rapide (1 à 4) : on vide le champ personnalisé.
  void _selectQuickQuantity(int qty) {
    FocusScope.of(context).unfocus();
    _qtyController.clear();
    setState(() => _quantity = qty);
  }

  /// Saisie d'une quantité personnalisée (1 à 99).
  /// Si le champ est vide ou invalide, on garde la quantité actuelle.
  void _onCustomQuantity(String value) {
    final n = int.tryParse(value);
    if (n == null || n < 1) return;
    setState(() => _quantity = n.clamp(1, 99));
  }

  // ───────────────────────── Construction de l'écran ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _imageHeader(context),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _titleRow(),
                        if ((_product.description ?? '').isNotEmpty) ...[
                          const SizedBox(height: 22),
                          _sectionTitle('Description'),
                          const SizedBox(height: 6),
                          Text(
                            _product.description!,
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              color: _muted,
                              height: 1.4,
                            ),
                          ),
                        ],
                        // Tailles et couleurs : affichées seulement si le
                        // produit en possède (ex. pas pour un laptop).
                        if (_product.sizes.isNotEmpty ||
                            _product.colours.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          _sizeAndColourRow(),
                        ],
                        const SizedBox(height: 18),
                        _quantitySection(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _bottomBar(),
        ],
      ),
    );
  }

  /// Image du produit en haut, coins du bas arrondis, avec les boutons
  /// retour et favori par-dessus (carrés beiges translucides).
  Widget _imageHeader(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final screenHeight = MediaQuery.of(context).size.height;
    final imageHeight = (screenHeight * 0.45).clamp(300.0, 420.0);
    final url = _product.imageUrl;

    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
          child: SizedBox(
            height: imageHeight,
            width: double.infinity,
            child: (url != null && url.isNotEmpty)
                ? Image.network(
              url,
              fit: BoxFit.cover,
              // Image en cours de chargement ou en erreur : simple fond.
              loadingBuilder: (_, child, progress) =>
              progress == null ? child : _imagePlaceholder(),
              errorBuilder: (_, __, ___) => _imagePlaceholder(),
            )
                : _imagePlaceholder(),
          ),
        ),
        Positioned(
          top: topInset + 12,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _squareButton(
                icon: Icons.arrow_back,
                onTap: () => Navigator.maybePop(context),
              ),
              _squareButton(
                icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
                iconColor: _isFavorite ? Colors.red : _ink,
                // TODO: enregistrer le favori (API / stockage local).
                onTap: () => setState(() => _isFavorite = !_isFavorite),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _imagePlaceholder() => Container(
    color: const Color(0x22000000),
    alignment: Alignment.center,
    child: const Icon(Icons.image_outlined, size: 48, color: Colors.white70),
  );

  /// Petit bouton carré beige translucide (retour / favori).
  Widget _squareButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = _ink,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xB3EBDDC3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 22, color: iconColor),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
    text,
    style: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: _ink,
    ),
  );

  /// Nom + boutique à gauche, étoiles + nombre d'avis à droite.
  Widget _titleRow() {
    final hasRating = _product.rating > 0;
    final hasReviews = _product.reviewCount > 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _product.name,
                style: GoogleFonts.poppins(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
              if ((_product.storeName ?? '').isNotEmpty)
                Text(
                  _product.storeName!,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _lime,
                  ),
                ),
            ],
          ),
        ),
        if (hasRating || hasReviews)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (hasRating)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      5,
                          (i) => Icon(
                        Icons.star,
                        size: 17,
                        // Étoile noire si i < note, grisée sinon.
                        color: i < _product.rating.round()
                            ? _ink
                            : Colors.black26,
                      ),
                    ),
                  ),
                if (hasReviews)
                  Text(
                    '${_reviewsLabel(_product.reviewCount)} Reviews',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _muted,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  /// Case carrée à bord arrondi (taille ou quantité) : pleine si sélectionnée.
  Widget _optionBox(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        width: 30,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _ink : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _ink, width: 1),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : _ink,
          ),
        ),
      ),
    );
  }

  /// Tailles à gauche, couleurs à droite (comme sur la maquette).
  Widget _sizeAndColourRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _product.sizes.isEmpty
              ? const SizedBox.shrink()
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Size'),
              const SizedBox(height: 8),
              Wrap(
                runSpacing: 8,
                children: [
                  for (final size in _product.sizes)
                    _optionBox(
                      size,
                      _selectedSize == size,
                          () => setState(() => _selectedSize = size),
                    ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _product.colours.isEmpty
              ? const SizedBox.shrink()
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Colour'),
              const SizedBox(height: 8),
              Wrap(
                runSpacing: 8,
                children: [
                  for (final name in _product.colours)
                    _colourDot(name),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Pastille de couleur ; un anneau noir entoure la couleur sélectionnée.
  Widget _colourDot(String name) {
    final selected = _selectedColour == name;
    return GestureDetector(
      onTap: () => setState(() => _selectedColour = name),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? _ink : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: _colourFromName(name),
            shape: BoxShape.circle,
            // Fin contour pour que le blanc reste visible sur l'orange.
            border: Border.all(color: Colors.black26, width: 0.5),
          ),
        ),
      ),
    );
  }

  /// Quantité : cases 1 à 4 + case libre pour saisir un autre nombre.
  Widget _quantitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Quantity'),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var qty = 1; qty <= 4; qty++)
              _optionBox(
                '$qty',
                // Case pleine seulement si aucune quantité personnalisée.
                _quantity == qty && _qtyController.text.isEmpty,
                    () => _selectQuickQuantity(qty),
              ),
            // Case libre (vide sur la maquette) : quantité personnalisée.
            Container(
              width: 62,
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: const Color(0x33FFFFFF),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0x66FFFFFF)),
              ),
              alignment: Alignment.center,
              child: TextField(
                controller: _qtyController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                onChanged: _onCustomQuantity,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Barre du bas : prix total, "Buy now" (vert) et "Add to Cart" (sombre).
  Widget _bottomBar() {
    final total = _product.price * _quantity;

    return Container(
      color: _bg,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              // Prix total : "$" petit + montant en gros.
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: widget.currency,
                      style: const TextStyle(fontSize: 14),
                    ),
                    TextSpan(text: _formatPrice(total)),
                  ],
                ),
                style: GoogleFonts.poppins(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                  height: 1,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _actionButton(
                  label: 'Buy now',
                  background: _lime,
                  foreground: Colors.black,
                  onPressed: _buyNow,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionButton(
                  label: 'Add to Cart',
                  background: _buttonDark,
                  foreground: Colors.white,
                  onPressed: _addToCart,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required Color background,
    required Color foreground,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          maxLines: 1,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}