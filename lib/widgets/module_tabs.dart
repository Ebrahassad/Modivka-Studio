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
      height: 82,
      color: const Color(0xFF0B0A11),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = index == selectedIndex;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
              child: Material(
                color: selected ? const Color(0xFF4A3EC6) : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => onChanged(index),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF7C6CFF)
                            : Colors.white.withAlpha(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icons[index], size: 26),
                        const SizedBox(width: 10),
                        Text(
                          labels[index],
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
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
