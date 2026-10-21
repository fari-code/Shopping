import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'cart_controller.dart';
import 'order_result_screen.dart';
import 'payment_service.dart';
import '../data/notification_service.dart';

// ───────────────────────── Constantes de style ─────────────────────────

const _ink = Color(0xFF1C1A17); // texte principal
const _amber = Color(0xFFF59A00); // montants / accents
const _cardDark = Color(0xFF262626); // fond des cartes sombres
const _lime = Color(0xFF33FF00); // sélection (vert vif)
const _link = Color(0xFF6B7A99); // lien "Add new address +"

/// Texte "Total" etc. : symbole monétaire + montant (sans décimales inutiles).
String _money(String currency, double value) {
  final text = value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
  return '$currency$text';
}

/// Écran "Address" : total à payer, choix de l'adresse de livraison,
/// mode de paiement, informations de carte et bouton "Pay".
class AddressScreen extends StatefulWidget {
  final String currency;

  /// Service qui traite le paiement. Par défaut : service FICTIF
  /// (voir payment_service.dart). Remplacez-le par un vrai prestataire.
  final PaymentService? paymentService;

  const AddressScreen({super.key, this.currency = r'$', this.paymentService});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cart = CartController.instance;
  late final PaymentService _service =
      widget.paymentService ?? MockPaymentService();

  // ── Adresses (données fictives ; TODO : charger depuis le compte utilisateur) ──
  final List<ShippingAddress> _addresses = [
    const ShippingAddress(
      id: 'home',
      label: 'Home Address',
      phone: '+01 (0102) 02154 0214',
      line: 'Manchester Street A2 United Kingdom',
    ),
    const ShippingAddress(
      id: 'office',
      label: 'Office Address',
      phone: '+01 (0102) 02154 0214',
      line: 'Manchester Street A2 United Kingdom',
    ),
  ];
  String? _selectedAddressId = 'home';

  // ── Paiement ──
  PaymentMethod _method = PaymentMethod.mastercard;
  final _holderCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  bool _paying = false; // true pendant le traitement (bloque les doubles clics)

  /// Le formulaire de carte n'existe que pour Mastercard et Visa.
  bool get _isCard => _method != PaymentMethod.paypal;

  ShippingAddress? get _selectedAddress {
    for (final a in _addresses) {
      if (a.id == _selectedAddressId) return a;
    }
    return null;
  }

  @override
  void dispose() {
    _holderCtrl.dispose();
    _numberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  // ───────────────────────── Actions ─────────────────────────

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
      );
  }

  /// Ouvre le formulaire d'adresse (ajout si [existing] est null, sinon édition).
  Future<void> _openAddressForm({ShippingAddress? existing}) async {
    final result = await showModalBottomSheet<ShippingAddress>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddressFormSheet(existing: existing),
    );
    if (result == null || !mounted) return;

    setState(() {
      final index = _addresses.indexWhere((a) => a.id == result.id);
      if (index >= 0) {
        _addresses[index] = result; // modification
      } else {
        _addresses.add(result); // ajout
      }
      _selectedAddressId =
          result.id; // la nouvelle adresse devient sélectionnée
    });
  }

  /// Vérifie tout, lance le paiement puis affiche l'écran de résultat.
  Future<void> _pay() async {
    if (_paying) return;
    FocusScope.of(context).unfocus();

    if (_cart.isEmpty) {
      _message('Your cart is empty.');
      return;
    }
    final address = _selectedAddress;
    if (address == null) {
      _message('Please select a delivery address.');
      return;
    }
    // Pour une carte : on valide les 4 champs avant d'aller plus loin.
    if (_isCard && !(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _paying = true);

    final request = PaymentRequest(
      amount: _cart.total,
      method: _method,
      address: address,
      card: _isCard
          ? CardDetails(
              holderName: _holderCtrl.text.trim(),
              number: _numberCtrl.text.replaceAll(' ', ''),
              expiry: _expiryCtrl.text,
              cvv: _cvvCtrl.text,
            )
          : null,
    );

    PaymentResult result;
    try {
      result = await _service.pay(request);
    } catch (_) {
      // Erreur inattendue (réseau, etc.) : on la traite comme un refus.
      result = const PaymentResult.declined(
        'Something went wrong. Please try again.',
      );
    }
    if (!mounted) return;
    setState(() => _paying = false);

    if (result.success) {
      _cart.clear(); // commande passée : on vide le panier

      // Déclencher la notification locale de confirmation de commande
      try {
        await NotificationService.showOrderNotification(
          title: 'Commande confirmée !',
          body: 'Votre commande a bien été enregistrée et sera livrée à ${address.line}.',
        );
      } catch (e) {
        debugPrint('Erreur notification: $e');
      }

      if (!mounted) return;

      // On remplace toute la pile : le retour ne ramène pas au paiement.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => ThanksScreen(orderNumber: result.orderNumber ?? ''),
        ),
        (route) => false,
      );
    } else {
      // Refus : on garde cet écran dessous pour que "Try Again" revienne
      // au formulaire déjà rempli.
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OopsScreen(message: result.message)),
      );
    }
  }

  // ───────────────────────── Construction de l'écran ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFD400), Color(0xFFFFB000), _amber],
            stops: [0, .35, 1],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _header(),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    children: [
                      _totalBar(),
                      const SizedBox(height: 14),
                      for (final address in _addresses) ...[
                        _AddressCard(
                          address: address,
                          selected: address.id == _selectedAddressId,
                          onTap: () =>
                              setState(() => _selectedAddressId = address.id),
                          onEdit: () => _openAddressForm(existing: address),
                        ),
                        const SizedBox(height: 10),
                      ],
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _openAddressForm(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              'Add new address +',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: _link,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Payment Method',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _methodRow(),
                      const SizedBox(height: 16),
                      // Carte : formulaire ; PayPal : simple information.
                      if (_isCard) ..._cardForm() else _paypalNote(),
                    ],
                  ),
                ),
              ),
              _payBar(),
            ],
          ),
        ),
      ),
    );
  }

  /// En-tête : flèche retour à gauche, titre centré.
  Widget _header() {
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
                'Address',
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

  /// Barre sombre "Total" : le montant vient du panier partagé.
  Widget _totalBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          Text(
            _money(widget.currency, _cart.total),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _amber,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Modes de paiement ─────────────────────────

  Widget _methodRow() {
    return Row(
      children: [
        Expanded(
          child: _methodTile(PaymentMethod.mastercard, _mastercardLogo()),
        ),
        const SizedBox(width: 10),
        Expanded(child: _methodTile(PaymentMethod.visa, _visaLogo())),
        const SizedBox(width: 10),
        Expanded(child: _methodTile(PaymentMethod.paypal, _paypalLogo())),
      ],
    );
  }

  /// Tuile d'un mode de paiement : bordure verte + pastille ✓ si sélectionnée.
  Widget _methodTile(PaymentMethod method, Widget logo) {
    final selected = _method == method;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() => _method = method);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _cardDark,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: selected ? _lime : Colors.transparent,
                width: 2,
              ),
            ),
            child: logo,
          ),
          if (selected)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: _lime,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 12, color: Colors.black),
              ),
            ),
        ],
      ),
    );
  }

  /// Logo Mastercard : deux cercles qui se chevauchent.
  Widget _mastercardLogo() {
    return SizedBox(
      width: 50,
      height: 30,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: Color(0xFFEB001B),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 0,
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: Color(0xFFF79E1B),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _visaLogo() => Text(
    'VISA',
    style: GoogleFonts.poppins(
      fontSize: 22,
      fontWeight: FontWeight.w800,
      fontStyle: FontStyle.italic,
      color: Colors.grey[500],
    ),
  );

  Widget _paypalLogo() => Text(
    'P',
    style: GoogleFonts.poppins(
      fontSize: 34,
      fontWeight: FontWeight.w800,
      fontStyle: FontStyle.italic,
      color: Colors.grey[500],
    ),
  );

  // ───────────────────────── Formulaire de carte ─────────────────────────

  List<Widget> _cardForm() {
    return [
      _field(
        label: 'Card Holder Name',
        controller: _holderCtrl,
        hint: 'Name on card',
        keyboardType: TextInputType.name,
        textCapitalization: TextCapitalization.words,
        validator: (v) => (v == null || v.trim().length < 2)
            ? 'Enter the card holder name'
            : null,
      ),
      const SizedBox(height: 14),
      _field(
        label: 'Card Number',
        controller: _numberCtrl,
        hint: '0000 0000 0000 0000',
        keyboardType: TextInputType.number,
        formatters: [_CardNumberFormatter()],
        validator: (v) {
          final digits = (v ?? '').replaceAll(' ', '');
          return digits.length == 16
              ? null
              : 'Enter the 16 digits of your card';
        },
      ),
      const SizedBox(height: 14),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _field(
              label: 'Expire Date',
              controller: _expiryCtrl,
              hint: 'MM/YY',
              keyboardType: TextInputType.number,
              formatters: [_ExpiryFormatter()],
              validator: _validateExpiry,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _field(
              label: 'CVV',
              controller: _cvvCtrl,
              hint: '123',
              keyboardType: TextInputType.number,
              obscure: true,
              // le CVV est masqué par sécurité
              formatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              validator: (v) =>
                  (v ?? '').length == 3 ? null : 'Enter the 3-digit CVV',
            ),
          ),
        ],
      ),
    ];
  }

  /// Valide "MM/YY" : format correct, mois de 01 à 12, carte non expirée.
  String? _validateExpiry(String? value) {
    final match = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(value ?? '');
    if (match == null) return 'Use MM/YY';
    final month = int.parse(match.group(1)!);
    final year = 2000 + int.parse(match.group(2)!);
    if (month < 1 || month > 12) return 'Invalid month';
    final now = DateTime.now();
    if (year < now.year || (year == now.year && month < now.month)) {
      return 'Card expired';
    }
    return null;
  }

  /// Champ stylé comme sur la maquette : libellé sombre au-dessus,
  /// cadre sombre sur fond orange, texte blanc.
  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? formatters,
    bool obscure = false,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: _cardDark, width: 1.5),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _ink,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          inputFormatters: formatters,
          obscureText: obscure,
          validator: validator,
          // Les erreurs s'affichent dès que l'utilisateur a touché le champ.
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white54,
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 15,
            ),
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: const BorderSide(color: _cardDark, width: 2.5),
            ),
            errorBorder: border.copyWith(
              borderSide: BorderSide(color: Colors.red[900]!, width: 1.5),
            ),
            focusedErrorBorder: border.copyWith(
              borderSide: BorderSide(color: Colors.red[900]!, width: 2.5),
            ),
            errorStyle: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.red[900],
            ),
          ),
        ),
      ],
    );
  }

  /// Message affiché à la place du formulaire quand PayPal est choisi.
  Widget _paypalNote() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'You will be redirected to PayPal to complete your payment securely.',
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _ink,
        ),
      ),
    );
  }

  // ───────────────────────── Bouton Pay ─────────────────────────

  Widget _payBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 8, 40, 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _cardDark,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _cardDark,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            // Désactivé pendant le traitement pour éviter un double paiement.
            onPressed: _paying ? null : _pay,
            child: _paying
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Pay',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Carte d'adresse ─────────────────────────

/// Carte sombre d'une adresse : pastille de sélection, textes, crayon d'édition.
class _AddressCard extends StatelessWidget {
  final ShippingAddress address;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _AddressCard({
    required this.address,
    required this.selected,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
        decoration: BoxDecoration(
          color: _cardDark,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            // Pastille : anneau vert plein si sélectionnée, anneau gris sinon.
            Container(
              width: 34,
              height: 34,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? _lime : Colors.grey[600]!,
                  width: 3,
                ),
              ),
              child: selected
                  ? const DecoratedBox(
                      decoration: BoxDecoration(
                        color: _lime,
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Le titre est facultatif (la 2e carte de la maquette n'en a pas).
                  if (address.label.isNotEmpty)
                    Text(
                      address.label,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    address.phone,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.line,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 20, color: Colors.white),
              onPressed: onEdit,
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Formulaire d'adresse (bottom sheet) ─────────────────────────

/// Feuille du bas pour ajouter ou modifier une adresse.
/// Renvoie le [ShippingAddress] enregistré via Navigator.pop.
class _AddressFormSheet extends StatefulWidget {
  final ShippingAddress? existing;

  const _AddressFormSheet({this.existing});

  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _labelCtrl = TextEditingController(
    text: widget.existing?.label ?? '',
  );
  late final _phoneCtrl = TextEditingController(
    text: widget.existing?.phone ?? '',
  );
  late final _lineCtrl = TextEditingController(
    text: widget.existing?.line ?? '',
  );

  @override
  void dispose() {
    _labelCtrl.dispose();
    _phoneCtrl.dispose();
    _lineCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(
      context,
      ShippingAddress(
        // Nouvelle adresse : identifiant unique basé sur l'heure.
        id:
            widget.existing?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        label: _labelCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        line: _lineCtrl.text.trim(),
      ),
    );
  }

  InputDecoration _decoration(String hint) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.white38),
      filled: true,
      fillColor: const Color(0xFF3A3A3A),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border,
      enabledBorder: border,
      errorStyle: GoogleFonts.poppins(fontSize: 10, color: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.poppins(fontSize: 12, color: Colors.white);

    return Padding(
      // Remonte la feuille quand le clavier s'ouvre.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: const BoxDecoration(
          color: _cardDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.existing == null ? 'Add new address' : 'Edit address',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                // Titre facultatif (ex. "Home Address").
                TextFormField(
                  controller: _labelCtrl,
                  style: style,
                  textCapitalization: TextCapitalization.words,
                  decoration: _decoration(
                    'Title (optional, e.g. Home Address)',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  style: style,
                  keyboardType: TextInputType.phone,
                  decoration: _decoration('Phone number'),
                  validator: (v) => (v == null || v.trim().length < 6)
                      ? 'Enter a valid phone number'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lineCtrl,
                  style: style,
                  textCapitalization: TextCapitalization.words,
                  decoration: _decoration('Street, city, country'),
                  validator: (v) => (v == null || v.trim().length < 5)
                      ? 'Enter the full address'
                      : null,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _amber,
                      foregroundColor: _ink,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _save,
                    child: Text(
                      'Save',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Formatage des champs de carte ─────────────────────────

/// Numéro de carte : chiffres uniquement, 16 maximum, groupés par 4
/// ("0145 0145 0145 0145").
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 16) digits = digits.substring(0, 16);

    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Date d'expiration : chiffres uniquement, 4 maximum, saisis comme "MM/YY"
/// (le "/" est ajouté automatiquement).
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 4) digits = digits.substring(0, 4);

    final text = digits.length > 2
        ? '${digits.substring(0, 2)}/${digits.substring(2)}'
        : digits;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
