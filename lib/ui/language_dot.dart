import 'package:flutter/material.dart';

/// Curated subset of GitHub Linguist colors for the languages we expect
/// to see across the supported forges. Unknown entries fall through to
/// [kUnknownLanguageColor]. Null language is handled by [LanguageDot]
/// (falls back to the theme's outlineVariant).
const Map<String, Color> _languagePalette = {
  'dart': Color(0xFF00B4AB),
  'rust': Color(0xFFDEA584),
  'go': Color(0xFF00ADD8),
  'javascript': Color(0xFFF1E05A),
  'typescript': Color(0xFF3178C6),
  'python': Color(0xFF3572A5),
  'java': Color(0xFFB07219),
  'kotlin': Color(0xFFA97BFF),
  'swift': Color(0xFFF05138),
  'c': Color(0xFF555555),
  'c++': Color(0xFFF34B7D),
  'c#': Color(0xFF178600),
  'ruby': Color(0xFF701516),
  'php': Color(0xFF4F5D95),
  'shell': Color(0xFF89E051),
  'html': Color(0xFFE34C26),
  'css': Color(0xFF563D7C),
  'vue': Color(0xFF41B883),
  'svelte': Color(0xFFFF3E00),
  'lua': Color(0xFF000080),
  'elixir': Color(0xFF6E4A7E),
  'haskell': Color(0xFF5E5086),
  'scala': Color(0xFFC22D40),
  'r': Color(0xFF198CE7),
  'objective-c': Color(0xFF438EFF),
  'jupyter notebook': Color(0xFFDA5B0B),
};

/// 兜底色:语言字段存在但不在 [_languagePalette] 中(例如 'Cython')。
const Color kUnknownLanguageColor = Color(0xFF8B8B8B);

/// 返回 linguist 风格的语言色。
/// - 输入为 null:返回 null(由 [LanguageDot] 走 outlineVariant 兜底)。
/// - 输入在表里:返回对应 Color。
/// - 输入不在表里:返回 [kUnknownLanguageColor]。
Color? languageColor(String? language) {
  if (language == null) return null;
  return _languagePalette[language.toLowerCase()] ?? kUnknownLanguageColor;
}

/// 8x8 圆点,作为仓库行 leading 的视觉锚点。
/// null 语言用主题弱色填充,有语言用 linguist 色,未知语言用中性灰。
class LanguageDot extends StatelessWidget {
  const LanguageDot({super.key, required this.language, this.size = 8});

  final String? language;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = languageColor(language) ??
        Theme.of(context).colorScheme.outlineVariant;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}