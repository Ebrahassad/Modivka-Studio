import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider {
  static Locale currentLocale = const Locale('ar');
  static ValueNotifier<Locale> localeNotifier =
      ValueNotifier(const Locale('ar'));

  static const List<LinearGradient> bgGradients = [
    // 1 — رمادي فضي
    LinearGradient(
      colors: [Color(0xFFF4F6F8), Color(0xFFDDE2E7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),

    // 2 — أزرق رمادي
    LinearGradient(
      colors: [Color(0xFFE8F0F6), Color(0xFFC4D4E1)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),

    // 3 — أزرق هادئ
    LinearGradient(
      colors: [Color(0xFFE5EEF8), Color(0xFFB9CCE2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),

    // 4 — بنفسجي هادئ
    LinearGradient(
      colors: [Color(0xFFF0ECF8), Color(0xFFD4C9E8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),

    // 5 — بنفسجي مزرق
    LinearGradient(
      colors: [Color(0xFFE9EAF7), Color(0xFFC5C9E4)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),

    // 6 — رمادي داكن
    LinearGradient(
      colors: [Color(0xFF252A30), Color(0xFF424A54)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ];

  static ValueNotifier<int> selectedGradientIndex = ValueNotifier(0);

  static bool get isArabic => currentLocale.languageCode == 'ar';

  static Future<void> initPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    int savedColorIndex = prefs.getInt('selected_bg_index') ?? 0;
    if (savedColorIndex < bgGradients.length) {
      selectedGradientIndex.value = savedColorIndex;
    }
    String? lang = prefs.getString('selected_lang');
    if (lang != null) {
      currentLocale = Locale(lang);
      localeNotifier.value = currentLocale;
    }
  }

  static Future<void> setGradientIndex(int index) async {
    selectedGradientIndex.value = index;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_bg_index', index);
  }

  static Future<void> toggleLanguage() async {
    if (currentLocale.languageCode == 'ar') {
      currentLocale = const Locale('en');
    } else {
      currentLocale = const Locale('ar');
    }
    localeNotifier.value = currentLocale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_lang', currentLocale.languageCode);
  }

  // دالة إضافية لتعيين لغة محددة مباشرة (عربي أو إنجليزي) عند الحاجة
  static Future<void> setLocale(Locale locale) async {
    if (locale.languageCode == 'ar' || locale.languageCode == 'en') {
      currentLocale = locale;
      localeNotifier.value = currentLocale;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_lang', currentLocale.languageCode);
    }
  }
}
