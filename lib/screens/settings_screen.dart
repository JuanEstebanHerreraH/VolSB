import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(
            title: 'Apariencia',
            children: [
              SwitchListTile(
                title: const Text('Modo oscuro'),
                subtitle: const Text('Interfaz oscura (recomendado)'),
                value: state.isDarkMode,
                onChanged: state.setDarkMode,
                activeColor: cs.primary,
              ),
              ListTile(
                leading: Icon(Icons.wallpaper_rounded, color: cs.primary),
                title: const Text('Imagen de fondo'),
                subtitle: Text(state.backgroundImagePath != null
                    ? 'Imagen personalizada activa'
                    : 'Sin imagen'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state.backgroundImagePath != null)
                      IconButton(
                        icon: Icon(Icons.close, color: cs.error, size: 18),
                        onPressed: () => state.setBackgroundImage(null),
                      ),
                    Icon(Icons.chevron_right_rounded, color: cs.onSurface.withOpacity(0.3)),
                  ],
                ),
                onTap: () => _pickBackground(context, state),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Bluetooth Avanzado',
            children: [
              SwitchListTile(
                title: const Text('Volumen Absoluto (AVRCP)'),
                subtitle: const Text(
                    'Sincroniza el volumen Android con el dispositivo Bluetooth. Desactívalo si causa problemas.'),
                value: state.absoluteVolumeEnabled,
                onChanged: state.toggleAbsoluteVolume,
                activeColor: cs.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Perfiles guardados',
            children: state.profiles.isEmpty
                ? [
                    const ListTile(
                      title: Text('Sin perfiles guardados'),
                      subtitle: Text('Los perfiles se crean automáticamente al usar la app'),
                    )
                  ]
                : state.profiles.entries.map((e) {
                    final profile = e.value;
                    return ListTile(
                      leading: const Icon(Icons.bluetooth_audio_rounded),
                      title: Text(profile.customName.isNotEmpty
                          ? profile.customName
                          : profile.address),
                      subtitle: Text('Último uso: ${_formatDate(profile.lastSeen)}'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline_rounded, color: cs.error),
                        onPressed: () => _deleteProfile(context, state, e.key),
                      ),
                    );
                  }).toList(),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'BT Volume Pro v1.0.0\nDesarrollado para control avanzado de audio Bluetooth',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(height: 1.6),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _pickBackground(BuildContext context, AppState state) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await state.setBackgroundImage(image.path);
    }
  }

  Future<void> _deleteProfile(
      BuildContext context, AppState state, String address) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar perfil'),
        content: const Text('¿Eliminar el perfil guardado de este dispositivo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm == true) {
      state.profiles.remove(address);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil eliminado')),
      );
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: cs.primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Card(
          child: Column(children: children),
        ),
      ],
    );
  }
}
