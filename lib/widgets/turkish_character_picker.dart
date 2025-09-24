import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TurkishCharacterPicker extends StatelessWidget {
  final Function(String) onCharacterSelected;
  final VoidCallback? onClose;

  const TurkishCharacterPicker({
    Key? key,
    required this.onCharacterSelected,
    this.onClose,
  }) : super(key: key);

  // Turkish special characters
  static const List<String> turkishChars = ['Ç', 'Ğ', 'İ', 'Ö', 'Ş', 'Ü'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F6F0), // _cardSurface
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border.all(color: const Color(0xFFE8E4DC), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C3E50).withOpacity(0.1),
            blurRadius: 8.0,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: turkishChars.map((char) => _buildCharacterButton(char)).toList(),
            ),
          ),
          if (onClose != null)
            IconButton(
              icon: const Icon(Icons.keyboard_hide, size: 20),
              onPressed: onClose,
              color: const Color(0xFF5D6D7E),
              tooltip: 'Karakterleri gizle',
            ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildCharacterButton(String character) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          HapticFeedback.selectionClick();
          onCharacterSelected(character);
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFD4AF37).withOpacity(0.1), // _vintageGold
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFD4AF37).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              character,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50), // _inkBlue
                fontFamily: 'serif',
              ),
            ),
          ),
        ),
      ),
    );
  }
}