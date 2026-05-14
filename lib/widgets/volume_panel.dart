import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class VolumePanel extends StatelessWidget {
  const VolumePanel({super.key});

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
                Icon(Icons.tune_rounded, color: cs.primary, size: 18),
                const SizedBox(width: 8),
                Text('Control de Volumen',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 24),

            // Android volume slider
            _VolumeSlider(
              label: 'Volumen Android',
              icon: Icons.phone_android_rounded,
              value: state.androidVolume.toDouble(),
              max: state.maxAndroidVolume.toDouble(),
              color: cs.primary,
              onChanged: (v) => state.setAndroidVolume(v.round()),
            ),

            const SizedBox(height: 24),

            // Bluetooth internal volume (AVRCP driven)
            _AvrcpVolumeRow(cs: cs),
          ],
        ),
      ),
    );
  }
}

class _VolumeSlider extends StatelessWidget {
  final String label;
  final IconData icon;
  final double value;
  final double max;
  final Color color;
  final ValueChanged<double> onChanged;

  const _VolumeSlider({
    required this.label,
    required this.icon,
    required this.value,
    required this.max,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final pct = max > 0 ? (value / max * 100).round() : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('$pct%',
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: color.withOpacity(0.15),
            thumbColor: color,
            overlayColor: color.withOpacity(0.12),
          ),
          child: Slider(
            value: value.clamp(0, max),
            min: 0,
            max: max,
            divisions: max.toInt(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _AvrcpVolumeRow extends StatelessWidget {
  final ColorScheme cs;
  const _AvrcpVolumeRow({required this.cs});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bluetooth_audio_rounded, color: cs.secondary, size: 16),
            const SizedBox(width: 6),
            const Text('Volumen Bluetooth (AVRCP)',
                style: TextStyle(
                    color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: cs.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Via comando',
                  style: TextStyle(color: Colors.white38, fontSize: 11)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _VolBtn(
              icon: Icons.remove_rounded,
              label: '−',
              color: cs.secondary,
              onTap: state.volumeDown,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _InternalVolumeBar(
                muted: state.isMuted,
                cs: cs,
              ),
            ),
            const SizedBox(width: 10),
            _VolBtn(
              icon: Icons.add_rounded,
              label: '+',
              color: cs.secondary,
              onTap: state.volumeUp,
            ),
          ],
        ),
      ],
    );
  }
}

class _VolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _VolBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

class _InternalVolumeBar extends StatelessWidget {
  final bool muted;
  final ColorScheme cs;
  const _InternalVolumeBar({required this.muted, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: cs.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              color: muted ? cs.error : cs.secondary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              muted ? 'MUTEADO' : 'Activo',
              style: TextStyle(
                color: muted ? cs.error : cs.secondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
