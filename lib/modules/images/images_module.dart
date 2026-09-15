import 'package:flutter/material.dart';

class ImagesModule extends StatelessWidget {
  final VoidCallback? onWatermark;
  final VoidCallback? onModify;
  final Widget? watermarkWorkspace;

  const ImagesModule({
    super.key,
    this.onWatermark,
    this.onModify,
    this.watermarkWorkspace,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ImagesToolbar(
          onWatermark: onWatermark,
          onModify: onModify,
        ),
        Expanded(
          child: watermarkWorkspace ??
              const _ImagesWorkspace(),
        ),
      ],
    );
  }
}

class _ImagesToolbar extends StatelessWidget {
  final VoidCallback? onWatermark;
  final VoidCallback? onModify;

  const _ImagesToolbar({
    this.onWatermark,
    this.onModify,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SizedBox(
        height: 58,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 7,
          ),
          children: [
            _ImagesToolButton(
              icon: Icons.branding_watermark_rounded,
              label: 'Watermark',
              onPressed: onWatermark,
            ),
            _ImagesToolButton(
              icon: Icons.tune_rounded,
              label: 'Modify',
              onPressed: onModify,
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagesToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _ImagesToolButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 19),
        label: Text(label),
      ),
    );
  }
}

class _ImagesWorkspace extends StatelessWidget {
  const _ImagesWorkspace();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.withAlpha(30),
        ),
      ),
      child: const Center(
        child: Text(
          'Images Workspace',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
