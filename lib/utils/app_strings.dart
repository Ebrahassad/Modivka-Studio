import 'package:flutter/material.dart';

class AppStrings {
  static const Map<String, Map<String, String>> values = {
    'ar': {
      'appTitle': 'العلامة المائية',
      'saveSuccess': 'تم الحفظ',
      'processedSuccess': 'تمت معالجة وحفظ {count} من أصل {total} صورة بنجاح.',
      'savePath': 'مسار الحفظ',
      'ok': 'حسناً',
      'openFolder': 'فتح المجلد',
      'openFolderError': 'تعذر فتح المجلد',
      'pleaseSelect': 'حدد الصور والشعار أولاً',
      'selectImages': 'اختيار الصور',
      'selectLogo': 'اختيار الشعار',
      'newSession': 'جلسة جديدة',
      'settings': 'الإعدادات',
      'exit': 'خروج',
      'shareQuoteLabel': 'اكتب اقتباس أو نص ترويجي للمشاركة على صفحات التواصل:',
      'shareQuoteHint': 'مثال: وصل حديثاً تشكيلة مميزة..',
      'processedByApp': 'تمت معالجة الصور بواسطة Watermark Pro',
      'exitTooltip': 'خروج',
      'settingsTooltip': 'الإعدادات',
      'enlargeLogo': 'تكبير الشعار',
      'rotateLogo': 'تدوير الشعار',
      'logoOpacity': 'شفافية الشعار',
      'savingExporting': 'جاري الحفظ والتصدير {current}/{total}',
      'noImages': 'لا توجد صور',
      'selectedImage': 'الصورة {current} من {total}',
      'dragLogoHint': 'اسحب الشعار لتغيير مكانه وحجمه',
      'toolsTitle': 'أدوات التعديل',
      'applyToAllTitle': 'تطبيق على الكل',
      'applyToAllOn': 'التعديلات تُطبق على كل الصور',
      'applyToAllOff': 'تعديل كل صورة بشكل مستقل',
      'removeLogoBg': 'إزالة خلفية الشعار',
      'removeLogoBgHint': 'جعل الشعار شفافاً',
      'opacity': 'الشفافية: {value}%',
      'applySave': 'تطبيق وحفظ',
      'settingsTitle': 'الإعدادات',
      'backgroundColor': 'خلفية التطبيق',
      'gradientColor': 'التدرج',
      'selectedColor': 'اللون المحدد: {color}',
      'language': 'اللغة',
      'currentArabic': 'Current Language: Arabic',
      'currentEnglish': 'Current Language: English',
      'changeLanguage': 'تغيير اللغة',
      'aboutTitle': 'حول التطبيق',
      'aboutDescription':
          'واترمارك هو تطبيق متخصص لإضافة العلامات المائية والشعارات التجارية إلى مجموعة من الصور دفعة واحدة من وحدة التخزين.\n\n'
              'أهم وظائف التطبيق:\n'
              '1. اختيار عدة صور من الجهاز دفعة واحدة.\n'
              '2. اختيار شعار أو لوقو من الجهاز.\n'
              '3. إزالة خلفية الشعار تلقائياً عند تفعيل الخيار.\n'
              '4. التحكم في مكان وحجم وشفافية الشعار.\n'
              '5. تطبيق الإعدادات وحفظ الصور الناتجة بسرعة.',
      'version': 'الإصدار: v1.0.4',
      'gradientWhite': 'أبيض ناصع',
      'gradientSky': 'أزرق سمائي',
      'gradientRoyal': 'أزرق ملكي',
      'gradientPurple': 'بنفسجي هادئ',
      'gradientGray': 'رمادي عصري',
      'gradientDark': 'رمادي داكن فاخر',
      'aboutDescriptionTitle': 'حول التطبيق',
      'aboutDescriptionText':
          'Watermark Pro هو تطبيق متخصص لإضافة العلامات المائية والشعارات التجارية إلى مجموعة من الصور دفعة واحدة من وحدة التخزين.\n\nأهم وظائف التطبيق:\n1. اختيار عدة صور من الجهاز دفعة واحدة.\n2. اختيار شعار أو لوقو من الجهاز.\n3. إزالة خلفية الشعار تلقائياً عند تفعيل الخيار.\n4. التحكم في مكان وحجم وشفافية الشعار.\n5. تطبيق الإعدادات وحفظ الصور الناتجة بسرعة.',
      'versionText': 'الإصدار: v1.0.4',
    },
    'en': {
      'appTitle': 'Watermark Pro',
      'saveSuccess': 'Saved Successfully',
      'processedSuccess':
          'Processed and saved {count} of {total} images successfully.',
      'savePath': 'Save path:',
      'ok': 'OK',
      'openFolder': 'Open Folder',
      'openFolderError': 'Unable to open folder',
      'pleaseSelect': 'Please select images and a logo first',
      'selectImages': 'Select Images',
      'selectLogo': 'Select Logo',
      'newSession': 'New Session',
      'settings': 'Settings',
      'exit': 'Exit',
      'shareQuoteLabel':
          'Write a quote or promotional text to share on social media:',
      'shareQuoteHint': 'Example: New collection just arrived..',
      'processedByApp': 'Images processed by Watermark Pro',
      'exitTooltip': 'Exit',
      'settingsTooltip': 'Settings',
      'enlargeLogo': 'Enlarge Logo',
      'rotateLogo': 'Rotate Logo',
      'logoOpacity': 'Logo Opacity',
      'savingExporting': 'Saving and exporting {current}/{total}',
      'noImages': 'No Images',
      'selectedImage': 'Image {current} of {total}',
      'dragLogoHint': 'Drag to move and resize the logo',
      'toolsTitle': 'Editing Tools',
      'applyToAllTitle': 'Apply to All',
      'applyToAllOn': 'Changes apply to all images',
      'applyToAllOff':
          'You can now customize the logo position and size for each image',
      'removeLogoBg': 'Remove Logo Background',
      'removeLogoBgHint': 'Make the logo transparent',
      'opacity': 'Opacity: {value}%',
      'applySave': 'Apply & Save',
      'settingsTitle': 'Settings & About',
      'backgroundColor': 'App Background',
      'gradientColor': 'Gradient',
      'selectedColor': 'Selected color: {color}',
      'language': 'Language',
      'currentArabic': 'اللغة الحالية: العربية',
      'currentEnglish': 'Current Language: English',
      'changeLanguage': 'Change Language',
      'aboutTitle': 'About',
      'aboutDescription':
          'Watermark is a specialized app for adding watermarks and commercial logos to multiple images at once from device storage.\n\n'
              'Main features:\n'
              '1. Select multiple images from the device at once.\n'
              '2. Select a logo from the device.\n'
              '3. Automatically remove the logo background when enabled.\n'
              '4. Control the logo position, size, and opacity.\n'
              '5. Apply the settings and save the processed images quickly.',
      'version': 'Version: v1.0.4',
      'gradientWhite': 'Bright White',
      'gradientSky': 'Sky Blue',
      'gradientRoyal': 'Royal Blue',
      'gradientPurple': 'Calm Purple',
      'gradientGray': 'Modern Gray',
      'gradientDark': 'Luxury Dark Charcoal',
      'aboutDescriptionTitle': 'About the App',
      'aboutDescriptionText':
          'Watermark Pro is a specialized app for adding watermarks and commercial logos to multiple images at once from device storage.\n\nMain features:\n1. Select multiple images from the device at once.\n2. Select a logo from the device.\n3. Automatically remove the logo background when enabled.\n4. Control the logo position, size, and opacity.\n5. Apply the settings and save the processed images quickly.',
      'versionText': 'Version: v1.0.4',
    },
  };

  static String get(
    BuildContext context,
    String key, {
    Map<String, String>? args,
  }) {
    final language = Localizations.localeOf(context).languageCode;
    var value = values[language]?[key] ?? values['en']?[key] ?? key;

    if (args != null) {
      for (final entry in args.entries) {
        value = value.replaceAll('{${entry.key}}', entry.value);
      }
    }

    return value;
  }
}
