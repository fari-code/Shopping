import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'cart_screen.dart';
import 'product_detail.dart';
import 'shopping.dart';

// ───────────────────────── Constantes de style ─────────────────────────

const _ink = Color(0xFF1C1A17); // texte principal (noir chaud)
const _muted = Color(0xFF8A5A00); // texte secondaire (brun/orangé)
const _amberDark = Color(0xFFF59A00); // orange des boutons "+" et des étoiles
const _cardDark = Color(0xFF262626); // fond des cartes sombres
const _chipGrey = Color(0xFFEDEDED); // fond des puces de recherche
const _currency = r'$';

/// Réduction appliquée à la section "Flat 20% Sale".
const _saleDiscount = 0.20;

/// Texte d'indication de la barre de recherche (identique à la maquette).
const _kSearchHint = 'Search games';

/// Mots ignorés dans la recherche ("Shoes For Men" -> "shoes", "men").
const _stopWords = {'for', 'the', 'and', 'of', 'in', 'with'};

/// Les 3 états de l'écran, tels qu'on les voit sur les maquettes :
/// - home        : fond blanc, "Recently Searches" + "Popular Searches"
/// - suggestions : fond orange, sections de produits (pendant la saisie)
/// - results     : fond orange, liste "Search Result" (après validation)
enum _SearchMode { home, suggestions, results }

class Search extends StatefulWidget {
  /// Source des produits. Par défaut : les données fictives locales.
  /// Passez votre propre implémentation quand votre API sera prête.
  final ShoppingRepository? repository;

  const Search({super.key, this.repository});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final TextEditingController _controller = TextEditingController();

  /// Clé globale sur la barre de recherche : elle permet à Flutter de
  /// conserver le TextField (et le focus du clavier) quand l'écran passe
  /// de l'état "home" aux états orange, où l'on ajoute un en-tête au-dessus.
  /// Sans cette clé, le clavier se fermerait dès la première lettre tapée.
  final GlobalKey _searchBarKey = GlobalKey();

  late final ShoppingRepository _repo =
      widget.repository ?? MockShoppingRepository();

  _SearchMode _mode = _SearchMode.home;

  // ── Données chargées depuis le repository ──
  List<ShoppingProduct> _featured = [];
  List<ShoppingProduct> _best = [];
  Map<String, String> _categoryNames = {}; // id de catégorie -> nom
  bool _loading = true;
  Object? _error;

  /// Texte réellement recherché (figé au moment de la validation).
  String _activeQuery = '';

  final List<String> _recentSearches = [
    'Jackets',
    'Shoes For Men',
    'Watches',
    'Gadgets',
    'Wedding Suits',
    'Mobile',
    'Laptops',
    'Handfree',
    'Mouse',
    'Lights',
  ];

  final List<String> _popularSearches = [
    'Jackets',
    'Shoes For Men',
    'Watches',
    'Gadgets',
    'Jackets',
    'Home Decoration',
    'Lounge Decor',
    'Winter',
    'Shoes For Men',
    'Watches',
    'Wedding Suits',
    'Summer',
    'Shoes For Men',
    'Room Lights',
    'Wedding Suits',
    'Shorts',
    'Dresses',
    'Gadgets',
    'Wedding Suits',
  ];

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ───────────────────────── Chargement des données ─────────────────────────

  /// Charge les produits et les catégories (en parallèle).
  Future<void> _loadCatalog() async {
    try {
      final results = await Future.wait<Object>([
        _repo.fetchFeatured(),
        _repo.fetchBestSells(),
        _repo.fetchCategories(),
      ]);
      if (!mounted) return;
      setState(() {
        _featured = results[0] as List<ShoppingProduct>;
        _best = results[1] as List<ShoppingProduct>;
        _categoryNames = {
          for (final c in results[2] as List<ShoppingCategory>) c.id: c.name,
        };
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  /// Relance le chargement après une erreur (bouton "Retry").
  void _retry() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _loadCatalog();
  }

  /// Tous les produits sans doublon (vedettes + meilleures ventes).
  List<ShoppingProduct> get _catalog {
    final seen = <String>{};
    return [
      for (final p in [..._featured, ..._best])
        if (seen.add(p.id)) p,
    ];
  }

  // ───────────────────────── Moteur de recherche ─────────────────────────

  /// Découpe la recherche en mots-clés utiles :
  /// minuscules, sans ponctuation, sans mots vides, au singulier simplifié
  /// ("T shirts" -> ["shirt"], "Jackets" -> ["jacket"]).
  List<String> _tokens(String query) {
    final tokens = <String>[];
    for (final raw in query.toLowerCase().split(RegExp(r'\s+'))) {
      var token = raw.replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (token.length < 2 || _stopWords.contains(token)) continue;
      if (token.length > 3 && token.endsWith('s')) {
        token = token.substring(0, token.length - 1); // pluriel -> singulier
      }
      tokens.add(token);
    }
    return tokens;
  }

  /// Cherche [query] dans le nom et la catégorie des produits de [source].
  /// Les produits sont triés par pertinence (nombre de mots-clés trouvés),
  /// puis dans leur ordre d'origine.
  List<ShoppingProduct> _search(List<ShoppingProduct> source, String query) {
    final text = query.trim();
    if (text.isEmpty) return source;

    final tokens = _tokens(text);
    // Si la saisie ne contient que des mots trop courts ("t"), on cherche
    // simplement le texte brut.
    final fallback = text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    final scored = <({ShoppingProduct product, int score, int index})>[];
    for (var i = 0; i < source.length; i++) {
      final p = source[i];
      // Texte dans lequel on cherche : nom + catégorie, sans espaces ni tirets
      // (ainsi "T-Shirt" devient "tshirt").
      final haystack = '${p.name} ${_categoryNames[p.categoryId] ?? ''}'
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '');

      final score = tokens.isEmpty
          ? (haystack.contains(fallback) ? 1 : 0)
          : tokens.where((t) => haystack.contains(t)).length;
      if (score > 0) scored.add((product: p, score: score, index: i));
    }

    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      return byScore != 0 ? byScore : a.index.compareTo(b.index);
    });
    return [for (final s in scored) s.product];
  }

  /// Prix après réduction, arrondi à 2 décimales.
  double _discounted(double price) =>
      double.parse((price * (1 - _saleDiscount)).toStringAsFixed(2));

  // ───────────────────────── Actions ─────────────────────────

  /// Appelé à chaque lettre tapée : champ vide = écran d'accueil,
  /// sinon on affiche les suggestions (filtrées en direct).
  void _onChanged(String value) {
    setState(() {
      _mode = value.trim().isEmpty ? _SearchMode.home : _SearchMode.suggestions;
    });
  }

  /// Lance la recherche (validation du clavier, clic sur une puce
  /// ou sur "See all") et affiche la liste des résultats.
  void _performSearch(String query) {
    final text = query.trim();
    if (text.isEmpty) {
      setState(() => _mode = _SearchMode.home);
      return;
    }
    FocusScope.of(context).unfocus(); // ferme le clavier
    setState(() {
      _activeQuery = text;
      // On remonte la recherche en tête de l'historique (sans doublon).
      _recentSearches.remove(text);
      _recentSearches.insert(0, text);
      if (_recentSearches.length > 10) _recentSearches.removeLast();
      _mode = _SearchMode.results;
    });
  }

  /// Flèche retour : depuis les états orange on revient à l'accueil de la
  /// recherche ; depuis l'accueil on quitte l'écran.
  void _goBack() {
    if (_mode == _SearchMode.home) {
      Navigator.maybePop(context);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _controller.clear();
      _mode = _SearchMode.home;
    });
  }

  void _openProduct(ShoppingProduct product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProductDetailScreen(product: product, currency: _currency),
      ),
    );
  }

  void _addToCart(ShoppingProduct product) {
    // Ajoute au panier partagé avec la taille et la couleur par défaut.
    CartController.instance.add(
      product: product,
      size: product.sizes.isNotEmpty ? product.sizes.first : null,
      colour: product.colours.isNotEmpty ? product.colours.first : null,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
        duration: const Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ───────────────────────── Construction de l'écran ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final isHome = _mode == _SearchMode.home;

    return Scaffold(
      body: Container(
        // Fond blanc sur l'accueil, dégradé jaune → orange sur les autres états.
        decoration: isHome
            ? const BoxDecoration(color: Colors.white)
            : const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFD400), Color(0xFFFFB000), _amberDark],
            stops: [0, .35, 1],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête "Search" avec flèche retour (états orange uniquement).
              if (!isHome) _header(),
              Padding(
                key: _searchBarKey,
                padding: EdgeInsets.fromLTRB(16, isHome ? 16 : 8, 16, 0),
                child: AppSearchBar(
                  controller: _controller,
                  hint: _kSearchHint,
                  // Barre blanche sans bordure sur fond orange,
                  // grise avec bordure sur fond blanc.
                  backgroundColor: isHome ? _chipGrey : Colors.white,
                  borderColor: isHome ? const Color(0xFFC9C9C9) : null,
                  onChanged: _onChanged,
                  onSubmitted: _performSearch,
                  onMicTap: () {
                    // TODO: recherche vocale
                  },
                  onCameraTap: () {
                    // TODO: recherche par image
                  },
                ),
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  /// Choisit le contenu selon l'état et l'avancement du chargement.
  Widget _buildBody() {
    if (_mode == _SearchMode.home) return _buildHome();
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _ink));
    }
    if (_error != null) return _errorView();
    return _mode == _SearchMode.suggestions
        ? _buildSuggestions()
        : _buildResults();
  }

  /// En-tête : flèche retour à gauche, titre centré.
  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: _ink),
            onPressed: _goBack,
          ),
          Expanded(
            child: Center(
              child: Text(
                'Search',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
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

  /// Message d'erreur avec bouton pour réessayer.
  Widget _errorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Unable to load products.',
            style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w500, color: _ink),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _retry,
            style: FilledButton.styleFrom(backgroundColor: _ink),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Message affiché quand aucun produit ne correspond à la recherche.
  Widget _emptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 48, color: _ink),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w500, color: _ink),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── État 1 : accueil ─────────────────────────

  Widget _buildHome() {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // La section "Recently Searches" disparaît si l'historique est vide.
          if (_recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recently Searches',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(_recentSearches.clear),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'clear all',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _chips(_recentSearches),
            const SizedBox(height: 24),
          ],
          Text(
            'Popular Searches',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          _chips(_popularSearches),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  /// Liste de puces grises ; un clic remplit la barre et lance la recherche.
  Widget _chips(List<String> terms) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final term in terms)
          InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () {
              _controller.text = term;
              _performSearch(term);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: _chipGrey,
                borderRadius: BorderRadius.circular(4), // coins peu arrondis
              ),
              child: Text(
                term,
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  color: const Color(0xFF555555),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ───────────────────────── État 2 : suggestions ─────────────────────────

  Widget _buildSuggestions() {
    final query = _controller.text;

    // Chaque section a sa propre source de produits, filtrée par la saisie.
    final sections = <({String title, List<ShoppingProduct> items})>[
      // Tous les produits correspondant à la saisie.
      (title: 'Popular', items: _search(_catalog, query)),
      // Produits vedettes avec 20 % de réduction sur le prix.
      (
      title: 'Flat 20% Sale',
      items: [
        for (final p in _search(_featured, query))
          p.copyWith(price: _discounted(p.price)),
      ],
      ),
      // Meilleures ventes.
      (title: 'High Orders', items: _search(_best, query)),
      // Produits vedettes.
      (title: 'Featured Products', items: _search(_featured, query)),
    ].where((section) => section.items.isNotEmpty).toList();

    // Rien ne correspond : on le dit à l'utilisateur.
    if (sections.isEmpty) {
      return _emptyState('No products found for "${query.trim()}".');
    }

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        for (final section in sections) ...[
          _sectionHeader(section.title),
          _productRow(section.items),
        ],
      ],
    );
  }

  /// Titre de section + lien "See all" (lance la recherche avec le texte saisi).
  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          GestureDetector(
            onTap: () => _performSearch(_controller.text),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'See all',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Rangée horizontale de produits (défilement latéral).
  Widget _productRow(List<ShoppingProduct> items) {
    return SizedBox(
      height: 172,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) => _SuggestionCard(
          product: items[index],
          onTap: () => _openProduct(items[index]),
          onAdd: () => _addToCart(items[index]),
        ),
      ),
    );
  }

  // ───────────────────────── État 3 : résultats ─────────────────────────

  Widget _buildResults() {
    // Résultats réels, calculés à partir du texte validé.
    final results = _search(_catalog, _activeQuery);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Search Result',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              // Présent sur la maquette ; tous les résultats sont déjà
              // affichés, donc pas d'action pour l'instant.
              Text(
                'See all',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: results.isEmpty
              ? _emptyState('No results found for "$_activeQuery".')
              : ListView.separated(
            keyboardDismissBehavior:
            ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: results.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) => _ResultCard(
              product: results[index],
              categoryName: _categoryNames[results[index].categoryId],
              onTap: () => _openProduct(results[index]),
            ),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── Widgets internes ─────────────────────────

/// Formate un prix : "20" si entier, "19.99" sinon.
String _formatPrice(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2);

/// Carte produit des sections de suggestions :
/// image, bouton "+", nom (petit) et prix (gros).
class _SuggestionCard extends StatelessWidget {
  final ShoppingProduct product;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const _SuggestionCard({
    required this.product,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 120,
              height: 120,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0x22000000),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (product.imageUrl != null && product.imageUrl!.isNotEmpty)
                    Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      // Si l'image ne charge pas : simple icône de remplacement.
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.image_outlined,
                            color: Colors.white70, size: 32),
                      ),
                    ),
                  // Bouton "+" en haut à droite.
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onAdd,
                      child: Container(
                        width: 21,
                        height: 21,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _amberDark,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          '+',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      color: _muted,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.bottomRight,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          // Le symbole "$" est plus petit que le montant.
                          TextSpan(
                            text: _currency,
                            style: const TextStyle(fontSize: 13),
                          ),
                          TextSpan(text: _formatPrice(product.price)),
                        ],
                      ),
                      maxLines: 1,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte d'un résultat de recherche (carte sombre) :
/// image à gauche, nom + couleurs + tailles, étoiles en haut à droite,
/// prix en bas à droite. Les infos absentes du produit sont masquées.
class _ResultCard extends StatelessWidget {
  final ShoppingProduct product;
  final String? categoryName;
  final VoidCallback onTap;

  const _ResultCard({
    required this.product,
    required this.onTap,
    this.categoryName,
  });

  /// Ligne "Label: valeurs" avec le label en gris et les valeurs en blanc.
  Widget _infoLine(String label, List<String> values) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label  ',
            style: TextStyle(color: Colors.grey[500]),
          ),
          TextSpan(
            text: values.join(', '),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ],
      ),
      style: GoogleFonts.poppins(fontSize: 10),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasDetails = product.colours.isNotEmpty || product.sizes.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 88,
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
                width: 66,
                height: double.infinity,
                child: Image.network(
                  product.imageUrl ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.white12,
                    child:
                    const Icon(Icons.image_outlined, color: Colors.white54),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 6, 8, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ligne du haut : nom à gauche, étoiles à droite.
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        // Étoiles affichées seulement si le produit est noté.
                        if (product.rating > 0) ...[
                          const SizedBox(width: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              5,
                                  (i) => Icon(
                                Icons.star,
                                size: 11,
                                // Étoile orange si i < note, grisée sinon.
                                color: i < product.rating.round()
                                    ? _amberDark
                                    : Colors.white24,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Spacer(),
                    // Ligne du bas : infos à gauche, prix à droite.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (product.colours.isNotEmpty)
                                _infoLine('Colour:', product.colours),
                              if (product.colours.isNotEmpty &&
                                  product.sizes.isNotEmpty)
                                const SizedBox(height: 2),
                              if (product.sizes.isNotEmpty)
                                _infoLine('Size:', product.sizes),
                              // Produit sans couleur ni taille (ex. laptop) :
                              // on affiche sa catégorie à la place.
                              if (!hasDetails && categoryName != null)
                                _infoLine('Category:', [categoryName!]),
                            ],
                          ),
                        ),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: _currency,
                                style: const TextStyle(fontSize: 11),
                              ),
                              TextSpan(text: _formatPrice(product.price)),
                            ],
                          ),
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Barre de recherche réutilisable (loupe, champ texte, micro, appareil photo).
/// Les couleurs sont personnalisables pour s'adapter au fond de l'écran.
class AppSearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onMicTap;
  final VoidCallback? onCameraTap;
  final TextEditingController? controller;
  final Widget searchIcon;
  final Widget micIcon;
  final Widget cameraIcon;

  /// Couleur de fond de la barre.
  final Color backgroundColor;

  /// Couleur de la bordure (null = pas de bordure).
  final Color? borderColor;

  const AppSearchBar({
    super.key,
    this.hint = 'Search',
    this.onChanged,
    this.onSubmitted,
    this.onMicTap,
    this.onCameraTap,
    this.controller,
    this.backgroundColor = const Color(0xFFEDEDED),
    this.borderColor = const Color(0xFFC9C9C9),
    this.searchIcon =
    const Icon(Icons.search, size: 26, color: Color(0xFF1C1C1C)),
    this.micIcon = const Icon(Icons.mic, size: 18, color: Color(0xFF1C1C1C)),
    this.cameraIcon =
    const Icon(Icons.camera_alt, size: 20, color: Color(0xFF1C1C1C)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: Row(
        children: [
          searchIcon,
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: const Color(0xFF1C1C1C)),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.poppins(
                    fontSize: 11.5, color: const Color(0xFF6B6B6B)),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onMicTap,
            child: Padding(padding: const EdgeInsets.all(4), child: micIcon),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onCameraTap,
            child: Padding(padding: const EdgeInsets.all(4), child: cameraIcon),
          ),
        ],
      ),
    );
  }
}