import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  Map<String, bool> _perms = {};

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    final bt        = await Permission.bluetooth.status;
    final btConnect = await Permission.bluetoothConnect.status;
    final btScan    = await Permission.bluetoothScan.status;
    final location  = await Permission.location.status;

    if (mounted) {
      setState(() {
        _perms = {
          'Bluetooth General'   : bt.isGranted,
          'Conexión Cercana'    : btConnect.isGranted,
          'Escaneo BT'          : btScan.isGranted,
          'Ubicación (Android < 12)': location.isGranted,
        };
      });
    }
  }

  Future<void> _requestAll() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();
    await _loadPermissions();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D1117) : const Color(0xFFF0F2F5);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Guía de Audio y DAC'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          _IntroHeader(isDark: isDark, cs: cs),
          const SizedBox(height: 32),

          _SectionTitle(title: 'Permisos del Sistema', icon: Icons.security_rounded, isDark: isDark),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161B22) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.transparent : Colors.black.withOpacity(0.05)),
              boxShadow: [
                BoxShadow(color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estado Actual',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 12),
                ..._perms.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(e.value ? Icons.check_circle_rounded : Icons.cancel_rounded, color: e.value ? Colors.greenAccent : Colors.redAccent, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        e.key,
                        style: TextStyle(color: e.value ? (isDark ? Colors.white70 : Colors.black54) : Colors.redAccent, fontSize: 13, fontWeight: e.value ? FontWeight.normal : FontWeight.w600),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _requestAll,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Comprobar / Solicitar Permisos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary.withOpacity(0.1),
                      foregroundColor: cs.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Si tienes problemas detectando dispositivos, asegúrate de que todos los permisos estén marcados en verde. En Android < 12 se requiere Ubicación.',
                  style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          
          _SectionTitle(title: 'Modos de Volumen', icon: Icons.tune_rounded, isDark: isDark),
          const SizedBox(height: 16),
          _ModeCard(
            title: 'Unified Volume Mode',
            subtitle: 'Volumen Absoluto Activado',
            description: 'Android controla el volumen del sistema y del dispositivo Bluetooth al mismo tiempo. Al subir el volumen en tu DAC o Audífonos, la barra de volumen de Android también se mueve.',
            icon: Icons.link_rounded,
            color: Colors.blueAccent,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _ModeCard(
            title: 'Independent Volume Mode',
            subtitle: 'Volumen Absoluto Desactivado',
            description: 'El volumen del dispositivo Bluetooth y de Android están separados. La app enviará comandos directos al DAC (AVRCP) sin modificar forzosamente la barra de Android. Ideal para hardware de audio de alta fidelidad o cuando el botón físico está dañado.',
            icon: Icons.link_off_rounded,
            color: Colors.tealAccent,
            isDark: isDark,
          ),

          const SizedBox(height: 40),

          _SectionTitle(title: 'Preguntas Frecuentes', icon: Icons.help_outline_rounded, isDark: isDark),
          const SizedBox(height: 16),
          _FaqItem(
            question: '¿Por qué mi DAC no suena aunque Android esté al máximo?',
            answer: 'Si el "Independent Mode" está activo, es posible que el volumen interno de tu DAC esté en 0%. Usa el botón (+) de la app para subir el volumen interno del dispositivo.',
            isDark: isDark,
          ),
          _FaqItem(
            question: '¿Por qué mi teléfono reacciona distinto?',
            answer: 'Fabricantes como Samsung, Xiaomi o Huawei a veces fuerzan la sincronización de volumen en su propia capa de software, ignorando la configuración nativa. Si notas comportamientos extraños, prueba resincronizar desde la app.',
            isDark: isDark,
          ),
          
          const SizedBox(height: 40),

          _SectionTitle(title: 'Mejores Resultados', icon: Icons.verified_user_rounded, isDark: isDark),
          const SizedBox(height: 16),
          _TipBox(
            title: 'Opciones de Desarrollador',
            description: 'Para mayor control, puedes activar las "Opciones de Desarrollador" en Android y cambiar la versión AVRCP de Bluetooth a 1.5 o 1.6, lo que mejora la compatibilidad del Volumen Absoluto.',
            isDark: isDark,
            cs: cs,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _IntroHeader extends StatelessWidget {
  final bool isDark;
  final ColorScheme cs;

  const _IntroHeader({required this.isDark, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? cs.primary.withOpacity(0.1) : cs.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.primary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.graphic_eq_rounded, size: 48, color: cs.primary),
          const SizedBox(height: 16),
          Text(
            'Control de Audio Avanzado',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'VolSB te permite interactuar directamente con la capa AVRCP de tus dispositivos Bluetooth, saltando las limitaciones típicas de Android.',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 14,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;

  const _SectionTitle({required this.title, required this.icon, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: isDark ? Colors.white54 : Colors.black45, size: 20),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.black45,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.transparent : Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
              height: 1.5,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;
  final bool isDark;

  const _FaqItem({required this.question, required this.answer, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            answer,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TipBox extends StatelessWidget {
  final String title;
  final String description;
  final bool isDark;
  final ColorScheme cs;

  const _TipBox({required this.title, required this.description, required this.isDark, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.amber.withOpacity(0.05) : Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: Colors.amber.shade700, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
