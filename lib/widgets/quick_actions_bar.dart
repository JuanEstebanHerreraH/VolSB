import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class QuickActionsBar extends StatelessWidget {
  const QuickActionsBar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on_rounded, color: cs.primary, size: 18),
                const SizedBox(width: 8),
                Text('Acciones Rápidas',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),

            // Primary row: main repair actions
            Row(
              children: [
                Expanded(
                  child: _PrimaryAction(
                    icon: Icons.sync_rounded,
                    label: 'Resincronizar',
                    color: cs.primary,
                    onTap: state.resyncVolume,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PrimaryAction(
                    icon: Icons.bluetooth_searching_rounded,
                    label: 'Reconectar',
                    color: cs.secondary,
                    onTap: state.reconnectDevice,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Secondary row: volume controls
            Row(
              children: [
                Expanded(
                  child: _SecondaryAction(
                    icon: Icons.volume_up_rounded,
                    label: 'Vol ▲',
                    onTap: state.volumeUp,
                    cs: cs,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SecondaryAction(
                    icon: Icons.volume_down_rounded,
                    label: 'Vol ▼',
                    onTap: state.volumeDown,
                    cs: cs,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SecondaryAction(
                    icon: state.isMuted
                        ? Icons.volume_off_rounded
                        : Icons.volume_mute_rounded,
                    label: state.isMuted ? 'Unmute' : 'Mute',
                    onTap: state.toggleMute,
                    cs: cs,
                    highlight: state.isMuted,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Tertiary row: advanced
            Row(
              children: [
                Expanded(
                  child: _SecondaryAction(
                    icon: Icons.restart_alt_rounded,
                    label: 'Reset BT Vol',
                    onTap: state.resetBluetoothVolume,
                    cs: cs,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SecondaryAction(
                    icon: Icons.hearing_disabled_rounded,
                    label: 'Recuperar Mute',
                    onTap: state.recoverMutedDevice,
                    cs: cs,
                    highlight: false,
                    accentColor: cs.tertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PrimaryAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                      color: color, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ColorScheme cs;
  final bool highlight;
  final Color? accentColor;

  const _SecondaryAction({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.cs,
    this.highlight = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? (highlight ? cs.error : Colors.white54);
    return Material(
      color: cs.surfaceVariant,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      color: color, fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
