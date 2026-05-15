import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/bt_device.dart';
import '../widgets/device_card.dart';
import '../widgets/volume_panel.dart';
import '../widgets/quick_actions_bar.dart';
import '../widgets/status_banner.dart';
import '../widgets/no_device_view.dart';
import 'settings_screen.dart';
import 'help_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _permissionsGranted = true;
  bool _permissionsChecked = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final bt = await Permission.bluetooth.status;
    final btConnect = await Permission.bluetoothConnect.status;
    final btScan = await Permission.bluetoothScan.status;
    final location = await Permission.location.status;

    // En Android >= 12, se requiere btConnect y btScan.
    // En Android < 12, se requiere location (para escaneo Bluetooth).
    // Si alguno está explícitamente "granted", avanzamos. Si falta lo vital, pedimos.
    final allGranted = (btConnect.isGranted || location.isGranted) && 
                       (btScan.isGranted || location.isGranted);

    if (mounted) {
      setState(() {
        _permissionsGranted = allGranted;
        _permissionsChecked = true;
      });
    }
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();
    await _checkPermissions();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, state, cs),
      body: _buildBody(context, state, cs),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, AppState state, ColorScheme cs) {
    return AppBar(
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Icon(Icons.graphic_eq_rounded, color: cs.primary, size: 28),
      ),
      title: const Text('VolSB'),
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline_rounded),
          tooltip: 'Ayuda',
          onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const HelpScreen())),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Ajustes',
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen())),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody(BuildContext context, AppState state, ColorScheme cs) {
    return Stack(
      children: [
        _Background(path: state.backgroundImagePath),
        SafeArea(
          child: RefreshIndicator(
            color: cs.primary,
            onRefresh: () => state.scanDevices(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // Lógica principal
                if (_permissionsChecked && !_permissionsGranted)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: _ElegantPermissionView(
                        onRequest: _requestPermissions,
                        onOpenSettings: openAppSettings,
                      ),
                    ),
                  )
                else ...[
                  // Status banner
                  if (state.statusMessage.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: StatusBanner(
                          status: state.status,
                          message: state.statusMessage,
                        ),
                      ),
                    ),

                  // Device chips
                  if (state.devices.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _DeviceTabs(
                        devices: state.devices,
                        selected: state.selectedDevice,
                        onSelect: state.selectDevice,
                      ),
                    ),

                  // Main content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: state.devices.isEmpty
                          ? NoDeviceView(onRefresh: state.scanDevices)
                          : _DeviceContent(device: state.selectedDevice),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Vista de permisos elegante ────────────────────────────────────────────────

class _ElegantPermissionView extends StatelessWidget {
  final VoidCallback onRequest;
  final VoidCallback onOpenSettings;

  const _ElegantPermissionView({required this.onRequest, required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161B22) : Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: isDark ? Colors.transparent : Colors.black.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bluetooth_searching_rounded, color: Colors.blueAccent, size: 48),
              ),
              const SizedBox(height: 24),
              Text(
                'Permisos Necesarios',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'VolSB necesita acceso a Bluetooth y Ubicación Cercana para poder detectar tu DAC o audífonos y enviar los comandos de volumen AVRCP.',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: onRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('Conceder Permisos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: onOpenSettings,
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? Colors.white54 : Colors.black45,
                ),
                child: const Text('Abrir Ajustes del Sistema'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Background ────────────────────────────────────────────────────────────────

class _Background extends StatelessWidget {
  final String? path;
  const _Background({this.path});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (path != null) {
      return Positioned.fill(
        child: Stack(children: [
          Image.file(File(path!), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
          Container(color: Colors.black.withOpacity(0.65)),
        ]),
      );
    }
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.surface,
              cs.surface.withOpacity(0.95),
              const Color(0xFF0D1B2A),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Device tabs ───────────────────────────────────────────────────────────────

class _DeviceTabs extends StatelessWidget {
  final List<BtDevice> devices;
  final BtDevice? selected;
  final void Function(BtDevice) onSelect;

  const _DeviceTabs({
    required this.devices,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: devices.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final d = devices[i];
          final active = d.address == selected?.address;
          return ChoiceChip(
            label: Text(d.name),
            selected: active,
            onSelected: (_) => onSelect(d),
            selectedColor: cs.primary.withOpacity(0.2),
            side: BorderSide(
              color: active ? cs.primary : Colors.white24,
            ),
            labelStyle: TextStyle(
              color: active ? cs.primary : Colors.white70,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            ),
          );
        },
      ),
    );
  }
}

// ── Device content ────────────────────────────────────────────────────────────

class _DeviceContent extends StatelessWidget {
  final BtDevice? device;
  const _DeviceContent({this.device});

  @override
  Widget build(BuildContext context) {
    if (device == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        DeviceCard(device: device!),
        const SizedBox(height: 16),
        const VolumePanel(),
        const SizedBox(height: 16),
        const QuickActionsBar(),
      ],
    );
  }
}
