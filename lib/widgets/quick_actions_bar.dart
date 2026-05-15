import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class QuickActionsBar extends StatelessWidget {
  const QuickActionsBar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22), // Matching the DAC feel
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.transparent,
        ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.build_circle_rounded, color: Colors.white54, size: 20),
              const SizedBox(width: 8),
              const Text(
                'SYSTEM ACTIONS',
                style: TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _ActionBtn(
                  icon: Icons.sync_rounded,
                  label: 'RESYNC',
                  color: cs.primary,
                  onTap: state.resyncVolume,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionBtn(
                  icon: state.isMuted ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  label: state.isMuted ? 'UNMUTE' : 'MUTE DAC',
                  color: const Color(0xFFE53935),
                  isSecondary: true,
                  onTap: () {
                    state.toggleMute();
                    HapticFeedback.lightImpact();
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _ActionBtn(
                  icon: Icons.bluetooth_searching_rounded,
                  label: 'RECONNECT',
                  color: cs.secondary,
                  onTap: state.reconnectDevice,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _ActionBtn(
                  icon: Icons.restart_alt_rounded,
                  label: 'RESET VOL',
                  color: Colors.orange,
                  onTap: state.resetBluetoothVolume,
                  isSecondary: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionBtn(
                  icon: Icons.healing_rounded,
                  label: 'FIX MUTE',
                  color: cs.tertiary,
                  onTap: state.recoverMutedDevice,
                  isSecondary: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isSecondary;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isSecondary
        ? Colors.white.withOpacity(0.05)
        : color.withOpacity(0.12);
    final fgColor = isSecondary ? Colors.white70 : color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSecondary 
                ? Colors.white10
                : color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: fgColor, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: fgColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
