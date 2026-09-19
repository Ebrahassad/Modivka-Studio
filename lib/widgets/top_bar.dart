import 'package:flutter/material.dart';

class ModivkaTopBar extends StatelessWidget {
  final VoidCallback onNew;
  final VoidCallback onOpen;
  final VoidCallback onSave;
  final VoidCallback onConvert;
  final VoidCallback onCompress;
  final VoidCallback onSettings;
  final VoidCallback onAbout;

  const ModivkaTopBar({
    super.key,
    required this.onNew,
    required this.onOpen,
    required this.onSave,
    required this.onConvert,
    required this.onCompress,
    required this.onSettings,
    required this.onAbout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF24164A), Color(0xFF0E0B18)],
        ),
        border: Border(
          bottom: BorderSide(color: Color(0x337D68FF)),
        ),
      ),
      child: Row(
        children: [
          PopupMenuButton<String>(
            tooltip: 'File',
            icon: const Icon(Icons.menu_rounded, size: 30),
            color: const Color(0xFF161327),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            onSelected: (value) {
              switch (value) {
                case 'new': onNew(); break;
                case 'open': onOpen(); break;
                case 'save': onSave(); break;
                case 'convert': onConvert(); break;
                case 'compress': onCompress(); break;
                case 'settings': onSettings(); break;
                case 'about': onAbout(); break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'new', child: ListTile(leading: Icon(Icons.note_add_outlined), title: Text('New project'))),
              PopupMenuItem(value: 'open', child: ListTile(leading: Icon(Icons.folder_open_outlined), title: Text('Open'))),
              PopupMenuItem(value: 'save', child: ListTile(leading: Icon(Icons.save_outlined), title: Text('Save / Export'))),
              PopupMenuItem(value: 'convert', child: ListTile(leading: Icon(Icons.transform_rounded), title: Text('Convert format'))),
              PopupMenuItem(value: 'compress', child: ListTile(leading: Icon(Icons.compress_rounded), title: Text('Compress files'))),
              PopupMenuDivider(),
              PopupMenuItem(value: 'settings', child: ListTile(leading: Icon(Icons.settings_outlined), title: Text('Settings'))),
              PopupMenuItem(value: 'about', child: ListTile(leading: Icon(Icons.info_outline), title: Text('About'))),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/modivka_icon.png', width: 30, height: 30),
              const SizedBox(width: 8),
              const Text(
                'Modivka Studio',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Convert',
            onPressed: onConvert,
            icon: const Icon(Icons.transform_rounded),
          ),
          IconButton(
            tooltip: 'Export',
            onPressed: onSave,
            icon: const Icon(Icons.file_upload_outlined),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: onSettings,
            icon: const Icon(Icons.tune_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
