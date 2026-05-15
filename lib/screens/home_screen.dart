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

    final allGranted = bt.isGranted && btConnect.isGranted && btScan.isGranted;
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

                // Aviso de permisos
                if (_permissionsChecked && !_permissionsGranted)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: _PermissionBanner(onTap: _requestPermissions),
                    ),
                  ),

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
            ),
          ),
        ),
      ],
    );
  }
}

// ── Banner de permisos ────────────────────────────────────────────────────────

class _PermissionBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _PermissionBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.orange.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 22),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Permisos de Bluetooth no otorgados. La app no puede detectar dispositivos.\nToca aquí para habilitarlos.',
                style: TextStyle(color: Colors.orange, fontSize: 13, height: 1.5),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Activar',
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
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
