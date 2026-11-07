import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/features/private_vault/application/private_vault_bloc.dart';
import 'package:musify_mu/features/private_vault/domain/models/gesture_pattern.dart';
import 'package:musify_mu/features/private_vault/domain/models/vault_settings.dart';
import 'package:musify_mu/features/private_vault/presentation/theme/vault_theme_palette.dart';
import 'package:musify_mu/features/private_vault/presentation/widgets/drawer_gesture_canvas.dart';

/// Full-screen dedicated settings view with live theme previews and security controls.
class PrivateVaultSettingsScreen extends StatefulWidget {
  const PrivateVaultSettingsScreen({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (context) => const PrivateVaultSettingsScreen(),
    );
  }

  @override
  State<PrivateVaultSettingsScreen> createState() => _PrivateVaultSettingsScreenState();
}

class _PrivateVaultSettingsScreenState extends State<PrivateVaultSettingsScreen> {
  GesturePattern? _recordedPattern;
  final GlobalKey<DrawerGestureCanvasState> _canvasKey = GlobalKey<DrawerGestureCanvasState>();

  void _showGestureRecordingDialog(BuildContext context, VaultThemePalette palette) {
    _recordedPattern = null;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: palette.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: palette.cardBorder),
              ),
              title: Text(
                'Record Secret Gesture',
                style: TextStyle(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Draw your new single-stroke gesture on the pad below. You will be able to draw it in either direction.',
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: palette.scaffoldBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: palette.cardBorder),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: DrawerGestureCanvas(
                      key: _canvasKey,
                      mode: GestureCanvasRenderMode.interactiveEnrollment,
                      onPatternRecorded: (pattern) {
                        setDialogState(() {
                          _recordedPattern = pattern;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _recordedPattern != null
                        ? 'Gesture captured (${_recordedPattern?.points.length} trajectory points)'
                        : 'Awaiting stroke gesture...',
                    style: TextStyle(
                      color: _recordedPattern != null
                          ? palette.textPrimary
                          : palette.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: palette.textSecondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    _canvasKey.currentState?.clear();
                    setDialogState(() {
                      _recordedPattern = null;
                    });
                  },
                  child: const Text('Clear'),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: palette.textSecondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.cardBorder,
                    foregroundColor: palette.textPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: palette.cardBorder),
                    ),
                  ),
                  onPressed: _recordedPattern == null
                      ? null
                      : () {
                          final pattern = _recordedPattern;
                          if (pattern != null) {
                            context.read<PrivateVaultBloc>().add(
                                  VaultGestureEnrollmentRequested(newPattern: pattern),
                                );
                            Navigator.of(dialogContext).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Secret gesture pattern saved'),
                                backgroundColor: palette.cardBackground,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: palette.cardBorder),
                                ),
                              ),
                            );
                          }
                        },
                  child: const Text('Save Pattern'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PrivateVaultBloc, PrivateVaultState>(
      builder: (context, state) {
        final settings = state.settings;
        final palette = VaultThemePalette.of(settings.theme);

        return Scaffold(
          backgroundColor: palette.scaffoldBackground,
          appBar: AppBar(
            backgroundColor: palette.scaffoldBackground,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: palette.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Vault Settings',
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              // -----------------------------------------------------------
              // THEME & APPEARANCE SECTION
              // -----------------------------------------------------------
              _SectionHeader(title: 'THEME & PALETTE', palette: palette),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ThemePreviewCard(
                      title: 'Deep Moss',
                      theme: VaultTheme.deepMoss,
                      isSelected: settings.theme == VaultTheme.deepMoss,
                      previewBackground: const Color(0xFF0F1F17),
                      previewCard: const Color(0xFF1E3A2E),
                      previewBorder: const Color(0xFF3E5A3F),
                      previewText: const Color(0xFFC7CBB8),
                      activePalette: palette,
                      onTap: () {
                        context.read<PrivateVaultBloc>().add(
                              VaultSettingsUpdateRequested(
                                newSettings: settings.copyWith(theme: VaultTheme.deepMoss),
                              ),
                            );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ThemePreviewCard(
                      title: 'Obsidian Cream',
                      theme: VaultTheme.obsidianCream,
                      isSelected: settings.theme == VaultTheme.obsidianCream,
                      previewBackground: const Color(0xFF121212),
                      previewCard: const Color(0xFF262323),
                      previewBorder: const Color(0xFF403D3E),
                      previewText: const Color(0xFFFFFED0),
                      activePalette: palette,
                      onTap: () {
                        context.read<PrivateVaultBloc>().add(
                              VaultSettingsUpdateRequested(
                                newSettings: settings.copyWith(theme: VaultTheme.obsidianCream),
                              ),
                            );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // -----------------------------------------------------------
              // GESTURE SENSOR SECTION
              // -----------------------------------------------------------
              _SectionHeader(title: 'GESTURE SENSOR', palette: palette),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: palette.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: palette.cardBorder),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      activeThumbColor: palette.textPrimary,
                      activeTrackColor: palette.cardBorder,
                      inactiveThumbColor: palette.textSecondary,
                      inactiveTrackColor: palette.scaffoldBackground,
                      title: Text(
                        'Show Gesture Trail in Drawer',
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Paints a faint 400ms disappearing ink line while drawing in the profile drawer',
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      value: settings.showDrawerGestureTrail,
                      onChanged: (enabled) {
                        context.read<PrivateVaultBloc>().add(
                              VaultSettingsUpdateRequested(
                                newSettings: settings.copyWith(showDrawerGestureTrail: enabled),
                              ),
                            );
                      },
                    ),
                    Divider(height: 1, color: palette.cardBorder),
                    ListTile(
                      title: Text(
                        'Re-record Secret Gesture',
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Current template: single-stroke geometric pattern',
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Icon(Icons.gesture, color: palette.textSecondary),
                      onTap: () => _showGestureRecordingDialog(context, palette),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // -----------------------------------------------------------
              // SECURITY & SESSION SECTION
              // -----------------------------------------------------------
              _SectionHeader(title: 'SESSION & PRIVACY', palette: palette),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: palette.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: palette.cardBorder),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      activeThumbColor: palette.textPrimary,
                      activeTrackColor: palette.cardBorder,
                      inactiveThumbColor: palette.textSecondary,
                      inactiveTrackColor: palette.scaffoldBackground,
                      title: Text(
                        'Window Protection (FLAG_SECURE)',
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Blocks device screenshots and obscures app content in the Android app switcher',
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      value: settings.preventScreenshots,
                      onChanged: (enabled) {
                        context.read<PrivateVaultBloc>().add(
                              VaultSettingsUpdateRequested(
                                newSettings: settings.copyWith(preventScreenshots: enabled),
                              ),
                            );
                      },
                    ),
                    Divider(height: 1, color: palette.cardBorder),
                    SwitchListTile(
                      activeThumbColor: palette.textPrimary,
                      activeTrackColor: palette.cardBorder,
                      inactiveThumbColor: palette.textSecondary,
                      inactiveTrackColor: palette.scaffoldBackground,
                      title: Text(
                        'Mask Lockscreen Media Metadata',
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Obscures private playlist track titles from OS notifications and lockscreen widgets',
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      value: settings.maskMediaSession,
                      onChanged: (enabled) {
                        context.read<PrivateVaultBloc>().add(
                              VaultSettingsUpdateRequested(
                                newSettings: settings.copyWith(maskMediaSession: enabled),
                              ),
                            );
                      },
                    ),
                    Divider(height: 1, color: palette.cardBorder),
                    ListTile(
                      title: Text(
                        'Cool-Off Auto-Lock Timeout',
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        settings.coolOffDuration.label,
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      trailing: DropdownButtonHideUnderline(
                        child: DropdownButton<CoolOffDuration>(
                          value: settings.coolOffDuration,
                          dropdownColor: palette.cardBackground,
                          icon: Icon(Icons.arrow_drop_down, color: palette.textSecondary),
                          onChanged: (newDuration) {
                            if (newDuration != null) {
                              context.read<PrivateVaultBloc>().add(
                                    VaultSettingsUpdateRequested(
                                      newSettings: settings.copyWith(coolOffDuration: newDuration),
                                    ),
                                  );
                            }
                          },
                          items: CoolOffDuration.values.map((duration) {
                            return DropdownMenuItem<CoolOffDuration>(
                              value: duration,
                              child: Text(
                                duration.label,
                                style: TextStyle(
                                  color: palette.textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VaultThemePalette palette;

  const _SectionHeader({
    required this.title,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: palette.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _ThemePreviewCard extends StatelessWidget {
  final String title;
  final VaultTheme theme;
  final bool isSelected;
  final Color previewBackground;
  final Color previewCard;
  final Color previewBorder;
  final Color previewText;
  final VaultThemePalette activePalette;
  final VoidCallback onTap;

  const _ThemePreviewCard({
    required this.title,
    required this.theme,
    required this.isSelected,
    required this.previewBackground,
    required this.previewCard,
    required this.previewBorder,
    required this.previewText,
    required this.activePalette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: previewBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activePalette.textPrimary : previewBorder,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: previewText,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, size: 16, color: activePalette.textPrimary),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: previewCard,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: previewBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: previewBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(Icons.lock, size: 12, color: previewText),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: previewText.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
