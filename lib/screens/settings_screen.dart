import 'package:flutter/material.dart';
import '../providers/locale_provider.dart';
import '../utils/app_strings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<String> get _gradientNames => [
        AppStrings.get(context, 'gradientWhite'),
        AppStrings.get(context, 'gradientSky'),
        AppStrings.get(context, 'gradientRoyal'),
        AppStrings.get(context, 'gradientPurple'),
        AppStrings.get(context, 'gradientGray'),
        AppStrings.get(context, 'gradientDark'),
      ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: LocaleProvider.selectedGradientIndex,
      builder: (context, currentBgIndex, child) {
        bool isDarkBg = currentBgIndex == 5;
        return Container(
          decoration: BoxDecoration(
            gradient: LocaleProvider.bgGradients[currentBgIndex],
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(
                  color: isDarkBg ? Colors.white : Colors.black87),
              title: Text(
                AppStrings.get(context, 'settingsTitle'),
                style:
                    TextStyle(color: isDarkBg ? Colors.white : Colors.black87),
              ),
              centerTitle: true,
            ),
            body: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.get(context, 'backgroundColor'),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 60,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: LocaleProvider.bgGradients.length,
                            itemBuilder: (context, index) {
                              final gradient =
                                  LocaleProvider.bgGradients[index];
                              return GestureDetector(
                                onTap: () {
                                  LocaleProvider.setGradientIndex(index);
                                },
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  decoration: BoxDecoration(
                                    gradient: gradient,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: currentBgIndex == index
                                          ? Colors.indigo
                                          : Colors.grey.shade400,
                                      width:
                                          currentBgIndex == index ? 3.5 : 1.5,
                                    ),
                                  ),
                                  child: currentBgIndex == index
                                      ? Icon(
                                          Icons.check,
                                          color: index == 5
                                              ? Colors.white
                                              : Colors.indigo,
                                          size: 22,
                                        )
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppStrings.get(
                            context,
                            'selectedColor',
                            args: {'color': _gradientNames[currentBgIndex]},
                          ),
                          style: TextStyle(
                              color: Colors.grey.shade700, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: SwitchListTile(
                    secondary: const Icon(Icons.language, color: Colors.indigo),
                    title: Text(
                      AppStrings.get(
                        context,
                        LocaleProvider.isArabic
                            ? 'currentArabic'
                            : 'currentEnglish',
                      ),
                    ),
                    subtitle: Text(AppStrings.get(context, 'changeLanguage')),
                    value: LocaleProvider.isArabic,
                    onChanged: (val) {
                      setState(() {
                        LocaleProvider.toggleLanguage();
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: Colors.indigo),
                            const SizedBox(width: 8),
                            Text(
                              AppStrings.get(context, 'aboutTitle'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Text(
                          AppStrings.get(context, 'aboutDescriptionText'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppStrings.get(context, 'versionText'),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
