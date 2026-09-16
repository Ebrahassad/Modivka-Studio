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
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withAlpha(210),
        border: Border(
          top: BorderSide(color: Colors.white.withAlpha(10)),
          bottom: BorderSide(color: Colors.white.withAlpha(10)),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tools.length,
        separatorBuilder: (_, __) => const SizedBox(width: 2),
        itemBuilder: (context, index) {
          final tool = tools[index];

          return Tooltip(
            message: tool.name,
            waitDuration: const Duration(milliseconds: 350),
            child: IconButton(
              onPressed: tool.onPressed,
              icon: Icon(tool.icon),
              iconSize: 21,
            ),
          );
        },
      ),
    );
  }
}
