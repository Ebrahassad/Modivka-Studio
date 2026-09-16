import 'package:flutter/material.dart';

class ModuleTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const ModuleTabs({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const labels = ['Images', 'Text', 'Video'];

    const icons = [
      Icons.image_outlined,
      Icons.text_fields_rounded,
      Icons.video_library_outlined,
    ];

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = selectedIndex == index;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Material(
                color: selected
                    ? Theme.of(context).colorScheme.primary.withAlpha(45)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onChanged(index),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icons[index], size: 18),
                        const SizedBox(width: 7),
                        Text(
                          labels[index],
                          style: TextStyle(
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
