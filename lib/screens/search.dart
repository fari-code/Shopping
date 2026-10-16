import 'package:flutter/material.dart';

class Search extends StatelessWidget {
  const Search({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSearchBar(
                hint: 'Search games',
                onChanged: (value) {
                  // Filtrer ou appeler votre API ici
                },
                onMicTap: () {},
                onCameraTap: () {},
              ),
              // Le reste de la page se met ici
            ],
          ),
        ),
      ),
    );
  }
}

/// Barre de recherche réutilisable.
/// Les icônes sont remplaçables (SVG, image...) via les paramètres *Icon.
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

  const AppSearchBar({
    super.key,
    this.hint = 'Search',
    this.onChanged,
    this.onSubmitted,
    this.onMicTap,
    this.onCameraTap,
    this.controller,
    this.searchIcon = const Icon(Icons.search, size: 26, color: Color(0xFF1C1C1C)),
    this.micIcon = const Icon(Icons.mic, size: 18, color: Color(0xFF1C1C1C)),
    this.cameraIcon = const Icon(Icons.camera_alt, size: 20, color: Color(0xFF1C1C1C)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEDED),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFC9C9C9)),
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
              style: const TextStyle(fontSize: 13, color: Color(0xFF1C1C1C)),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF6B6B6B)),
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