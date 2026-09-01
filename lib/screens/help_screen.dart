import 'package:flutter/material.dart';
import '../utils/app_strings.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.get(context, 'helpTitle'))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(AppStrings.get(context, 'helpStep1'),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Text(AppStrings.get(context, 'helpStep2')),
            const SizedBox(height: 12),
            Text(AppStrings.get(context, 'helpStep3')),
            const SizedBox(height: 12),
            Text(AppStrings.get(context, 'helpStep4')),
            const SizedBox(height: 12),
            Text(AppStrings.get(context, 'helpStep5')),
          ],
        ),
      ),
    );
  }
}
