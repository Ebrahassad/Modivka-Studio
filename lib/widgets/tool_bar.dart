import 'package:flutter/material.dart';

class ToolDefinition {
  final IconData icon;
  final String name;
  final VoidCallback? onPressed;

  const ToolDefinition({
    required this.icon,
    required this.name,
    this.onPressed,
  });
}

class ModivkaToolBar extends StatelessWidget {
  final List<ToolDefinition> tools;

  const ModivkaToolBar({super.key, required this.tools});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF111019),
        border: Border(
          bottom: BorderSide(color: Colors.white.withAlpha(10)),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tools.length,
        separatorBuilder: (_, __) => const SizedBox(width: 3),
        itemBuilder: (context, index) {
          final tool = tools[index];
          return Tooltip(
            message: tool.name,
            child: Material(
              color: tool.onPressed == null
                  ? Colors.transparent
                  : const Color(0xFF1B1927),
              borderRadius: BorderRadius.circular(11),
              child: IconButton(
                onPressed: tool.onPressed,
                icon: Icon(tool.icon),
                iconSize: 22,
                color: tool.onPressed == null ? Colors.white24 : Colors.white,
                splashRadius: 22,
              ),
            ),
          );
        },
      ),
    );
  }
}
