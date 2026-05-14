import 'dart:io';
import 'package:flutter/material.dart';
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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
      title: const Text('BT Volume Pro'),
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
        // Background
        _Background(path: state.backgroundImagePath),

        SafeArea(
          child: RefreshIndicator(
            color: cs.primary,
            onRefresh: () => state.scanDevices(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // Status banner (only when active)
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

// ── Background ───────────────────────────────────────────────────────────────

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
    // Default gradient
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.background,
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
  final ValueChanged<BtDevice> onSelect;

  const _DeviceTabs({
    required this.devices,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: devices.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final d = devices[i];
          final isSelected = d.address == selected?.address;
          return ChoiceChip(
            label: Text(d.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            selected: isSelected,
            onSelected: (_) => onSelect(d),
            selectedColor: cs.primary.withOpacity(0.25),
            labelStyle: TextStyle(
              color: isSelected ? cs.primary : Colors.white70,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
            side: BorderSide(
              color: isSelected ? cs.primary : Colors.white12,
            ),
            avatar: Icon(
              _iconFor(d),
              size: 16,
              color: isSelected ? cs.primary : Colors.white54,
            ),
          );
        },
      ),
    );
  }

  IconData _iconFor(BtDevice d) {
    switch (d.deviceIcon) {
      case 'headphones': return Icons.headphones_rounded;
      case 'speaker': return Icons.speaker_rounded;
      case 'amp': return Icons.equalizer_rounded;
      case 'car': return Icons.directions_car_rounded;
      default: return Icons.bluetooth_audio_rounded;
    }
  }
}

// ── Main device content ──────────────────────────────────────────────────────

class _DeviceContent extends StatelessWidget {
  final BtDevice? device;
  const _DeviceContent({this.device});

  @override
  Widget build(BuildContext context) {
    if (device == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        DeviceCard(device: device!),
        const SizedBox(height: 16),
        const VolumePanel(),
        const SizedBox(height: 16),
        const QuickActionsBar(),
      ],
    );
  }
}
