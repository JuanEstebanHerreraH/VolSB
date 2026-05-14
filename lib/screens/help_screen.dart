import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Guía de Solución')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoBox(
            icon: Icons.info_outline_rounded,
            color: cs.primary,
            title: '¿Por qué mi dispositivo no tiene volumen?',
            body:
                'En Bluetooth existen DOS capas de volumen independientes: el volumen del sistema Android y el volumen interno del dispositivo Bluetooth.\n\n'
                'Cuando "Volumen Absoluto" (AVRCP Absolute Volume) está desactivado, roto o no es compatible, ambos funcionan separados. Esto hace que tu amplificador, DAC o auriculares queden internamente en volumen 0 aunque Android muestre volumen normal.',
          ),
          const SizedBox(height: 16),
          _StepList(
            title: 'Pasos a seguir manualmente',
            color: cs.tertiary,
            steps: [
              'Usa los botones físicos de volumen del headset o amplificador',
              'Reconecta el dispositivo Bluetooth (desconecta y vuelve a conectar)',
              'Activa/desactiva el Bluetooth del celular y reconecta',
              'Prueba "Resincronizar" y "Reconectar" en la pantalla principal',
              'Si tu celular tiene opciones de desarrollador, prueba cambiar la versión AVRCP en "Configuración → Opciones de desarrollador → Versión AVRCP de Bluetooth"',
              'Desvincula y vuelve a emparejar el dispositivo (Olvidar dispositivo + nuevo emparejamiento)',
              'Reinicia el dispositivo Bluetooth (apagar/encender físicamente)',
              'Si el dispositivo tiene combinación de botones para reset, úsala',
              'Sube el volumen desde el dispositivo físico antes de usar la app',
              'Prueba con otro celular que tenga Absolute Volume activo',
            ],
          ),
          const SizedBox(height: 16),
          _StepList(
            title: 'Lo que la app intenta automáticamente',
            color: cs.secondary,
            steps: [
              'Resincronización de volumen via AVRCP',
              'Envío de comandos AVRCP repetidos (burst)',
              'Reinicialización del stack Bluetooth',
              'Reconexión automática al perfil A2DP/HFP',
              'Restauración de niveles de volumen previos del perfil guardado',
              'Comando "Unmute" a nivel del sistema Android',
            ],
          ),
          const SizedBox(height: 16),
          _InfoBox(
            icon: Icons.lightbulb_outline_rounded,
            color: Colors.amber,
            title: 'Consejo Pro',
            body:
                'Si el dispositivo quedó con volumen 0 interno, la solución más confiable es usar los controles físicos del propio dispositivo (si los tiene) y luego usar "Resincronizar" en la app para alinear ambas capas.',
          ),
          const SizedBox(height: 16),
          _InfoBox(
            icon: Icons.developer_mode_rounded,
            color: cs.tertiary,
            title: 'Opciones de Desarrollador Android',
            body:
                'Puedes activar las Opciones de Desarrollador en tu Android yendo a:\n'
                'Ajustes → Acerca del teléfono → Número de compilación (toca 7 veces)\n\n'
                'Luego busca "Versión AVRCP de Bluetooth" y prueba con AVRCP 1.5 o 1.6.',
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _InfoBox({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
                color: Colors.white70, fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _StepList extends StatelessWidget {
  final String title;
  final Color color;
  final List<String> steps;

  const _StepList({
    required this.title,
    required this.color,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 12),
          ...steps.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${e.key + 1}',
                          style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        e.value,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13, height: 1.5),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
