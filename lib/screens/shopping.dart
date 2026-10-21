import 'package:flutter/material.dart';
import 'product_detail.dart';
import 'cart_screen.dart';

const _ink = Color(0xFF1C1A17);
const _muted = Color(0xFF8A5A00);
const _amberDark = Color(0xFFF59A00);
const _barColor = Color(0xFF1B1B1B);

// Texts taken from the mockup (easy to change in one place).
const _kSearchHint = 'Search games';

class ShoppingCategory {
  final String id;
  final String name;
  final String? imageUrl;

  const ShoppingCategory({
    required this.id,
    required this.name,
    this.imageUrl,
  });

  factory ShoppingCategory.fromJson(Map<String, dynamic> json) =>
      ShoppingCategory(
        id: '${json['id']}',
        name: json['name']?.toString() ?? '',
        imageUrl: json['image']?.toString(),
      );
}

class ShoppingProduct {
  final String id;
  final String name;
  final double price;
  final String? imageUrl;
  final String? categoryId;

  /// Couleurs disponibles (vide = non applicable, ex. un laptop).
  final List<String> colours;

  /// Tailles disponibles (vide = non applicable).
  final List<String> sizes;

  /// Note moyenne sur 5 (0 = pas encore noté, les étoiles sont masquées).
  final double rating;

  /// Nombre d'avis clients (0 = aucun, le texte "Reviews" est masqué).
  final int reviewCount;

  /// Description du produit (null/vide = section masquée).
  final String? description;

  /// Nom de la boutique qui vend le produit (null = masqué).
  final String? storeName;

  const ShoppingProduct({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
    this.categoryId,
    this.colours = const [],
    this.sizes = const [],
    this.rating = 0,
    this.reviewCount = 0,
    this.description,
    this.storeName,
  });

  factory ShoppingProduct.fromJson(Map<String, dynamic> json) =>
      ShoppingProduct(
        id: '${json['id']}',
        name: json['name']?.toString() ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        imageUrl: json['image']?.toString(),
        categoryId: json['category_id']?.toString(),
        colours:
        (json['colours'] as List?)?.map((e) => '$e').toList() ?? const [],
        sizes: (json['sizes'] as List?)?.map((e) => '$e').toList() ?? const [],
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
        description: json['description']?.toString(),
        storeName: json['store_name']?.toString(),
      );

  /// Copie du produit avec un autre prix (utile pour les promotions).
  ShoppingProduct copyWith({double? price}) => ShoppingProduct(
    id: id,
    name: name,
    price: price ?? this.price,
    imageUrl: imageUrl,
    categoryId: categoryId,
    colours: colours,
    sizes: sizes,
    rating: rating,
    reviewCount: reviewCount,
    description: description,
    storeName: storeName,
  );
}

abstract class ShoppingRepository {
  Future<List<ShoppingCategory>> fetchCategories();
  Future<List<ShoppingProduct>> fetchFeatured();
  Future<List<ShoppingProduct>> fetchBestSells();
}

/// Local mock data: no API or Internet connection needed.
/// Replace this repository with an API implementation once your backend
/// is ready.
class MockShoppingRepository implements ShoppingRepository {
  static const _categories = <ShoppingCategory>[
    ShoppingCategory(
      id: 'apparel',
      name: 'Apparel',
      imageUrl:
      'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=300',
    ),
    ShoppingCategory(
      id: 'shoes',
      name: 'Shoes',
      imageUrl:
      'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=300',
    ),
    ShoppingCategory(
      id: 'phones',
      name: 'Phones',
      imageUrl:
      'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=300',
    ),
    ShoppingCategory(
      id: 'tech',
      name: 'Tech',
      imageUrl:
      'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=300',
    ),
    ShoppingCategory(
      id: 'home',
      name: 'Home',
      imageUrl:
      'https://images.unsplash.com/photo-1503602642458-232111445657?w=300',
    ),
    ShoppingCategory(
      id: 'sports',
      name: 'Sports',
      imageUrl:
      'https://images.unsplash.com/photo-1517649763962-0c6232660102?w=300',
    ),
    ShoppingCategory(
      id: 'beauty',
      name: 'Beauty',
      imageUrl:
      'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=300',
    ),
    ShoppingCategory(
      id: 'gaming',
      name: 'Gaming',
      imageUrl:
      'https://images.unsplash.com/photo-1612287230202-1ff1d85d1bdf?w=300',
    ),
  ];

  static const _featured = <ShoppingProduct>[
    ShoppingProduct(
      id: 'p1',
      name: 'Branded Shoes',
      price: 25,
      categoryId: 'shoes',
      colours: ['Black', 'White'],
      sizes: ['40', '41', '42', '43'],
      rating: 4,
      reviewCount: 320,
      storeName: 'Sneaker House',
      description: 'Comfortable branded shoes for everyday wear, with a light sole and breathable upper.',
      imageUrl:
      'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=500',
    ),
    ShoppingProduct(
      id: 'p2',
      name: 'Branded T-Shirt',
      price: 20,
      categoryId: 'apparel',
      colours: ['Black', 'White', 'Cyan', 'Magenta', 'Green'],
      sizes: ['S', 'M', 'L', 'XL'],
      rating: 5,
      reviewCount: 1000,
      storeName: 'Garments Store',
      description:
      'Phasellus ipsum sed arcu nisl. Mattis lobortis in donec malesuada et mollis pellentesque volutpat. Ut bibendum sollicitudin pulvinar quis quis ultricies. Fringilla sit nibh phasellus enim aliquet cursus gravida ultrices scelerisque. Vitae quis dictumst eget non quam vulputate. Felis egestas vitae lectus ut pellentesque.',
      imageUrl:
      'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=500',
    ),
    ShoppingProduct(
      id: 'p3',
      name: 'RayBen Glasses',
      price: 5,
      categoryId: 'apparel',
      imageUrl:
      'https://images.unsplash.com/photo-1511499767150-a48a237f0083?w=500',
    ),
    ShoppingProduct(
      id: 'p4',
      name: 'Casio Watch',
      price: 35,
      categoryId: 'tech',
      imageUrl:
      'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=500',
    ),
    ShoppingProduct(
      id: 'p5',
      name: 'Bag',
      price: 45,
      categoryId: 'tech',
      imageUrl:
      'https://images.unsplash.com/photo-1590874103328-eac38a683ce7?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=NHwxMjA3fDA%3D',
    ),
    ShoppingProduct(
      id: 'p6',
      name: 'Talon',
      price: 20,
      categoryId: 'shoes',
      imageUrl:
      'https://images.unsplash.com/photo-1535043934128-cf0b28d52f95?q=80&w=870&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=NHwxMjA3fDA%3D',
    ),
    ShoppingProduct(
      id: 'p9',
      name: 'Nike Air Max',
      price: 110,
      categoryId: 'shoes',
      colours: ['White', 'Black'],
      sizes: ['40', '41', '42', '43', '44'],
      rating: 5,
      reviewCount: 850,
      storeName: 'Sneaker House',
      description: 'Iconic Air Max cushioning with a bold design, made for all-day comfort.',
      imageUrl:
      'https://images.unsplash.com/photo-1584735935682-2f2b69dff9d2?w=500',
    ),
    ShoppingProduct(
      id: 'p10',
      name: 'Leather Jacket',
      price: 150,
      categoryId: 'apparel',
      colours: ['Black', 'Brown'],
      sizes: ['M', 'L', 'XL'],
      rating: 4,
      reviewCount: 210,
      storeName: 'Garments Store',
      description: 'Classic leather jacket with a soft lining and a timeless fit.',
      imageUrl:
      'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=500',
    ),
    ShoppingProduct(
      id: 'p11',
      name: 'iPhone 15 Pro',
      price: 999,
      categoryId: 'phones',
      imageUrl:
      'https://images.unsplash.com/photo-1695048133142-1a20484d2569?w=500',
    ),
    ShoppingProduct(
      id: 'p12',
      name: 'Sony Headphones',
      price: 299,
      categoryId: 'tech',
      imageUrl:
      'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=500',
    ),
    ShoppingProduct(
      id: 'p13',
      name: 'Desk Lamp',
      price: 45,
      categoryId: 'home',
      imageUrl:
      'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?w=500',
    ),
    ShoppingProduct(
      id: 'p14',
      name: 'Gaming Keyboard',
      price: 89,
      categoryId: 'gaming',
      imageUrl:
      'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=500',
    ),
  ];

  static const _bestSells = <ShoppingProduct>[
    ShoppingProduct(
      id: 'p15',
      name: 'Dell New Laptop',
      price: 2500,
      categoryId: 'tech',
      imageUrl:
      'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=500',
    ),
    ShoppingProduct(
      id: 'p16',
      name: 'Sitting Chair',
      price: 75,
      categoryId: 'home',
      imageUrl:
      'https://images.unsplash.com/photo-1503602642458-232111445657?w=500',
    ),
    ShoppingProduct(
      id: 'p17',
      name: 'Hanging Mirror',
      price: 50,
      categoryId: 'home',
      imageUrl:
      'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?w=500',
    ),
    ShoppingProduct(
      id: 'p18',
      name: 'Apple AirPods',
      price: 120,
      categoryId: 'phones',
      imageUrl:
      'https://images.unsplash.com/photo-1606220945770-b5b6c2c55bf1?w=500',
    ),
    ShoppingProduct(
      id: 'p19',
      name: 'Espresso Machine',
      price: 350,
      categoryId: 'home',
      imageUrl:
      'https://images.unsplash.com/photo-1517668808822-9402f2db04b3?w=500',
    ),
    ShoppingProduct(
      id: 'p20',
      name: 'Smart Watch',
      price: 199,
      categoryId: 'tech',
      imageUrl:
      'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=500',
    ),
    ShoppingProduct(
      id: 'p21',
      name: 'Running Backpack',
      price: 65,
      categoryId: 'sports',
      imageUrl:
      'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=500',
    ),
    ShoppingProduct(
      id: 'p22',
      name: 'Bluetooth Speaker',
      price: 80,
      categoryId: 'tech',
      imageUrl:
      'https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?w=500',
    ),
  ];

  // Simulates a small network delay to test the loading state.
  Future<T> _fakeRequest<T>(T data) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return data;
  }

  @override
  Future<List<ShoppingCategory>> fetchCategories() =>
      _fakeRequest(_categories);

  @override
  Future<List<ShoppingProduct>> fetchFeatured() => _fakeRequest(_featured);

  @override
  Future<List<ShoppingProduct>> fetchBestSells() =>
      _fakeRequest(_bestSells);
}

// ───────────────────────── Icons ─────────────────────────

class ShoppingIcons {
  final Widget? back, menu, cart, search, mic, camera;
  final Widget? add, added;
  final Widget? navHome, navCart, navMedia, navChat, fab;

  const ShoppingIcons({
    this.back,
    this.menu,
    this.cart,
    this.search,
    this.mic,
    this.camera,
    this.add,
    this.added,
    this.navHome,
    this.navCart,
    this.navMedia,
    this.navChat,
    this.fab,
  });

  /// Default icons to get started quickly.
  /// You can replace them with your own icons/SVGs.
  factory ShoppingIcons.defaults() => const ShoppingIcons(
    back: Icon(Icons.arrow_back, size: 26, color: _ink),
    menu: Icon(Icons.menu, size: 26, color: _ink),
    cart: Icon(Icons.shopping_cart, size: 27, color: _ink),
    search: Icon(Icons.search, size: 21, color: _ink),
    mic: Icon(Icons.mic, size: 19, color: _ink),
    camera: Icon(Icons.camera_alt, size: 20, color: _ink),
    add: Text('+',
        style: TextStyle(
            color: _ink, fontSize: 15, fontWeight: FontWeight.w700)),
    added: Icon(Icons.check, size: 14, color: Colors.white),
    navHome: Icon(Icons.home_filled, size: 26, color: Colors.white),
    navCart: Icon(Icons.shopping_cart, size: 26, color: _amberDark),
    navMedia: Icon(Icons.movie_filter, size: 26, color: Colors.white),
    navChat: Icon(Icons.chat, size: 26, color: Colors.white),
    fab: Icon(Icons.add, size: 30, color: Colors.white),
  );
}

// ───────────────────────── Shopping page ─────────────────────────

class ShoppingPage extends StatefulWidget {
  final ShoppingRepository repository;
  final ShoppingIcons icons;
  final String currency;
  final VoidCallback? onBack;
  final VoidCallback? onCartTap;
  final VoidCallback? onFabTap;
  final ValueChanged<ShoppingProduct>? onProductTap;
  final ValueChanged<ShoppingProduct>? onAddToCart;

  const ShoppingPage({
    super.key,
    required this.repository,
    this.icons = const ShoppingIcons(),
    this.currency = r'$',
    this.onBack,
    this.onCartTap,
    this.onFabTap,
    this.onProductTap,
    this.onAddToCart,
  });

  @override
  State<ShoppingPage> createState() => _ShoppingPageState();
}

class _ShoppingPageState extends State<ShoppingPage> {
  List<ShoppingCategory> _categories = [];
  List<ShoppingProduct> _featured = [];
  List<ShoppingProduct> _best = [];
  bool _loading = true;
  Object? _error;
  String _catId = 'all';
  String _query = '';
  /// Nombre d'articles du panier partagé (valeur du badge).
  int get _cartCount => CartController.instance.itemCount;

  @override
  void initState() {
    super.initState();
    // Met à jour le badge dès que le panier change.
    CartController.instance.addListener(_onCartChanged);
    _load();
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    CartController.instance.removeListener(_onCartChanged);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait<Object>([
        widget.repository.fetchCategories(),
        widget.repository.fetchFeatured(),
        widget.repository.fetchBestSells(),
      ]);
      if (!mounted) return;

      setState(() {
        _categories = results[0] as List<ShoppingCategory>;
        _featured = results[1] as List<ShoppingProduct>;
        _best = results[2] as List<ShoppingProduct>;
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

  List<ShoppingProduct> _filter(List<ShoppingProduct> list) => list.where((p) {
    final categoryMatches = _catId == 'all' || p.categoryId == _catId;
    final queryMatches = p.name.toLowerCase().contains(_query.toLowerCase());
    return categoryMatches && queryMatches;
  }).toList();

  void _add(ShoppingProduct product) {
    // Ajoute au panier partagé avec la taille et la couleur par défaut.
    CartController.instance.add(
      product: product,
      size: product.sizes.isNotEmpty ? product.sizes.first : null,
      colour: product.colours.isNotEmpty ? product.colours.first : null,
    );
    widget.onAddToCart?.call(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
        duration: const Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAll() {
    setState(() {
      _catId = 'all';
      _query = '';
    });
  }

  void _openCart() {
    if (widget.onCartTap != null) {
      widget.onCartTap!();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartScreen(currency: widget.currency),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final icons = widget.icons;
    return Scaffold(
      extendBody: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: widget.onFabTap,
        backgroundColor: const Color(0xFF2B2B2B),
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: icons.fab,
      ),
      bottomNavigationBar: BottomAppBar(
        color: _barColor,
        height: 64,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _iconSlot(icons.navHome),
            GestureDetector(
              onTap: _openCart,
              child: _iconSlot(icons.navCart),
            ),
            const SizedBox(width: 56),
            _iconSlot(icons.navMedia),
            _iconSlot(icons.navChat),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFD400), Color(0xFFFFB000), _amberDark],
            stops: [0, .35, 1],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _ink))
              : _error != null
              ? _errorView()
              : RefreshIndicator(
            color: _ink,
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 110),
              children: [
                _header(),
                _searchRow(),
                _section('Categories'),
                _categoryList(),
                _section('Featured Products'),
                _productList(_filter(_featured)),
                _section('Best sells'),
                _productList(_filter(_best)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconSlot(Widget? icon) =>
      SizedBox(width: 44, height: 44, child: Center(child: icon));

  Widget _errorView() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Unable to load products.',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _load,
            style: FilledButton.styleFrom(backgroundColor: _ink),
            child: const Text('Retry'),
          ),
        ],
      ),
    ),
  );

  Widget _header() {
    final icons = widget.icons;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack ?? () => Navigator.maybePop(context),
            child: _iconSlot(icons.back),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Shopping',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          GestureDetector(
            onTap: _openCart,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  if (icons.cart != null) icons.cart!,
                  // Small white badge, as on the mockup.
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      constraints:
                      const BoxConstraints(minWidth: 13, minHeight: 13),
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _cartCount > 99 ? '99+' : '$_cartCount',
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 7,
                          fontWeight: FontWeight.w600,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchRow() {
    final icons = widget.icons;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0x59282314),
              borderRadius: BorderRadius.circular(8),
            ),
            child: icons.menu,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/search'),
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    if (icons.search != null) ...[
                      icons.search!,
                      const SizedBox(width: 8),
                    ],
                    const Expanded(
                      child: AbsorbPointer(
                        child: TextField(
                          style: TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            hintText: _kSearchHint,
                            hintStyle: TextStyle(fontSize: 11),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                    if (icons.mic != null) ...[
                      icons.mic!,
                      const SizedBox(width: 8),
                    ],
                    if (icons.camera != null) icons.camera!,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700)),
        GestureDetector(
          onTap: _showAll,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text('See all',
                style:
                TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ),
      ],
    ),
  );

  Widget _categoryList() {
    final items = <ShoppingCategory>[
      const ShoppingCategory(id: 'all', name: 'All'),
      ..._categories.where((c) => c.id != 'all'),
    ];

    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) {
          final category = items[index];
          final selected = category.id == _catId;
          return GestureDetector(
            onTap: () => setState(() => _catId = category.id),
            child: SizedBox(
              width: 80,
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 80,
                    height: 80,
                    alignment: Alignment.center,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: const Color(0xFF232323),
                      borderRadius: BorderRadius.circular(12),
                      border:
                      selected ? Border.all(color: _ink, width: 3) : null,
                    ),
                    child: category.imageUrl != null &&
                        category.imageUrl!.isNotEmpty
                        ? _NetImage(category.imageUrl!, size: 80)
                    // "All" tile: list icon like on the mockup
                    // (no more dependency on assets/mask.png).
                        : const Icon(Icons.format_list_bulleted_rounded,
                        size: 44, color: _amberDark),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? _ink : _muted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _productList(List<ShoppingProduct> products) {
    if (products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          'No products found.',
          style: TextStyle(fontSize: 13, color: _muted),
        ),
      );
    }

    return SizedBox(
      height: 172,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) => _ProductCard(
          key: ValueKey(products[index].id),
          product: products[index],
          currency: widget.currency,
          addIcon: widget.icons.add,
          addedIcon: widget.icons.added,
          onTap: widget.onProductTap ??
                  (product) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailScreen(
                      product: product,
                      currency: widget.currency,
                    ),
                  ),
                );
              },
          onAdd: _add,
        ),
      ),
    );
  }
}

// ───────────────────────── Internal widgets ─────────────────────────

class _NetImage extends StatelessWidget {
  final String url;
  final double size;

  const _NetImage(this.url, {required this.size});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      color: const Color(0x22000000),
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, color: Colors.white70),
    );

    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) =>
      progress == null ? child : placeholder,
      errorBuilder: (_, __, ___) => placeholder,
    );
  }
}

class _ProductCard extends StatefulWidget {
  final ShoppingProduct product;
  final String currency;
  final Widget? addIcon;
  final Widget? addedIcon;
  final ValueChanged<ShoppingProduct>? onTap;
  final ValueChanged<ShoppingProduct> onAdd;

  const _ProductCard({
    super.key,
    required this.product,
    required this.currency,
    required this.onAdd,
    this.addIcon,
    this.addedIcon,
    this.onTap,
  });

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _added = false;

  Future<void> _add() async {
    widget.onAdd(widget.product);
    setState(() => _added = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => _added = false);
  }

  String get _price {
    final value = widget.product.price;
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return GestureDetector(
      onTap: widget.onTap == null ? null : () => widget.onTap!(product),
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
                  if (product.imageUrl != null &&
                      product.imageUrl!.isNotEmpty)
                    _NetImage(product.imageUrl!, size: 120)
                  else
                    const Center(
                        child: Icon(Icons.image_outlined,
                            color: Colors.white70, size: 32)),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _add,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 21,
                        height: 21,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _added ? _ink : _amberDark,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: _added
                            ? (widget.addedIcon ??
                            const Icon(Icons.check,
                                size: 14, color: Colors.white))
                            : (widget.addIcon ??
                            const Text(
                              '+',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            )),
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
                    style: const TextStyle(
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
                          TextSpan(
                            text: widget.currency,
                            style: const TextStyle(fontSize: 13),
                          ),
                          TextSpan(text: _price),
                        ],
                      ),
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
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