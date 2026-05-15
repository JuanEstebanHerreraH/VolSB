import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bt_device.dart';
import '../providers/app_state.dart';

class DeviceCard extends StatelessWidget {
  final BtDevice device;
  const DeviceCard({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                _DeviceIcon(device: device, cs: cs),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(device.name, style: tt.titleLarge),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _StatusDot(active: device.isConnected),
                          const SizedBox(width: 6),
                          Text(
                            device.isConnected ? 'Conectado' : 'Desconectado',
                            style: tt.bodyMedium?.copyWith(
                              color: device.isConnected
                                  ? cs.tertiary
                                  : cs.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (device.batteryLevel >= 0)
                  _BatteryChip(level: device.batteryLevel, cs: cs),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),

            // Feature badges — absoluteVolumeEnabled viene de AppState para reflejar cambios en tiempo real
            Builder(builder: (context) {
              final absVol = context.watch<AppState>().absoluteVolumeEnabled;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Badge(label: 'AVRCP', active: device.avrcpSupported, cs: cs),
                  _Badge(label: 'Vol. Absoluto', active: absVol, cs: cs),
                  _Badge(
                    label: absVol ? 'Vol. Sincronizado' : 'Vol. Independiente',
                    active: absVol,
                    cs: cs,
                  ),
                  _Badge(label: device.profileType, active: true, cs: cs, neutral: true),
                ],
              );
            }),

            // Desync warning
            if (!device.volumeSynced || !device.absoluteVolumeSupported)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _WarningBanner(cs: cs),
              ),
          ],
        ),
      ),
    );
  }
}

class _DeviceIcon extends StatelessWidget {
  final BtDevice device;
  final ColorScheme cs;
  const _DeviceIcon({required this.device, required this.cs});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (device.deviceIcon) {
      case 'headphones':
        icon = Icons.headphones_rounded;
        break;
      case 'speaker':
        icon = Icons.speaker_rounded;
        break;
      case 'amp':
        icon = Icons.equalizer_rounded;
        break;
      case 'car':
        icon = Icons.directions_car_rounded;
        break;
      default:
        icon = Icons.bluetooth_audio_rounded;
    }

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: cs.primary, size: 26),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final bool active;
  const _StatusDot({required this.active});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? cs.tertiary : cs.error,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (active ? cs.tertiary : cs.error).withOpacity(0.5),
            blurRadius: 6,
          )
        ],
      ),
    );
  }
}

class _BatteryChip extends StatelessWidget {
  final int level;
  final ColorScheme cs;
  const _BatteryChip({required this.level, required this.cs});

  @override
  Widget build(BuildContext context) {
    final color = level > 60
        ? cs.tertiary
        : level > 20
            ? Colors.orange
            : cs.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.battery_charging_full_rounded, size: 14, color: color),
          const SizedBox(width: 4),
          Text('$level%',
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final bool active;
  final bool neutral;
  final ColorScheme cs;
  const _Badge({
    required this.label,
    required this.active,
    required this.cs,
    this.neutral = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = neutral
        ? cs.secondary
        : active
            ? cs.tertiary
            : cs.error.withOpacity(0.7);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!neutral)
            Icon(
              active ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: 12,
              color: color,
            ),
          if (!neutral) const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  final ColorScheme cs;
  const _WarningBanner({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'El volumen puede estar desincronizado. Usa los controles abajo para corregirlo.',
              style: TextStyle(
                color: Colors.orange.shade200,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
