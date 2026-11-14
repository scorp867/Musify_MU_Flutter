import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musify_mu/app/di/injection.dart';
import 'package:musify_mu/features/vault/application/settings/settings_mutation_cubit.dart';
import 'package:musify_mu/features/vault/presentation/theme/vault_theme.dart';

/// Derives a high-contrast danger ink color legible on dark vault surfaces
/// while staying strictly aligned to the active [VaultThemeData].
Color vaultDangerInk(VaultThemeData vaultTheme) {
  final blended = Color.lerp(
    vaultTheme.danger,
    vaultTheme.textHighSalience,
    0.35,
  );
  if (blended case final Color resolved) {
    return resolved;
  }
  return vaultTheme.textHighSalience;
}

/// Displays a consistently themed floating [SnackBar] across Vault settings.
void showVaultSettingsSnackBar(
  BuildContext context,
  VaultThemeData vaultTheme, {
  required String message,
  bool isError = false,
  bool clearExisting = false,
}) {
  final messenger = ScaffoldMessenger.of(context);
  if (clearExisting) {
    messenger.clearSnackBars();
  }
  final borderColor = isError ? vaultTheme.danger : vaultTheme.border;
  final textColor =
      isError ? vaultDangerInk(vaultTheme) : vaultTheme.textHighSalience;

  messenger.showSnackBar(
    SnackBar(
      backgroundColor: vaultTheme.surface,
      behavior: SnackBarBehavior.floating,
      elevation: 0.0,
      margin: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: VaultTheme.borderRadius8,
        side: BorderSide(color: borderColor, width: VaultTheme.borderWidth),
      ),
      content: Text(
        message,
        style: TextStyle(
          fontFamily: VaultTheme.fontFamily,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    ),
  );
}

/// Consistent Figma-style AppBar used across Vault Settings and sub-screens.
AppBar buildVaultSettingsAppBar({
  required VaultThemeData vaultTheme,
  required String title,
  Key? backButtonKey,
  VoidCallback? onBackPressed,
  List<Widget>? actions,
}) {
  return AppBar(
    backgroundColor: vaultTheme.scaffold,
    surfaceTintColor: Colors.transparent,
    elevation: 0.0,
    scrolledUnderElevation: 0.0,
    toolbarHeight: 58.0,
    centerTitle: false,
    titleSpacing: onBackPressed == null ? 20.0 : 4.0,
    leading: onBackPressed == null
        ? null
        : IconButton(
            key: backButtonKey,
            icon: Icon(
              Icons.arrow_back_rounded,
              size: 22.0,
              color: vaultTheme.textHighSalience,
            ),
            tooltip: 'Back',
            onPressed: onBackPressed,
          ),
    title: Text(
      title,
      style: TextStyle(
        fontFamily: VaultTheme.fontFamily,
        fontSize: 18.0,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: vaultTheme.textHighSalience,
      ),
    ),
    actions: actions,
  );
}

/// Minimal tracked section label displayed above an inset-grouped container.
class VaultSettingsSectionHeader extends StatelessWidget {
  final String title;
  final VaultThemeData vaultTheme;
  final EdgeInsetsGeometry padding;

  const VaultSettingsSectionHeader({
    super.key,
    required this.title,
    required this.vaultTheme,
    this.padding = const EdgeInsets.fromLTRB(4.0, 0.0, 4.0, 8.0),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontFamily: VaultTheme.fontFamily,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: vaultTheme.textMediumSalience,
        ),
      ),
    );
  }
}

/// Clean inset-grouped dark card holding stacked settings rows separated by
/// crisp 1.0px internal hairline dividers.
class VaultSettingsGroup extends StatelessWidget {
  final VaultThemeData vaultTheme;
  final List<Widget> children;
  final double dividerInset;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? dividerColor;

  const VaultSettingsGroup({
    super.key,
    required this.vaultTheme,
    required this.children,
    this.dividerInset = 16.0,
    this.backgroundColor,
    this.borderColor,
    this.dividerColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = switch (backgroundColor) {
      final Color custom => custom,
      null => vaultTheme.surfaceSubtle,
    };
    final effectiveBorder = switch (borderColor) {
      final Color custom => custom,
      null => vaultTheme.border,
    };
    final effectiveDivider = switch (dividerColor) {
      final Color custom => custom,
      null => vaultTheme.borderSubtle,
    };

    final spacedChildren = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      if (i > 0) {
        spacedChildren.add(
          Container(
            height: VaultTheme.borderWidth,
            margin: EdgeInsets.only(left: dividerInset),
            color: effectiveDivider,
          ),
        );
      }
      spacedChildren.add(children[i]);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: VaultTheme.borderRadius8,
        border: Border.all(
          color: effectiveBorder,
          width: VaultTheme.borderWidth,
        ),
      ),
      child: ClipRRect(
        borderRadius: VaultTheme.borderRadius8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: spacedChildren,
        ),
      ),
    );
  }
}

/// Clean grouped navigation row with a subtle tinted icon badge, concise copy,
/// and right disclosure chevron.
class VaultSettingsNavRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VaultThemeData vaultTheme;
  final VoidCallback onTap;
  final bool isDanger;
  final Widget? trailing;

  const VaultSettingsNavRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.vaultTheme,
    required this.onTap,
    this.isDanger = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final badgeBackground = isDanger
        ? vaultTheme.danger.withValues(alpha: 0.16)
        : vaultTheme.surfaceHighlight;
    final iconColor =
        isDanger ? vaultDangerInk(vaultTheme) : vaultTheme.accent;
    final titleColor =
        isDanger ? vaultDangerInk(vaultTheme) : vaultTheme.textHighSalience;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        highlightColor: vaultTheme.surfaceHighlight.withValues(alpha: 0.5),
        splashColor: vaultTheme.accent.withValues(alpha: 0.08),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 62.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 12.0,
            ),
            child: Row(
              children: [
                Container(
                  width: 36.0,
                  height: 36.0,
                  decoration: BoxDecoration(
                    color: badgeBackground,
                    borderRadius: VaultTheme.borderRadius8,
                  ),
                  child: Icon(icon, size: 19.0, color: iconColor),
                ),
                const SizedBox(width: 14.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: VaultTheme.fontFamily,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.1,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: VaultTheme.fontFamily,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          height: 1.35,
                          color: vaultTheme.textMediumSalience,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8.0),
                switch (trailing) {
                  final Widget custom => custom,
                  null => Icon(
                      Icons.chevron_right_rounded,
                      size: 20.0,
                      color: vaultTheme.textLowSalience,
                    ),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Clean grouped switch row adhering to >= 48dp touch target ergonomics.
class VaultSettingsToggleRow extends StatelessWidget {
  final Key? switchKey;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final VaultThemeData vaultTheme;
  final IconData? icon;

  const VaultSettingsToggleRow({
    super.key,
    this.switchKey,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    required this.vaultTheme,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final VoidCallback? rowTap = switch (onChanged) {
      final ValueChanged<bool> callback => () => callback(!value),
      null => null,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: rowTap,
        highlightColor: vaultTheme.surfaceHighlight.withValues(alpha: 0.45),
        splashColor: vaultTheme.accent.withValues(alpha: 0.08),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 12.0,
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 34.0,
                    height: 34.0,
                    decoration: BoxDecoration(
                      color: vaultTheme.surfaceHighlight,
                      borderRadius: VaultTheme.borderRadius8,
                    ),
                    child: Icon(
                      icon,
                      size: 18.0,
                      color: value
                          ? vaultTheme.accent
                          : vaultTheme.textMediumSalience,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: VaultTheme.fontFamily,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.1,
                          color: vaultTheme.textHighSalience,
                        ),
                      ),
                      if (subtitle case final String subtitleText) ...[
                        const SizedBox(height: 3.0),
                        Text(
                          subtitleText,
                          style: TextStyle(
                            fontFamily: VaultTheme.fontFamily,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                            height: 1.38,
                            color: vaultTheme.textMediumSalience,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12.0),
                Switch(
                  key: switchKey,
                  value: value,
                  onChanged: onChanged,
                  activeThumbColor: vaultTheme.scaffold,
                  activeTrackColor: vaultTheme.accent,
                  inactiveThumbColor: vaultTheme.textMediumSalience,
                  inactiveTrackColor: vaultTheme.surfaceHighlight,
                  trackOutlineColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return vaultTheme.accent;
                    }
                    return vaultTheme.border;
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Clean selectable radio row inside a [VaultSettingsGroup].
class VaultSettingsRadioRow extends StatelessWidget {
  final Key? optionKey;
  final String title;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final VaultThemeData vaultTheme;

  const VaultSettingsRadioRow({
    super.key,
    this.optionKey,
    required this.title,
    this.subtitle,
    required this.isSelected,
    required this.onTap,
    required this.vaultTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? vaultTheme.surfaceHighlight.withValues(alpha: 0.55)
          : Colors.transparent,
      child: InkWell(
        key: optionKey,
        onTap: onTap,
        highlightColor: vaultTheme.surfaceHighlight.withValues(alpha: 0.65),
        splashColor: vaultTheme.accent.withValues(alpha: 0.08),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 12.0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: VaultTheme.fontFamily,
                          fontSize: 14.5,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          letterSpacing: -0.1,
                          color: isSelected
                              ? vaultTheme.accent
                              : vaultTheme.textHighSalience,
                        ),
                      ),
                      if (subtitle case final String subtitleText) ...[
                        const SizedBox(height: 2.0),
                        Text(
                          subtitleText,
                          style: TextStyle(
                            fontFamily: VaultTheme.fontFamily,
                            fontSize: 12.0,
                            fontWeight: FontWeight.w400,
                            height: 1.35,
                            color: vaultTheme.textMediumSalience,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12.0),
                Container(
                  width: 20.0,
                  height: 20.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? vaultTheme.accent
                          : vaultTheme.textLowSalience,
                      width: 1.6,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 10.0,
                            height: 10.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: vaultTheme.accent,
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Subdued explanatory footnote paired beneath grouped settings controls.
class VaultSettingsFootnote extends StatelessWidget {
  final String text;
  final VaultThemeData vaultTheme;

  const VaultSettingsFootnote({
    super.key,
    required this.text,
    required this.vaultTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4.0, 10.0, 4.0, 0.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.5),
            child: Icon(
              Icons.info_outline_rounded,
              size: 15.0,
              color: vaultTheme.textLowSalience,
            ),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: VaultTheme.fontFamily,
                fontSize: 12.0,
                fontWeight: FontWeight.w400,
                height: 1.4,
                color: vaultTheme.textMediumSalience,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared inset search input for Vault list and detail screens.
class VaultInlineSearchField extends StatelessWidget {
  final TextEditingController controller;
  final VaultThemeData vaultTheme;
  final String hintText;
  final Key? inputKey;
  final FocusNode? focusNode;
  final EdgeInsetsGeometry padding;

  const VaultInlineSearchField({
    super.key,
    required this.controller,
    required this.vaultTheme,
    required this.hintText,
    this.inputKey,
    this.focusNode,
    this.padding = const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Container(
        height: 44.0,
        decoration: BoxDecoration(
          color: vaultTheme.surfaceSubtle,
          borderRadius: VaultTheme.borderRadius8,
          border: Border.all(
            color: vaultTheme.borderSubtle,
            width: VaultTheme.borderWidth,
          ),
        ),
        padding: const EdgeInsets.only(left: 12.0, right: 4.0),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              size: 19.0,
              color: vaultTheme.textLowSalience,
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: TextField(
                key: inputKey,
                controller: controller,
                focusNode: focusNode,
                style: TextStyle(
                  fontFamily: VaultTheme.fontFamily,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w400,
                  color: vaultTheme.textHighSalience,
                ),
                cursorColor: vaultTheme.accent,
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(
                    fontFamily: VaultTheme.fontFamily,
                    fontSize: 14.0,
                    fontWeight: FontWeight.w400,
                    color: vaultTheme.textLowSalience,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
                ),
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                if (value.text.isEmpty) {
                  return const SizedBox(width: 8.0);
                }
                return IconButton(
                  tooltip: 'Clear search',
                  onPressed: controller.clear,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40.0,
                    minHeight: 40.0,
                  ),
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18.0,
                    color: vaultTheme.textMediumSalience,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Presents a dark Figma-aligned confirmation bottom sheet returning whether
/// the user confirmed the action.
Future<bool> showVaultConfirmationSheet(
  BuildContext context,
  VaultThemeData vaultTheme, {
  Key? sheetKey,
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool isDestructive = true,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: vaultTheme.surface,
    barrierColor: Colors.black.withValues(alpha: 0.65),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
    ),
    builder: (sheetContext) {
      final actionFill = isDestructive ? vaultTheme.danger : vaultTheme.accent;
      final actionForeground =
          isDestructive ? Colors.white : vaultTheme.scaffold;

      return SafeArea(
        key: sheetKey,
        top: false,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: vaultTheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12.0),
            ),
            border: Border(
              top: BorderSide(
                color: vaultTheme.borderSubtle,
                width: VaultTheme.borderWidth,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36.0,
                    height: 4.0,
                    decoration: BoxDecoration(
                      color: vaultTheme.border,
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                ),
                const SizedBox(height: 18.0),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: VaultTheme.fontFamily,
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: vaultTheme.textHighSalience,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  message,
                  style: TextStyle(
                    fontFamily: VaultTheme.fontFamily,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    height: 1.45,
                    color: vaultTheme.textMediumSalience,
                  ),
                ),
                const SizedBox(height: 20.0),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48.0,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: vaultTheme.textHighSalience,
                            side: BorderSide(
                              color: vaultTheme.border,
                              width: VaultTheme.borderWidth,
                            ),
                            shape: VaultTheme.shape8,
                          ),
                          onPressed: () =>
                              Navigator.of(sheetContext).pop(false),
                          child: Text(
                            cancelLabel,
                            style: const TextStyle(
                              fontFamily: VaultTheme.fontFamily,
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: SizedBox(
                        height: 48.0,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: actionFill,
                            foregroundColor: actionForeground,
                            elevation: 0.0,
                            shape: VaultTheme.shape8,
                          ),
                          onPressed: () =>
                              Navigator.of(sheetContext).pop(true),
                          child: Text(
                            confirmLabel,
                            style: const TextStyle(
                              fontFamily: VaultTheme.fontFamily,
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  return result == true;
}

/// Resolves the active [VaultThemeData], honoring explicit overrides first,
/// then ancestor [VaultTheme], [SettingsMutationCubit] in widget tree or DI,
/// and finally the warmEspresso fallback.
VaultThemeData resolveVaultTheme(
  BuildContext context, [
  VaultThemeData? explicitTheme,
]) {
  if (explicitTheme case final provided?) {
    return provided;
  }
  if (VaultTheme.maybeOf(context) case final inherited?) {
    return inherited;
  }
  try {
    final cubit = context.read<SettingsMutationCubit>();
    return VaultThemeData.fromConfig(cubit.currentConfig);
  } on ProviderNotFoundException {
    // Public routes outside VaultRoutes may not provide SettingsMutationCubit.
  }
  if (getIt.isRegistered<SettingsMutationCubit>()) {
    return VaultThemeData.fromConfig(
      getIt<SettingsMutationCubit>().currentConfig,
    );
  }
  return VaultTheme.of(context);
}

/// Confirms destructive playlist deletion with a dark Figma bottom sheet.
Future<bool> confirmVaultPlaylistDeletion(
  BuildContext context,
  VaultThemeData vaultTheme, {
  required String playlistName,
  Key? sheetKey,
}) {
  return showVaultConfirmationSheet(
    context,
    vaultTheme,
    sheetKey: sheetKey ?? const ValueKey('delete_playlist_confirmation_sheet'),
    title: 'Delete Playlist',
    message:
        'Delete "$playlistName"? Songs stay in your regular library unless moved only to the vault.',
    confirmLabel: 'Delete Playlist',
    isDestructive: true,
  );
}

/// Presents a keyboard-safe dark Figma modal sheet to create a vault playlist.
Future<({String name, String description})?> showVaultCreatePlaylistSheet(
  BuildContext context,
  VaultThemeData vaultTheme, {
  Key? sheetKey,
  String title = 'New Playlist',
  String subtitle = 'Create a private space for tracks in your vault.',
  String confirmLabel = 'Create',
  bool showDescription = true,
}) {
  return showModalBottomSheet<({String name, String description})>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.65),
    builder: (sheetContext) => VaultTheme(
      data: vaultTheme,
      child: _VaultCreatePlaylistSheet(
        sheetKey: sheetKey ?? const ValueKey('create_playlist_sheet'),
        vaultTheme: vaultTheme,
        title: title,
        subtitle: subtitle,
        confirmLabel: confirmLabel,
        showDescription: showDescription,
      ),
    ),
  );
}

class _VaultCreatePlaylistSheet extends StatefulWidget {
  final Key sheetKey;
  final VaultThemeData vaultTheme;
  final String title;
  final String subtitle;
  final String confirmLabel;
  final bool showDescription;

  const _VaultCreatePlaylistSheet({
    required this.sheetKey,
    required this.vaultTheme,
    required this.title,
    required this.subtitle,
    required this.confirmLabel,
    required this.showDescription,
  });

  @override
  State<_VaultCreatePlaylistSheet> createState() =>
      _VaultCreatePlaylistSheetState();
}

class _VaultCreatePlaylistSheetState extends State<_VaultCreatePlaylistSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    Navigator.of(context).pop((name: name, description: description));
  }

  InputDecoration _inputDecoration({
    required VaultThemeData vaultTheme,
    required String labelText,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      filled: true,
      fillColor: vaultTheme.background,
      labelStyle: TextStyle(
        fontFamily: VaultTheme.fontFamily,
        fontSize: 13.5,
        color: vaultTheme.textMediumSalience,
      ),
      hintStyle: TextStyle(
        fontFamily: VaultTheme.fontFamily,
        fontSize: 13.5,
        color: vaultTheme.textLowSalience,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14.0,
        vertical: 14.0,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: VaultTheme.borderRadius8,
        borderSide: BorderSide(
          color: vaultTheme.borderSubtle,
          width: VaultTheme.borderWidth,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: VaultTheme.borderRadius8,
        borderSide: BorderSide(
          color: vaultTheme.accent,
          width: VaultTheme.borderWidth,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: VaultTheme.borderRadius8,
        borderSide: BorderSide(
          color: vaultTheme.danger,
          width: VaultTheme.borderWidth,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: VaultTheme.borderRadius8,
        borderSide: BorderSide(
          color: vaultTheme.danger,
          width: VaultTheme.borderWidth,
        ),
      ),
      errorStyle: TextStyle(
        fontFamily: VaultTheme.fontFamily,
        fontSize: 12.0,
        color: vaultDangerInk(vaultTheme),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vaultTheme = widget.vaultTheme;
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: VaultSheetScaffold(
        sheetKey: widget.sheetKey,
        vaultTheme: vaultTheme,
        title: widget.title,
        subtitle: widget.subtitle,
        onClose: () => Navigator.of(context).pop(),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  textInputAction: widget.showDescription
                      ? TextInputAction.next
                      : TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (!widget.showDescription) {
                      _submit();
                    }
                  },
                  cursorColor: vaultTheme.accent,
                  style: TextStyle(
                    fontFamily: VaultTheme.fontFamily,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: vaultTheme.textHighSalience,
                  ),
                  decoration: _inputDecoration(
                    vaultTheme: vaultTheme,
                    labelText: 'Name',
                    hintText: 'Late night mix',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a playlist name';
                    }
                    return null;
                  },
                ),
                if (widget.showDescription) ...[
                  const SizedBox(height: 12.0),
                  TextFormField(
                    controller: _descriptionController,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    cursorColor: vaultTheme.accent,
                    style: TextStyle(
                      fontFamily: VaultTheme.fontFamily,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w400,
                      color: vaultTheme.textHighSalience,
                    ),
                    decoration: _inputDecoration(
                      vaultTheme: vaultTheme,
                      labelText: 'Description (optional)',
                      hintText: 'Tracks saved for private listening',
                    ),
                  ),
                ],
                const SizedBox(height: 20.0),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48.0,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: vaultTheme.textHighSalience,
                            side: BorderSide(
                              color: vaultTheme.border,
                              width: VaultTheme.borderWidth,
                            ),
                            shape: VaultTheme.shape8,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontFamily: VaultTheme.fontFamily,
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: SizedBox(
                        height: 48.0,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: vaultTheme.accent,
                            foregroundColor: vaultTheme.scaffold,
                            elevation: 0.0,
                            shape: VaultTheme.shape8,
                          ),
                          onPressed: _submit,
                          child: Text(
                            widget.confirmLabel,
                            style: const TextStyle(
                              fontFamily: VaultTheme.fontFamily,
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared dark Figma bottom sheet container with drag handle, header, hairline
/// divider, content body, and optional pinned bottom action bar.
class VaultSheetScaffold extends StatelessWidget {
  final Key? sheetKey;
  final VaultThemeData vaultTheme;
  final String title;
  final String? subtitle;
  final Widget? headerTrailing;
  final VoidCallback? onClose;
  final Widget body;
  final Widget? bottomBar;
  final double? heightFactor;
  final bool expandBody;

  const VaultSheetScaffold({
    super.key,
    this.sheetKey,
    required this.vaultTheme,
    required this.title,
    this.subtitle,
    this.headerTrailing,
    this.onClose,
    required this.body,
    this.bottomBar,
    this.heightFactor,
    this.expandBody = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final contentColumn = Column(
      mainAxisSize: expandBody ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 12.0, 12.0, 12.0),
          child: Column(
            children: [
              Container(
                width: 36.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: vaultTheme.border,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
              const SizedBox(height: 14.0),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: VaultTheme.fontFamily,
                            fontSize: 18.0,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                            color: vaultTheme.textHighSalience,
                          ),
                        ),
                        if (subtitle case final sub? when sub.isNotEmpty) ...[
                          const SizedBox(height: 2.0),
                          Text(
                            sub,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: VaultTheme.fontFamily,
                              fontSize: 13.0,
                              fontWeight: FontWeight.w400,
                              color: vaultTheme.textMediumSalience,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (headerTrailing case final trailing?) ...[
                    const SizedBox(width: 8.0),
                    trailing,
                  ],
                  if (onClose case final closeCallback?)
                    IconButton(
                      tooltip: 'Close',
                      onPressed: closeCallback,
                      constraints: const BoxConstraints(
                        minWidth: 48.0,
                        minHeight: 48.0,
                      ),
                      icon: Container(
                        width: 34.0,
                        height: 34.0,
                        decoration: BoxDecoration(
                          color: vaultTheme.surfaceSubtle,
                          borderRadius: VaultTheme.borderRadius8,
                          border: Border.all(
                            color: vaultTheme.borderSubtle,
                            width: VaultTheme.borderWidth,
                          ),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18.0,
                          color: vaultTheme.textHighSalience,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        Divider(
          color: vaultTheme.borderSubtle,
          height: 1.0,
          thickness: VaultTheme.borderWidth,
        ),
        if (expandBody) Expanded(child: body) else Flexible(child: body),
        ?bottomBar,
      ],
    );

    final Widget boundedBody = switch (heightFactor) {
      final factor? => SizedBox(
          height: screenHeight * factor,
          child: contentColumn,
        ),
      null => ConstrainedBox(
          constraints: BoxConstraints(maxHeight: screenHeight * 0.88),
          child: contentColumn,
        ),
    };

    return Material(
      key: sheetKey,
      color: vaultTheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: vaultTheme.borderSubtle,
              width: VaultTheme.borderWidth,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: boundedBody,
        ),
      ),
    );
  }
}

/// Option descriptor for [VaultSegmentedControl].
class VaultSegmentOption<T> {
  final T value;
  final String label;
  final IconData icon;

  const VaultSegmentOption({
    required this.value,
    required this.label,
    required this.icon,
  });
}

/// Shared geometric 8dp segmented bar for Vault sheets.
class VaultSegmentedControl<T> extends StatelessWidget {
  final VaultThemeData vaultTheme;
  final List<VaultSegmentOption<T>> options;
  final T selectedValue;
  final ValueChanged<T>? onChanged;

  const VaultSegmentedControl({
    super.key,
    required this.vaultTheme,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44.0,
      padding: const EdgeInsets.all(3.0),
      decoration: BoxDecoration(
        color: vaultTheme.background,
        borderRadius: VaultTheme.borderRadius8,
        border: Border.all(
          color: vaultTheme.borderSubtle,
          width: VaultTheme.borderWidth,
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 4.0),
            Expanded(
              child: _buildSegment(options[i]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSegment(VaultSegmentOption<T> option) {
    final isSelected = selectedValue == option.value;
    final foregroundColor =
        isSelected ? vaultTheme.scaffold : vaultTheme.textMediumSalience;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged!(option.value),
        borderRadius: BorderRadius.circular(6.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration: BoxDecoration(
            color: isSelected ? vaultTheme.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                option.icon,
                size: 16.0,
                color: foregroundColor,
              ),
              const SizedBox(width: 6.0),
              Flexible(
                child: Text(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: VaultTheme.fontFamily,
                    fontSize: 13.0,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: foregroundColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared geometric 6-slot PIN indicator strip matching Vault Figma specs.
class VaultPinDotsRow extends StatelessWidget {
  final VaultThemeData vaultTheme;
  final int enteredCount;
  final bool isError;
  final Animation<double>? shakeAnimation;
  final Key? shakeContainerKey;
  final Key Function(int index)? dotSlotKeyBuilder;
  final bool keyFilledDots;

  const VaultPinDotsRow({
    super.key,
    required this.vaultTheme,
    required this.enteredCount,
    this.isError = false,
    this.shakeAnimation,
    this.shakeContainerKey,
    this.dotSlotKeyBuilder,
    this.keyFilledDots = false,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = isError ? vaultTheme.danger : vaultTheme.accent;

    final row = FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(6, (index) {
          final isFilled = index < enteredCount;
          final borderColor = isError
              ? vaultTheme.danger
              : (isFilled ? vaultTheme.accent : vaultTheme.borderSubtle);

          return Container(
            key: dotSlotKeyBuilder?.call(index),
            width: 42.0,
            height: 50.0,
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            decoration: BoxDecoration(
              color: isFilled ? vaultTheme.surfaceSubtle : vaultTheme.surface,
              borderRadius: VaultTheme.borderRadius8,
              border: Border.all(
                color: borderColor,
                width: VaultTheme.borderWidth,
              ),
            ),
            alignment: Alignment.center,
            child: isFilled
                ? Container(
                    key: keyFilledDots ? const ValueKey('pin_dot_filled') : null,
                    width: 10.0,
                    height: 10.0,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  )
                : null,
          );
        }),
      ),
    );

    final animation = shakeAnimation;
    if (animation == null) {
      return row;
    }

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          key: shakeContainerKey,
          offset: Offset(animation.value, 0),
          child: child,
        );
      },
      child: row,
    );
  }
}

/// Shared spring-animated keypad grid for PIN unlock and setup screens.
class VaultPinKeypad extends StatelessWidget {
  final VaultThemeData vaultTheme;
  final List<int> digits;
  final bool isDisabled;
  final ValueChanged<int> onDigitPressed;
  final VoidCallback onBackspace;
  final Widget? leadingSlot;

  const VaultPinKeypad({
    super.key,
    required this.vaultTheme,
    required this.digits,
    required this.isDisabled,
    required this.onDigitPressed,
    required this.onBackspace,
    this.leadingSlot,
  });

  Widget _digitTile(int digit) {
    return VaultKeypadActionTile(
      vaultTheme: vaultTheme,
      isDisabled: isDisabled,
      backgroundColor: vaultTheme.surface,
      borderColor: vaultTheme.borderSubtle,
      onTap: () => onDigitPressed(digit),
      child: Text(
        '$digit',
        style: TextStyle(
          fontFamily: VaultTheme.fontFamily,
          fontSize: 25.0,
          fontWeight: FontWeight.w500,
          fontFeatures: const [FontFeature.tabularFigures()],
          color: isDisabled
              ? vaultTheme.textLowSalience
              : vaultTheme.textHighSalience,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var row = 0; row < 3; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var col = 0; col < 3; col++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: _digitTile(digits[row * 3 + col]),
                  ),
              ],
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: leadingSlot ?? const SizedBox(width: 64.0, height: 64.0),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: _digitTile(digits[9]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: VaultKeypadActionTile(
                vaultTheme: vaultTheme,
                isDisabled: isDisabled,
                backgroundColor: Colors.transparent,
                borderColor: vaultTheme.borderSubtle,
                onTap: onBackspace,
                child: Icon(
                  Icons.backspace_outlined,
                  size: 22.0,
                  color: isDisabled
                      ? vaultTheme.textLowSalience
                      : vaultTheme.textHighSalience,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Crisp 64x64 8dp geometric keypad key with fast spring press feedback.
class VaultKeypadActionTile extends StatefulWidget {
  final VaultThemeData vaultTheme;
  final bool isDisabled;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback onTap;
  final Widget child;

  const VaultKeypadActionTile({
    super.key,
    required this.vaultTheme,
    required this.isDisabled,
    required this.backgroundColor,
    required this.borderColor,
    required this.onTap,
    required this.child,
  });

  @override
  State<VaultKeypadActionTile> createState() => _VaultKeypadActionTileState();
}

class _VaultKeypadActionTileState extends State<VaultKeypadActionTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _springController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(
        parent: _springController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeOutQuad,
      ),
    );
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.isDisabled) return;
    HapticFeedback.lightImpact();
    _springController.forward();
  }

  void _onTapCancel() {
    if (widget.isDisabled) return;
    _springController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final vaultTheme = widget.vaultTheme;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: SizedBox(
          width: 64.0,
          height: 64.0,
          child: Material(
            color: widget.backgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: VaultTheme.borderRadius8,
              side: BorderSide(
                color: widget.borderColor,
                width: VaultTheme.borderWidth,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTapDown: _onTapDown,
              onTap: widget.isDisabled
                  ? null
                  : () {
                      _springController.reverse();
                      widget.onTap();
                    },
              onTapCancel: _onTapCancel,
              splashColor: vaultTheme.accent.withValues(alpha: 0.14),
              highlightColor: vaultTheme.accent.withValues(alpha: 0.08),
              child: Center(child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}
