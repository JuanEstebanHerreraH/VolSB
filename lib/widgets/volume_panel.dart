import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class VolumePanel extends StatelessWidget {
  const VolumePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final isAbsolute = state.absoluteVolumeEnabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Indicador de Modo
        _ModeIndicator(isAbsolute: isAbsolute),
        const SizedBox(height: 16),
        
        // Control Principal: Volumen Bluetooth
        _BluetoothVolumeController(cs: cs, isAbsolute: isAbsolute),
        
        const SizedBox(height: 24),
        
        // Control Secundario: Volumen Android
        _AndroidVolumeController(cs: cs, isAbsolute: isAbsolute),
      ],
    );
  }
}

class _ModeIndicator extends StatelessWidget {
  final bool isAbsolute;
  const _ModeIndicator({required this.isAbsolute});

  @override
  Widget build(BuildContext context) {
    final modeText = isAbsolute ? "Unified Volume Mode" : "Independent Volume Mode";
    final modeDesc = isAbsolute 
      ? "Volumen Android y Bluetooth vinculados." 
      : "Controles de volumen separados. BT no modifica Android.";
    final color = isAbsolute ? Colors.blueAccent : Colors.tealAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAbsolute ? Icons.link_rounded : Icons.link_off_rounded,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                modeText,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            modeDesc,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _BluetoothVolumeController extends StatelessWidget {
  final ColorScheme cs;
  final bool isAbsolute;

  const _BluetoothVolumeController({required this.cs, required this.isAbsolute});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final bgColor = const Color(0xFF161B22);
    final textColor = Colors.white;
    final subtitleColor = Colors.white54;

    // Cuando AV=ON: btVolume == androidVolume (misma fuente).
    // Cuando AV=OFF: btVolume es el contador independiente (0–100).
    final btVol = state.btVolume;
    final btMax = state.btMaxVolume > 0 ? state.btMaxVolume : 100;
    final pct = (btVol / btMax * 100).round();
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: cs.primary.withOpacity(0.05),
            blurRadius: 1,
            spreadRadius: 1,
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bluetooth_audio_rounded, color: cs.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                'BLUETOOTH DAC',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isAbsolute ? 'Sincronizado con dispositivo' : 'Control Independiente',
            style: TextStyle(color: subtitleColor, fontSize: 12),
          ),
          const SizedBox(height: 8),
          // Indicador de nivel BT (solo visible como referencia)
          Text(
            '$pct%',
            style: TextStyle(
              color: isAbsolute ? cs.primary : Colors.tealAccent,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _RepeatableVolumeButton(
                icon: Icons.remove_rounded,
                onTap: state.volumeDown,
                btnColor: const Color(0xFFE53935),
                isNegative: true,
              ),
              Column(
                children: [
                  Icon(
                    state.isMuted ? Icons.volume_off_rounded : Icons.graphic_eq_rounded,
                    color: state.isMuted ? const Color(0xFFE53935) : cs.primary,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.isMuted ? 'MUTE' : 'ACTIVE',
                    style: TextStyle(
                      color: state.isMuted ? const Color(0xFFE53935) : cs.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              _RepeatableVolumeButton(
                icon: Icons.add_rounded,
                onTap: state.volumeUp,
                btnColor: cs.primary,
                isNegative: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RepeatableVolumeButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color btnColor;
  final bool isNegative;

  const _RepeatableVolumeButton({
    required this.icon,
    required this.onTap,
    required this.btnColor,
    this.isNegative = false,
  });

  @override
  State<_RepeatableVolumeButton> createState() => _RepeatableVolumeButtonState();
}

class _RepeatableVolumeButtonState extends State<_RepeatableVolumeButton> with SingleTickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  void _startRepeating() {
    _animCtrl.forward();
    widget.onTap(); // Initial tap
    HapticFeedback.lightImpact();
    
    _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      widget.onTap();
      HapticFeedback.selectionClick();
    });
  }

  void _stopRepeating() {
    _animCtrl.reverse();
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final glowOpacity = widget.isNegative ? 0.15 : 0.2;
    final bgOpacity = 0.1;
    
    final bgColor = widget.btnColor.withOpacity(bgOpacity);

    return GestureDetector(
      onTapDown: (_) => _startRepeating(),
      onTapUp: (_) => _stopRepeating(),
      onTapCancel: _stopRepeating,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.btnColor.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.btnColor.withOpacity(glowOpacity),
                blurRadius: 15,
                spreadRadius: 1,
              )
            ],
          ),
          child: Icon(widget.icon, color: widget.btnColor, size: 36),
        ),
      ),
    );
  }
}

class _AndroidVolumeController extends StatelessWidget {
  final ColorScheme cs;
  final bool isAbsolute;

  const _AndroidVolumeController({required this.cs, required this.isAbsolute});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final value = state.androidVolume.toDouble();
    final max = state.maxAndroidVolume.toDouble();
    final pct = max > 0 ? (value / max * 100).round() : 0;
    
    final bgColor = const Color(0xFF1E232B);
    final textColor = Colors.white60;
    final highlightColor = Colors.white;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.phone_android_rounded, color: textColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'Media Volume (Android)',
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Text(
                '$pct%',
                style: TextStyle(
                  color: highlightColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: textColor,
              inactiveTrackColor: Colors.white12,
              thumbColor: highlightColor,
              overlayColor: Colors.white24,
              trackHeight: 4,
            ),
            child: Slider(
              value: value.clamp(0, max),
              min: 0,
              max: max,
              divisions: max > 0 ? max.toInt() : 1,
              onChanged: (v) {
                state.setAndroidVolume(v.round());
                HapticFeedback.selectionClick();
              },
            ),
          ),
          if (isAbsolute)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 8),
              child: Text(
                '* Cambiar este valor afectará el DAC.',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}
