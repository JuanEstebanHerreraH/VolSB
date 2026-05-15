import 'package:flutter/material.dart';

class NoDeviceView extends StatelessWidget {
  final VoidCallback onRefresh;
  const NoDeviceView({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 380,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.bluetooth_disabled_rounded,
                  color: cs.primary.withOpacity(0.4), size: 40),
            ),
            const SizedBox(height: 24),
            Text('Sin dispositivos conectados',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.white54)),
            const SizedBox(height: 8),
            Text('Conecta un dispositivo Bluetooth\ny vuelve a escanear',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(height: 1.5)),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Buscar dispositivos'),
            ),
          ],
        ),
      ),
    );
  }
}
