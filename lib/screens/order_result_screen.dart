import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ───────────────────────── Constantes de style ─────────────────────────

const _ink = Color(0xFF1C1A17); // texte principal
const _amber = Color(0xFFF59A00); // couleur du symbole dans le cercle
const _buttonDark = Color(0xFF262626); // boutons sombres
const _lime = Color(0xFF33FF00); // cercle de succès
const _red = Color(0xFFFF0000); // cercle d'échec
const _softText = Color(0xFF6B7A99); // texte d'explication gris-bleu

/// Titre affiché en haut de l'écran d'échec. La maquette utilise "Thanks"
/// aussi sur cet écran ; changez cette constante si vous préférez un autre mot.
const _kOopsTitle = 'Thanks';

/// Fond dégradé jaune → orange commun aux deux écrans.
const _gradient = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD400), Color(0xFFFFB000), _amber],
    stops: [0, .35, 1],
  ),
);

/// Retourne à l'accueil Shopping en vidant la pile de navigation.
void _goToShopping(BuildContext context) {
  Navigator.pushNamedAndRemoveUntil(context, '/shopping', (route) => false);
}

/// Écran affiché après un paiement réussi ("Thanks You").
class ThanksScreen extends StatelessWidget {
  /// Numéro de commande affiché dans le message (ex. "#254587166").
  final String orderNumber;

  /// Action du bouton "Continue Shopping". Par défaut : retour à l'accueil.
  final VoidCallback? onContinue;

  const ThanksScreen({super.key, required this.orderNumber, this.onContinue});

  @override
  Widget build(BuildContext context) {
    void continueShopping() =>
        onContinue != null ? onContinue!() : _goToShopping(context);

    // Le bouton retour du téléphone ramène à l'accueil au lieu de quitter
    // l'application (la pile de navigation a été vidée après le paiement).
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) continueShopping();
      },
      child: Scaffold(
        body: Container(
          decoration: _gradient,
          child: SafeArea(
            child: Column(
              children: [
                const _ScreenTitle('Thanks'),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: _ResultContent(
                        circleColor: _lime,
                        icon: Icons.check_rounded,
                        title: 'Thanks You',
                        message: orderNumber.isEmpty
                            ? 'Thanks for choosing us! Your order has been placed.'
                            : 'Thanks for choosing us! Your order has been placed under order number $orderNumber.',
                        withConfetti: true,
                      ),
                    ),
                  ),
                ),
                _BottomButton(label: 'Continue Shopping', onPressed: continueShopping),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Écran affiché quand le paiement est refusé ("Oops").
class OopsScreen extends StatelessWidget {
  /// Raison du refus (ex. renvoyée par le service de paiement).
  final String? message;

  const OopsScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: _gradient,
        child: SafeArea(
          child: Column(
            children: [
              // En-tête avec flèche retour (comme sur la maquette).
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: _ink),
                      onPressed: () => Navigator.maybePop(context),
                    ),
                    const Expanded(child: _ScreenTitle(_kOopsTitle, padded: false)),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: _ResultContent(
                      circleColor: _red,
                      icon: Icons.close_rounded,
                      title: 'Oops!',
                      message: message ??
                          'Payment has been declined. Please try again to proceed with your order.',
                    ),
                  ),
                ),
              ),
              // "Try Again" revient à l'écran de paiement (formulaire conservé).
              _BottomButton(
                label: 'Try Again',
                onPressed: () => Navigator.maybePop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Widgets internes ─────────────────────────

/// Titre centré en haut de l'écran.
class _ScreenTitle extends StatelessWidget {
  final String text;
  final bool padded;

  const _ScreenTitle(this.text, {this.padded = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: padded ? 20 : 0),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _ink,
          ),
        ),
      ),
    );
  }
}

/// Cercle coloré avec symbole + titre + message (partie centrale des 2 écrans).
class _ResultContent extends StatelessWidget {
  final Color circleColor;
  final IconData icon;
  final String title;
  final String message;
  final bool withConfetti; // petits points colorés autour du cercle

  const _ResultContent({
    required this.circleColor,
    required this.icon,
    required this.title,
    required this.message,
    this.withConfetti = false,
  });

  /// Petit point décoratif positionné dans la zone de 240×240.
  Widget _dot(Color color, double size, double left, double top) => Positioned(
    left: left,
    top: top,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 240,
            height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (withConfetti) ...[
                  _dot(const Color(0xFF1E6BFF), 12, 0, 40),
                  _dot(const Color(0xFFFF00FF), 14, 160, 6),
                  _dot(const Color(0xFFFF3B00), 18, 4, 160),
                  _dot(Colors.red, 9, 214, 132),
                ],
                // Le cercle apparaît avec un léger effet de rebond.
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.elasticOut,
                  builder: (_, value, child) =>
                      Transform.scale(scale: value, child: child),
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration:
                    BoxDecoration(color: circleColor, shape: BoxShape.circle),
                    child: Icon(icon, size: 100, color: _amber),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 30,
              fontWeight: FontWeight.w600,
              color: _ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _softText,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bouton sombre en bas de l'écran, avec ombre portée.
class _BottomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _BottomButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 8, 40, 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
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
                  backgroundColor: _buttonDark,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: onPressed,
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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