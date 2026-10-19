import 'dart:math';

/// Modes de paiement proposés sur l'écran Address.
enum PaymentMethod { mastercard, visa, paypal }

/// Adresse de livraison.
class ShippingAddress {
  final String id;
  final String label; // ex. "Home Address" (peut être vide)
  final String phone;
  final String line; // adresse postale complète

  const ShippingAddress({
    required this.id,
    required this.phone,
    required this.line,
    this.label = '',
  });

  ShippingAddress copyWith({String? label, String? phone, String? line}) =>
      ShippingAddress(
        id: id,
        label: label ?? this.label,
        phone: phone ?? this.phone,
        line: line ?? this.line,
      );
}

/// Informations de carte saisies par l'utilisateur.
/// ATTENTION : ces données sont sensibles. Ne les enregistrez jamais en clair
/// (ni en base, ni dans les journaux) ; en production, passez par le SDK d'un
/// prestataire de paiement (Stripe, etc.) qui les transforme en jeton.
class CardDetails {
  final String holderName;
  final String number; // chiffres uniquement, sans espaces
  final String expiry; // format MM/YY
  final String cvv;

  const CardDetails({
    required this.holderName,
    required this.number,
    required this.expiry,
    required this.cvv,
  });
}

/// Tout ce dont le service a besoin pour traiter un paiement.
class PaymentRequest {
  final double amount;
  final PaymentMethod method;
  final ShippingAddress address;
  final CardDetails? card; // null pour PayPal

  const PaymentRequest({
    required this.amount,
    required this.method,
    required this.address,
    this.card,
  });
}

/// Résultat d'un paiement : accepté (avec un numéro de commande) ou refusé.
class PaymentResult {
  final bool success;
  final String? orderNumber;
  final String? message;

  const PaymentResult.success(this.orderNumber)
      : success = true,
        message = null;

  const PaymentResult.declined([this.message])
      : success = false,
        orderNumber = null;
}

/// Contrat d'un service de paiement. L'écran Address ne dépend que de ce
/// contrat : pour brancher un vrai prestataire, créez une classe qui
/// l'implémente et passez-la à `AddressScreen(paymentService: ...)`.
abstract class PaymentService {
  Future<PaymentResult> pay(PaymentRequest request);
}

/// Service de paiement FICTIF pour développer et tester l'interface.
/// - Il attend 1,5 seconde pour simuler un traitement.
/// - Il REFUSE toute carte dont le numéro se termine par 0000
///   (pratique pour tester l'écran "Oops").
/// - Il accepte tout le reste et génère un numéro de commande.
class MockPaymentService implements PaymentService {
  @override
  Future<PaymentResult> pay(PaymentRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 1500));

    final card = request.card;
    if (card != null && card.number.endsWith('0000')) {
      return const PaymentResult.declined(
        'Payment has been declined. Please try again to proceed with your order.',
      );
    }

    final orderNumber = '#${100000000 + Random().nextInt(900000000)}';
    return PaymentResult.success(orderNumber);
  }
}