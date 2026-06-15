import 'package:flutter/material.dart';

/// Shared course/module card image used by the Student, Lecturer and Pusat Adab
/// "view course and module" screens.
///
/// The same single picture is shown on EVERY card, for every subject and every
/// role (matching the SRS wireframes). To use a real photo instead of the grey
/// placeholder, drop an image at [_cardImage], register it under `assets:` in
/// pubspec.yaml, and set [_useImage] to true.
const String _cardImage = 'assets/card_picture.png';
const bool _useImage = true;

/// The rounded image banner shown at the top of a course/module card.
class CardImageBanner extends StatelessWidget {
  final double height;
  const CardImageBanner({super.key, this.height = 130});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      height: height,
      width: double.infinity,
      color: const Color(0xFFE6EAED),
      child: Icon(Icons.image_outlined, size: 48, color: Colors.grey.shade400),
    );

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      child: _useImage
          ? Image.asset(
              _cardImage,
              height: height,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => placeholder,
            )
          : placeholder,
    );
  }
}
