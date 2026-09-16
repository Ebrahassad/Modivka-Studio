import 'package:flutter/material.dart';

class ModivkaTopBar extends StatelessWidget {
  final VoidCallback onNew;
  final VoidCallback onOpen;
  final VoidCallback onSave;
  final VoidCallback onSettings;
  final VoidCallback onAbout;

  const ModivkaTopBar({
    super.key,
    required this.onNew,
    required this.onOpen,
    required this.onSave,
    required this.onSettings,
    required this.onAbout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF21153D), Color(0xFF101018)],
        ),
      ),
      child: Row(
        children: [
          PopupMenuButton<String>(
            tooltip: 'File',
            icon: const Icon(Icons.menu_rounded),
            onSelected: (value) {
              switch (value) {
                case 'new':
                  onNew();
                  break;
                case 'open':
                  onOpen();
                  break;
                case 'save':
                  onSave();
                  break;
                case 'settings':
                  onSettings();
                  break;
                case 'about':
                  onAbout();
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'new',
                child: ListTile(
                  leading: Icon(Icons.note_add_outlined),
                  title: Text('New'),
                ),
              ),
              PopupMenuItem(
                value: 'open',
                child: ListTile(
                  leading: Icon(Icons.folder_open_outlined),
                  title: Text('Open'),
                ),
              ),
              PopupMenuItem(
                value: 'save',
                child: ListTile(
                  leading: Icon(Icons.save_outlined),
                  title: Text('Save / Export'),
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings_outlined),
                  title: Text('Settings'),
                ),
              ),
              PopupMenuItem(
                value: 'about',
                child: ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('About'),
                ),
              ),
            ],
          ),
          const Spacer(),
          const Text(
            'Modivka Studio',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
